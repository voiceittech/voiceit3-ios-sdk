//
//  FaceVerificationViewController.m
//  VoiceItApi2IosSDK
//
//  Created by VoiceIt Technolopgies, LLC on 3/17/18.
//

#import "FaceVerificationViewController.h"
#import "Styles.h"
#import "Liveness.h"

@interface FaceVerificationViewController ()
@property(nonatomic, strong)  VoiceItAPITwo * myVoiceIt;
@property(nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor;
@property(nonatomic, strong)  AVAssetWriter *assetWriterMyData;
@property(nonatomic, strong)  NSString *videoPath;
@property(nonatomic, strong)  AVAssetWriterInput *assetWriterInput;
@property CGFloat circleWidth;
@property CGFloat backgroundWidthHeight;
@property NSTimer * timer;
@property int currentChallenge;
@property Liveness * livenessDetector;
@end

@implementation FaceVerificationViewController

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
    
    self.isReadyToWrite = NO;
    self.enoughRecordingTimePassed = NO;

    // Do any additional setup after loading the view.
    [self.progressView setHidden:YES];
    
    // Set up the AVCapture Session
    [self setupCaptureSession];
    [self setupVideoProcessing];

    [self setupScreen];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.messageLabel setText: [ResponseManager getMessage:@"LOOK_INTO_CAM"]];
    [self.progressView startAnimation];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self cleanupEverything];
}

- (void)notEnoughEnrollments:(NSString *) jsonResponse {
    [self setMessage:[ResponseManager getMessage: @"NFEF"]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated: YES completion:^{
            [self userVerificationFailed](0.0, jsonResponse);
        }];
    });
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
            [self stopRecording];
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

-(void)livenessFailedAction{
    self.continueRunning = NO;
    if(self.doLivenessDetection){
        self.livenessDetector.continueRunning = NO;
    }
    self.continueRunning = NO;
    self.lookingIntoCam = NO;
    [self setMessage: [ResponseManager getMessage:@"VERIFY_FACE_FAILED"]];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.8 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated: YES completion:^{
            NSError *error;
            NSMutableDictionary * jsonResponse = [[NSMutableDictionary alloc] init];
            [jsonResponse setObject:@"LDFA" forKey:@"responseCode"];
            [jsonResponse setObject:@0.0 forKey:@"faceConfidence"];
            [jsonResponse setObject:@"Liveness detection failed" forKey:@"message"];
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject: jsonResponse options:0 error:&error];
            if (!jsonData) {
                NSLog(@"Got an error: %@", error);
            } else {
                NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                 [self userVerificationFailed]( 0.0, jsonString);
            }
        }];
    });
}

-(void)startWritingToVideoFile{
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:640], AVVideoWidthKey, [NSNumber numberWithInt:480], AVVideoHeightKey, AVVideoCodecH264, AVVideoCodecKey,nil];
    self.assetWriterInput = [AVAssetWriterInput  assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:outputSettings];
    [self.assetWriterInput setTransform: CGAffineTransformMakeRotation( ( 90 * M_PI ) / 180 )];
    self.pixelBufferAdaptor =
    [[AVAssetWriterInputPixelBufferAdaptor alloc]
     initWithAssetWriterInput:self.assetWriterInput
     sourcePixelBufferAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [NSNumber numberWithInt:kCVPixelFormatType_32BGRA],
      kCVPixelBufferPixelFormatTypeKey,
      nil]];
    
    self.videoPath = [Utilities pathForTemporaryFileWithSuffix:@"mp4"];
    NSURL *videoURL = [NSURL fileURLWithPath:self.videoPath];
    
    /* Asset writer with MPEG4 format*/
    self.assetWriterMyData = [[AVAssetWriter alloc]
                                        initWithURL: videoURL
                                        fileType:AVFileTypeMPEG4
                                        error:nil];
    [self.assetWriterMyData addInput:self.assetWriterInput];
    self.assetWriterInput.expectsMediaDataInRealTime = YES;
    [self.assetWriterMyData startWriting];
    [self.assetWriterMyData startSessionAtSourceTime:kCMTimeZero];
    self.isReadyToWrite = YES;
}

-(void)finishVerification:(NSString *)jsonResponse{
    [self removeLoading];
    NSLog(@"FaceVerification JSON Response : %@", jsonResponse);
    NSDictionary *jsonObj = [Utilities getJSONObject:jsonResponse];
    NSString * responseCode = [jsonObj objectForKey:@"responseCode"];
    
    if([responseCode isEqualToString:@"SUCC"]){
        [self setMessage:[ResponseManager getMessage:@"SUCCESS"]];
        float faceConfidence = [[jsonObj objectForKey:@"faceConfidence"] floatValue];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated: YES completion:^{
                [self userVerificationSuccessful](faceConfidence, jsonResponse);
            }];
        });
    } else {
        self.failCounter += 1;
        if([Utilities isBadResponseCode:responseCode]){
            [self setMessage:[ResponseManager getMessage: @"CONTACT_DEVELOPER" variable: responseCode]];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self dismissViewControllerAnimated: YES completion:^{
                    [self userVerificationFailed](0.0, jsonResponse);
                }];
            });
        }
        else if(self.failCounter < self.failsAllowed){
            if ([responseCode isEqualToString:@"FAIL"]){
                [self setMessage:[ResponseManager getMessage: @"VERIFY_FACE_FAILED_TRY_AGAIN"]];
                [self startDelayedRecording:2.0];
            }
            else if ([responseCode isEqualToString:@"NFEF"]){
                [self notEnoughEnrollments:jsonResponse];
            } else{
                [self setMessage:[ResponseManager getMessage: responseCode]];
                [self startDelayedRecording:2.0];
            }
        } else {
            [self setMessage:[ResponseManager getMessage: @"TOO_MANY_ATTEMPTS"]];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                float faceConfidence = [responseCode isEqualToString:@"FAIL"] ? [[jsonObj objectForKey:@"faceConfidence"] floatValue] : 0.0;
                [self dismissViewControllerAnimated: YES completion:^{
                    [self userVerificationFailed](faceConfidence, jsonResponse);
                }];
            });
        }
    }
}

-(void)sendPhoto{
    [self showLoading];
    if(!self.continueRunning){
        return;
    }
    [self.myVoiceIt faceVerification:self.userToVerifyUserId imageData:self.finalCapturedPhotoData callback:^(NSString * jsonResponse){
        [self finishVerification:jsonResponse];
    }];
}

-(void)stopWritingToVideoFile {
    self.isReadyToWrite = NO;
    [self.assetWriterMyData finishWritingWithCompletionHandler:^{
        [self showLoading];
        if(!self.continueRunning){
            return;
        }
        [self.myVoiceIt faceVerification:self.userToVerifyUserId videoPath:self.videoPath callback:^(NSString * jsonResponse){
            [Utilities deleteFile:self.videoPath];
            [self finishVerification:jsonResponse];
        }];
    }];
}

-(void)setMessage:(NSString *) newMessage {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.messageLabel setText: newMessage];
        [self.messageLabel setAdjustsFontSizeToFitWidth:YES];
    });
}

-(void)startVerificationProcess{
    [self.myVoiceIt getAllFaceEnrollments:_userToVerifyUserId callback:^(NSString * jsonResponse){
        NSDictionary *jsonObj = [Utilities getJSONObject:jsonResponse];
        NSString * responseCode = [jsonObj objectForKey:@"responseCode"];
        if([responseCode isEqualToString:@"SUCC"]){
            [self.myVoiceIt getAllVideoEnrollments:self.userToVerifyUserId callback:^(NSString * jsonResponse){
                NSDictionary *jsonObj2 = [Utilities getJSONObject:jsonResponse];
                int faceEnrollmentsCount = [[jsonObj valueForKey:@"count"] intValue];
                int videoEnrollmentsCount = [[jsonObj2 valueForKey:@"count"] intValue];
                if(faceEnrollmentsCount < 1 && videoEnrollmentsCount < 1){
                    [self notEnoughEnrollments:@"{\"responseCode\":\"NFEF\",\"message\":\"No face enrollments found\"}"];
                } else {
                    [self startRecording];
                }
            }];
        } else {
            [self notEnoughEnrollments:@"{\"responseCode\":\"NFEF\",\"message\":\"No face enrollments found\"}"];
        }
    }];
}

-(void)startRecording {
    self.isRecording = YES;
    
    if(self.doLivenessDetection){
        [self.livenessDetector doLivenessDetection];
    }
    else {
        [self startWritingToVideoFile];
        [self setMessage:[ResponseManager getMessage:@"WAIT_FOR_FACE_VERIFICATION"]];
    }
    
    // Start Progress Circle Around Face Animation
    [self animateProgressCircle];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if(self.continueRunning){
            [self setEnoughRecordingTimePassed:YES];
            if (!self.doLivenessDetection) {
                [self stopRecording];
            }
        }
    });
}

-(void)startDelayedRecording:(NSTimeInterval)delayTime{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayTime * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if(self.continueRunning){
            [self startRecording];
        }
    });
}

-(void)animateProgressCircle {
    if(self.doLivenessDetection){
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressCircle.strokeColor = [Styles getMainCGColor];
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        animation.duration = 1.4;
        animation.removedOnCompletion = YES;
        animation.fromValue = @(0);
        animation.toValue = @(1);
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        [self.progressCircle addAnimation:animation forKey:@"drawCircleAnimation"];
    });
    
}

-(void)stopRecording{
    self.isRecording = NO;
    [self setEnoughRecordingTimePassed:NO];
    if([self doLivenessDetection]){
        [self sendPhoto];
    } else {
        [self stopWritingToVideoFile];
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

- (IBAction)cancelClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [self userVerificationCancelled]();
    }];
}

#pragma mark - Camera Delegate Methods

// Code to Capture Face Rectangle and other cool metadata stuff
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
            [self startVerificationProcess];
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
        if (self.isRecording && !self.enoughRecordingTimePassed && self.isReadyToWrite && !self.doLivenessDetection){
            CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
            // a very dense way to keep track of the time at which this frame
            // occurs relative to the output stream, but it's just an example!
            static int64_t frameNumber = 0;
            if(self.assetWriterInput.readyForMoreMediaData){
                if(self.pixelBufferAdaptor != nil){
                    [self.pixelBufferAdaptor appendPixelBuffer:imageBuffer
                                          withPresentationTime:CMTimeMake(frameNumber, 25)];
                    frameNumber++;
                }
            }
        }
    }
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
    [self cleanupCaptureSession];
    self.continueRunning = NO;
    if(self.doLivenessDetection){
        self.livenessDetector.continueRunning = NO;
        self.livenessDetector = nil;
    }
}
@end
