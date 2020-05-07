//
//  VideoVerificationViewController.m
//  VoiceItApi2IosSDK
//
//  Created by VoiceIt Technolopgies, LLC on 3/23/18.
//

#import "VideoVerificationViewController.h"
#import "Styles.h"
#import "Liveness.h"

@interface VideoVerificationViewController ()
@property(nonatomic, strong)  VoiceItAPITwo * myVoiceIt;
@property(nonatomic, strong)  NSString *videoPath;
@property CGFloat circleWidth;
@property CGFloat backgroundWidthHeight;
@property NSTimer * timer;
@property int currentChallenge;
@property Liveness * livenessDetector;
@end

@implementation VideoVerificationViewController

#pragma mark - Life Cycle Methods

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue",
                                                          DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.myVoiceIt = (VoiceItAPITwo *) [self voiceItMaster];
    // Initialize Boolean and All
    self.lookingIntoCam = NO;
    self.lookingIntoCamCounter = 0;
    self.continueRunning = YES;
    self.verificationStarted = NO;
    self.failCounter = 0;
    
    self.imageNotSaved = YES;

    // Do any additional setup after loading the view.
    [self.progressView setHidden:YES];
    
    // Set up the AVCapture Session
    [self setupCaptureSession];
    [self setupVideoProcessing];
    
    [self setupScreen];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.messageLabel setText: [ResponseManager getMessage:@"LOOK_INTO_CAM"]];
    [self.progressView startAnimation];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self cleanupEverything];
}

#pragma mark - Setup Methods

-(void)setupScreen {
    [self.cancelButton setTitle:[ResponseManager getMessage:@"CANCEL"] forState:UIControlStateNormal];
    // Setup Awesome Transparent Background and radius for Verification Box
    if (!UIAccessibilityIsReduceTransparencyEnabled()) {
        self.view.backgroundColor = [UIColor clearColor];
        
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.frame = self.view.bounds;
        blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self.view insertSubview:blurEffectView atIndex:0];
    } else {
        [[self view] setBackgroundColor:[UIColor colorWithRed:0.58 green:0.65 blue:0.65 alpha:0.6]];
    }
    [[self.verificationBox layer] setCornerRadius:10.0];
    [Utilities setBottomCornersForCancelButton:self.cancelButton];
    [self setupCameraCircle];
}

- (void)setupVideoProcessing {
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    NSDictionary *rgbOutputSettings = @{
                                        (__bridge NSString*)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)
                                        };
    [self.videoDataOutput setVideoSettings:rgbOutputSettings];
    
    if (![self.captureSession canAddOutput:self.videoDataOutput]) {
        [self cleanupVideoProcessing];
        NSLog(@"Failed to setup video output");
        return;
    }
    [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [self.videoDataOutput setSampleBufferDelegate:self queue:self.videoDataOutputQueue];
    [self.captureSession addOutput:self.videoDataOutput];
}

-(void)setupCaptureSession{
    // Setup Video Input Devices
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession beginConfiguration];
    [self.captureSession setSessionPreset: AVCaptureSessionPresetMedium];
    self.videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
    NSError * videoError;
    AVCaptureDeviceInput * videoInput = [AVCaptureDeviceInput deviceInputWithDevice: self.videoDevice error:&videoError];
    [self.captureSession addInput:videoInput];
}

-(void)setupCameraCircle{
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession: self.captureSession];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    // Setup code to capture face meta data
    AVCaptureMetadataOutput *metadataOutput = [[AVCaptureMetadataOutput alloc] init];
    // Have to add the output before setting metadata types
    [self.captureSession addOutput: metadataOutput];
    // We're only interested in faces
    [metadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeFace]];
    // This VC is the delegate. Please call us on the main queue
    [metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    // Setup Little Camera Circle and Positions
    self.rootLayer = [[self verificationBox] layer];
    self.backgroundWidthHeight = (CGFloat) [self verificationBox].frame.size.height  * 0.50;
    CGFloat cameraViewWidthHeight = (CGFloat) [self verificationBox].frame.size.height  * 0.48;
    self.circleWidth = (self.backgroundWidthHeight - cameraViewWidthHeight) / 2;
    CGFloat backgroundViewX = ([self verificationBox].frame.size.width - self.backgroundWidthHeight)/2;
    CGFloat cameraViewX = ([self verificationBox].frame.size.width - cameraViewWidthHeight)/2;
    CGFloat backgroundViewY = VERIFICATION_BACKGROUND_VIEW_Y;
    CGFloat cameraViewY = backgroundViewY + self.circleWidth;
    
    self.cameraBorderLayer = [[CALayer alloc] init];
    self.progressCircle = [CAShapeLayer layer];
    
    [self.cameraBorderLayer setFrame:CGRectMake(backgroundViewX, backgroundViewY, self.backgroundWidthHeight, self.backgroundWidthHeight)];
    [self.previewLayer setFrame:CGRectMake(cameraViewX, cameraViewY, cameraViewWidthHeight, cameraViewWidthHeight)];
    [self.previewLayer setCornerRadius: cameraViewWidthHeight / 2];
    self.cameraCenterPoint = CGPointMake(self.cameraBorderLayer.frame.origin.x + (self.backgroundWidthHeight/2), self.cameraBorderLayer.frame.origin.y + (self.backgroundWidthHeight/2) );
    
    if ([self.videoDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        CGPoint autofocusPoint = self.cameraCenterPoint;
        [self.videoDevice setFocusPointOfInterest:autofocusPoint];
        [self.videoDevice setFocusMode:AVCaptureFocusModeLocked];
    }
    
    // Setup Progress Circle
    self.progressCircle .path = [UIBezierPath bezierPathWithArcCenter: self.cameraCenterPoint radius:(self.backgroundWidthHeight / 2) startAngle:-M_PI_2 endAngle:2 * M_PI - M_PI_2 clockwise:YES].CGPath;
    self.progressCircle.fillColor = [UIColor clearColor].CGColor;
    self.progressCircle.strokeColor = [UIColor clearColor].CGColor;
    self.progressCircle.lineWidth = self.circleWidth + 8.0;
    
    [self.cameraBorderLayer setBackgroundColor: [UIColor clearColor].CGColor];
    self.cameraBorderLayer.cornerRadius = self.backgroundWidthHeight / 2;
    
    // Setup Rectangle Around Face
    [Utilities setupFaceRectangle:self.faceRectangleLayer];
    
    [self.rootLayer addSublayer:self.cameraBorderLayer];
    if(self.doLivenessDetection){
        self.livenessDetector = [[Liveness alloc] init:self cCP:self.cameraCenterPoint bgWH:self.backgroundWidthHeight cW:self.circleWidth rL:self.rootLayer mL:self.messageLabel doAudio:self.doAudioPrompts lFA:self.numberOfLivenessFailsAllowed livenessPassed:^(NSData * imageData) {
            self.finalCapturedPhotoData = imageData;
            [self startVerificationProcess];
        } livenessFailed:^{
            self.continueRunning = NO;
            self.livenessDetector.continueRunning = NO;
            [self livenessFailedAction];
        }];
    }
    [self.rootLayer addSublayer:self.progressCircle];
    [self.rootLayer addSublayer:self.previewLayer];
    [self.previewLayer addSublayer:self.faceRectangleLayer];
    [self.captureSession commitConfiguration];
    [self.captureSession startRunning];
}

#pragma mark - Action Methods

- (void)notEnoughEnrollments:(NSString *) jsonResponse {
    [self setMessage:[ResponseManager getMessage: @"TVER"]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated: YES completion:^{
            [self userVerificationFailed](0.0, 0.0, jsonResponse);
        }];
    });
}

-(void)checkEnrollments:(Boolean)doLiveness{
    [self.myVoiceIt getAllVideoEnrollments:_userToVerifyUserId callback:^(NSString * jsonResponse){
        NSDictionary *jsonObj = [Utilities getJSONObject:jsonResponse];
        NSString * responseCode = [jsonObj objectForKey:@"responseCode"];
        if([responseCode isEqualToString:@"SUCC"]){
            int enrollmentsCount = [[jsonObj valueForKey:@"count"] intValue];
            if(enrollmentsCount < 3){
                [self notEnoughEnrollments:@"{\"responseCode\":\"TVER\",\"message\":\"Not enough video enrollments\"}"];
            } else {
                if(doLiveness){
                    [self.livenessDetector doLivenessDetection];
                } else {
                    [self startVerificationProcess];
                }
            }
        } else {
            [self notEnoughEnrollments:@"{\"responseCode\":\"TVER\",\"message\":\"Not enough video enrollments\"}"];
        }
    }];
}

-(void)startVerificationProcess {
    [self startDelayedRecording:0.4];
}

-(void)startDelayedLiveness:(NSTimeInterval)delayTime{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayTime * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if(self.continueRunning){
            [self.livenessDetector doLivenessDetection];
        }
    });
}

-(void)startDelayedRecording:(NSTimeInterval)delayTime{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayTime * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if(self.continueRunning){
            [self setMessage:[ResponseManager getMessage:@"VERIFY" variable:self.thePhrase]];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                if(self.continueRunning){
                    [self startRecording];
                }
            });
        }
    });
}

-(void)livenessFailedAction{
    if(self.doLivenessDetection){
        self.livenessDetector.continueRunning = NO;
    }
    self.continueRunning = NO;
    self.lookingIntoCam = NO;
    [self setMessage: [ResponseManager getMessage:@"VIDEO_VERIFY_FAILED"]];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.8 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated: YES completion:^{
            NSError *error;
            NSMutableDictionary * jsonResponse = [[NSMutableDictionary alloc] init];
            [jsonResponse setObject:@"LDFA" forKey:@"responseCode"];
            [jsonResponse setObject:@0.0 forKey:@"voiceConfidence"];
            [jsonResponse setObject:@0.0 forKey:@"faceConfidence"];
            [jsonResponse setObject:@"Liveness detection failed" forKey:@"message"];
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject: jsonResponse options:0 error:&error];
            if (!jsonData) {
                NSLog(@"Got an error: %@", error);
            } else {
                NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                [self userVerificationFailed]( 0.0, 0.0, jsonString);
            }
        }];
    });
}

-(void)timerDone{
    [self livenessFailedAction];
}

- (UIImage *)imageFromCIImage:(CIImage *)ciImage {
    CIContext *ciContext = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [ciContext createCGImage:ciImage fromRect:[ciImage extent]];
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return image;
}

-(void)saveImageData:(CIImage *)image{
    if ( image != nil){
        UIImage *uiimage = [self imageFromCIImage:image];
        self.finalCapturedPhotoData  = UIImageJPEGRepresentation(uiimage, 0.4);
        self.imageNotSaved = NO;
    }
}

-(void)showLoading{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView setHidden:NO];
        [self setMessage:@""];
    });
}

-(void)removeLoading{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView setHidden:YES];
    });
}


-(void)setAudioSessionInactive{
    [self.audioRecorder stop];
    NSError * err;
    [self.audioSession setActive:NO error:&err];
}

-(void)setMessage:(NSString *) newMessage {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.messageLabel setText: newMessage];
        [self.messageLabel setAdjustsFontSizeToFitWidth:YES];
    });
}

-(void)animateProgressCircle {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressCircle.strokeColor = [Styles getMainCGColor];
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        animation.duration = 5;
        animation.removedOnCompletion = YES;
        animation.fromValue = @(0);
        animation.toValue = @(1);
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        [self.progressCircle addAnimation:animation forKey:@"drawCircleAnimation"];
    });
}

-(void)startRecording {
    NSLog(@"Starting RECORDING");
    self.isRecording = YES;
    self.imageNotSaved = YES;
    self.cameraBorderLayer.backgroundColor = [UIColor clearColor].CGColor;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err;
    [audioSession setCategory:AVAudioSessionCategoryRecord error:&err];
    if (err)
    {
        NSLog(@"%@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
    }
    err = nil;
    if (err)
    {
        NSLog(@"%@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
    }
    
    self.audioPath = [Utilities pathForTemporaryFileWithSuffix:@"wav"];
    NSURL *url = [NSURL fileURLWithPath:self.audioPath];
    
    err = nil;
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:url settings:[Utilities getRecordingSettings] error:&err];
    if(!self.audioRecorder){
        NSLog(@"recorder: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
        return;
    }
    [self.audioRecorder setDelegate:self];
    [self.audioRecorder prepareToRecord];
    [self.audioRecorder setMeteringEnabled:YES];
    [self.audioRecorder recordForDuration:4.8];
    
    // Start Progress Circle Around Face Animation
    [self animateProgressCircle];
}

-(void)stopRecording{
    self.isRecording = NO;
    self.progressCircle.strokeColor = [UIColor clearColor].CGColor;
}

- (IBAction)cancelClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [self userVerificationCancelled]();
    }];
}

#pragma mark - Camera Delegate Methods

-(void)    captureOutput:(AVCaptureOutput *)output
didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects
          fromConnection:(AVCaptureConnection *)connection{
        BOOL faceFound = NO;
        for(AVMetadataObject *metadataObject in metadataObjects) {
        if([metadataObject.type isEqualToString:AVMetadataObjectTypeFace]) {
            faceFound = YES;
            AVMetadataObject * face = [self.previewLayer transformedMetadataObjectForMetadataObject:metadataObject];
            [Utilities showFaceRectangle:self.faceRectangleLayer face:face];
        }
    }
    
    if(faceFound) {
        self.lookingIntoCamCounter += 1;
        self.lookingIntoCam = self.lookingIntoCamCounter > MAX_TIME_TO_WAIT_TILL_FACE_FOUND;
        if (self.lookingIntoCam && !self.verificationStarted) {
            self.verificationStarted = YES;
            [self checkEnrollments:self.doLivenessDetection];
        }
    } else {
        self.lookingIntoCam = NO;
        self.lookingIntoCamCounter = 0;
        [self.faceRectangleLayer setHidden:YES];
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    
    // Don't do any analysis when not looking into the camera
    if(!self.lookingIntoCam){
        return;
    }
    
    if(self.doLivenessDetection){
        [self.livenessDetector processFrame:sampleBuffer];
    } else {
        if(self.lookingIntoCamCounter > 5 && self.imageNotSaved){
            // Convert to CIPixelBuffer for faceDetector
            CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
            if (pixelBuffer == NULL) { return; }
            
            // Create CIImage for faceDetector
            CIImage *image = [CIImage imageWithCVImageBuffer:pixelBuffer];
            [self saveImageData:image];
        }
    }
}

#pragma mark - AVAudioRecorderDelegate Methods

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    if(!self.continueRunning){
        return;
    }
    [self setAudioSessionInactive];
    [self stopRecording];
    [self showLoading];
    [self.myVoiceIt videoVerification:self.userToVerifyUserId contentLanguage: self.contentLanguage imageData:self.finalCapturedPhotoData audioPath:self.audioPath phrase:self.thePhrase callback:^(NSString * jsonResponse){
            [Utilities deleteFile:self.audioPath];
            self.imageNotSaved = YES;
            [self removeLoading];
            NSLog(@"Video Verification JSON Response : %@", jsonResponse);
            NSDictionary *jsonObj = [Utilities getJSONObject:jsonResponse];
            NSString * responseCode = [jsonObj objectForKey:@"responseCode"];
        
            if([responseCode isEqualToString:@"SUCC"]){
                [self setMessage:[ResponseManager getMessage:@"SUCCESS"]];
                float faceConfidence = [[jsonObj objectForKey:@"faceConfidence"] floatValue];
                float voiceConfidence = [[jsonObj objectForKey:@"voiceConfidence"] floatValue];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [self dismissViewControllerAnimated: YES completion:^{
                        [self userVerificationSuccessful](faceConfidence, voiceConfidence, jsonResponse);
                    }];
                });
            }
        
            else if([responseCode isEqualToString:@"FNFD"]){
                [self setMessage:[ResponseManager getMessage: responseCode]];
                if(self.doLivenessDetection){
                    [self.livenessDetector resetVariables];
                    [self startDelayedLiveness:3.0];
                } else {
                    [self startDelayedRecording:3.0];
                }
                
            } else {
                self.failCounter += 1;
                
                if([Utilities isBadResponseCode:responseCode]){
                    [self setMessage:[ResponseManager getMessage: @"CONTACT_DEVELOPER" variable: responseCode]];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        [self dismissViewControllerAnimated: YES completion:^{
                            [self userVerificationFailed](0.0, 0.0, jsonResponse);
                        }];
                    });
                }
                else if(self.failCounter < self.failsAllowed){
                    if([responseCode isEqualToString:@"STTF"] || [responseCode isEqualToString:@"PDNM"]){
                        [self setMessage:[ResponseManager getMessage: responseCode variable:self.thePhrase]];
                        [self startDelayedRecording:3.0];
                    }
                    else if ([responseCode isEqualToString:@"TVER"]){
                        [self notEnoughEnrollments:jsonResponse];
                    }else{
                        [self setMessage:[ResponseManager getMessage: responseCode]];
                        [self startDelayedRecording:3.0];
                    }
                } else {
                    [self setMessage:[ResponseManager getMessage: @"TOO_MANY_ATTEMPTS"]];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        float faceConfidence = [responseCode isEqualToString:@"FAIL"] ? [[jsonObj objectForKey:@"faceConfidence"] floatValue] : 0.0;
                        float voiceConfidence = [responseCode isEqualToString:@"FAIL"] ? [[jsonObj objectForKey:@"voiceConfidence"] floatValue] : 0.0;
                        [self dismissViewControllerAnimated: YES completion:^{
                            [self userVerificationFailed](faceConfidence, voiceConfidence, jsonResponse);
                        }];
                    });
                }
            }
        }];
}

-(void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    NSLog(@"fail because %@", error.localizedDescription);
}

#pragma mark - Cleanup Methods

- (void)cleanupCaptureSession {
    [self.captureSession stopRunning];
    [self cleanupVideoProcessing];
    self.captureSession = nil;
    [self.previewLayer removeFromSuperlayer];
}

- (void)cleanupVideoProcessing {
    if (self.videoDataOutput) {
        [self.captureSession removeOutput:self.videoDataOutput];
    }
    self.videoDataOutput = nil;
}

-(void)cleanupEverything {
    [self setAudioSessionInactive];
    [self cleanupCaptureSession];
    self.continueRunning = NO;
    if(self.doLivenessDetection){
        self.livenessDetector.continueRunning = NO;
        self.livenessDetector = nil;
    }
}

@end
