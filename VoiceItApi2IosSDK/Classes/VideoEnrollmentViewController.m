//
//  VideoEnrollmentViewController.m
//  VoiceItApi2IosSDK
//
//  Created by VoiceIt Technolopgies, LLC on 10/1/17.
//

#import "VideoEnrollmentViewController.h"
#import "Liveness.h"
#import "Utilities.h"
@interface VideoEnrollmentViewController ()
@end

@implementation VideoEnrollmentViewController

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
    self.messageLabel.textColor  = [Utilities uiColorFromHexString:@"#FFFFFF"];
    [self.navigationItem setHidesBackButton: YES];
    self.myNavController = (MainNavigationController*) [self navigationController];
    self.myVoiceIt = (VoiceItAPITwo *) self.myNavController.myVoiceIt;
    self.thePhrase =  self.myNavController.voicePrintPhrase;
    self.contentLanguage =  self.myNavController.contentLanguage;
    self.userToEnrollUserId = self.myNavController.uniqueId;
    // Setup Cancel Button on top left of navigation controller
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithTitle:[ResponseManager getMessage:@"CANCEL"] style:UIBarButtonItemStylePlain target:self action:@selector(cancelClicked)];
    leftBarButton.tintColor = [Utilities uiColorFromHexString:@"#FFFFFF"];
    [self.navigationItem setLeftBarButtonItem:leftBarButton];

    // Initialize Boolean and All
    self.lookingIntoCam = NO;
    self.enrollmentStarted = NO;
    self.continueRunning  = YES;
    self.imageNotSaved = YES;
    self.lookingIntoCamCounter = 0;
    self.enrollmentDoneCounter = 0;
    [self setNavigationTitle:self.enrollmentDoneCounter + 1];
    [self setupCaptureSession];
    [self setupCameraCircle];
    [self setupVideoProcessing];
    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated{
    self.originalMessageLeftConstraintContstant = self.messageleftConstraint.constant;
    [[self messageLabel] setText:[ResponseManager getMessage:@"LOOK_INTO_CAM"]];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self cleanupEverything];
}

#pragma mark - Setup Methods

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
    CALayer *rootLayer = [[self view] layer];
    CGFloat backgroundWidthHeight = (CGFloat) self.view.frame.size.height  * 0.42;
    CGFloat cameraViewWidthHeight = (CGFloat) self.view.frame.size.height  * 0.4;
    CGFloat circleWidth = (backgroundWidthHeight - cameraViewWidthHeight) / 2;
    CGFloat backgroundViewX = (self.view.frame.size.width - backgroundWidthHeight)/2;
    CGFloat cameraViewX = (self.view.frame.size.width - cameraViewWidthHeight)/2;
    CGFloat backgroundViewY = ENROLLMENT_BACKGROUND_VIEW_Y;
    CGFloat cameraViewY = backgroundViewY + circleWidth;

    self.cameraBorderLayer = [[CALayer alloc] init];
    self.progressCircle = [CAShapeLayer layer];
    
    [self.cameraBorderLayer setFrame:CGRectMake(backgroundViewX, backgroundViewY, backgroundWidthHeight, backgroundWidthHeight)];
    [self.previewLayer setFrame:CGRectMake(cameraViewX, cameraViewY, cameraViewWidthHeight, cameraViewWidthHeight)];
    [self.previewLayer setCornerRadius: cameraViewWidthHeight / 2];
    self.cameraCenterPoint = CGPointMake(self.cameraBorderLayer.frame.origin.x + (backgroundWidthHeight/2), self.cameraBorderLayer.frame.origin.y + (backgroundWidthHeight/2) );

    if ([self.videoDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        CGPoint autofocusPoint = self.cameraCenterPoint;
        [self.videoDevice setFocusPointOfInterest:autofocusPoint];
        [self.videoDevice setFocusMode:AVCaptureFocusModeLocked];
    }

    // Setup Progress Circle
    self.progressCircle .path = [UIBezierPath bezierPathWithArcCenter: self.cameraCenterPoint radius:(backgroundWidthHeight / 2) startAngle:-M_PI_2 endAngle:2 * M_PI - M_PI_2 clockwise:YES].CGPath;
    self.progressCircle.fillColor = [UIColor clearColor].CGColor;
    self.progressCircle.strokeColor = [UIColor clearColor].CGColor;
    self.progressCircle.lineWidth = circleWidth * 2.0;
    [self.cameraBorderLayer setBackgroundColor: [UIColor clearColor].CGColor];
    self.cameraBorderLayer.cornerRadius = circleWidth / 2;

    // Setup Rectangle Around Face
    [Utilities setupFaceRectangle:self.faceRectangleLayer];

    [rootLayer addSublayer:self.cameraBorderLayer];
    [rootLayer addSublayer:self.progressCircle];
    [rootLayer addSublayer:self.previewLayer];
    [self.previewLayer addSublayer:self.faceRectangleLayer];
    [self.captureSession commitConfiguration];
    [self.captureSession startRunning];
}

-(void)setupCaptureSession{
    // Setup Video Input Device
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession beginConfiguration];
    [self.captureSession setSessionPreset: AVCaptureSessionPresetMedium];
    self.videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
    NSError * videoError;
    AVCaptureDeviceInput * videoInput = [AVCaptureDeviceInput deviceInputWithDevice: self.videoDevice error:&videoError];
    [self.captureSession addInput:videoInput];
}

#pragma mark - Action Methods

-(void)setNavigationTitle:(int) enrollNumber {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString * newTitle = [[NSString alloc] initWithFormat:@"%d of 3", enrollNumber];
        [[self navigationItem] setTitle: newTitle];
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

-(void)startDelayedRecording:(NSTimeInterval)delayTime{
    NSLog(@"Starting Delayed RECORDING with delayTime %f ", delayTime);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayTime * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if(self.continueRunning){
            [self makeLabelFlyIn:[ResponseManager getMessage:[[NSString alloc] initWithFormat:@"ENROLL_%d", self.enrollmentDoneCounter] variable:self.thePhrase]];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.8 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                if(self.continueRunning){
                    [self startRecording];
                }
            });
        }
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
    [self setAudioSessionInactive];
    self.isRecording = NO;
    self.progressCircle.strokeColor = [UIColor clearColor].CGColor;
}

-(void)startEnrollmentProcess {
    [self.myVoiceIt deleteAllEnrollments:self.userToEnrollUserId callback:^(NSString * deleteEnrollmentsJSONResponse){
        [self makeLabelFlyIn: [ResponseManager getMessage:@"GET_ENROLLED"]];
        [self startDelayedRecording:2.0];
    }];
}

-(void)makeLabelFlyAway :(void (^)(void))flewAway {
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat flyAwayTime = 0.4;
        __block CGFloat currentX = [self.messageLabel center].x;
        [UIView animateWithDuration:flyAwayTime animations:^{
            [self.messageLabel setCenter:CGPointMake(currentX - self.view.bounds.size.width, self.messageLabel.center.y)];
        } completion:^(BOOL finished){
            flewAway();
        }];
    });
}

-(void)makeLabelFlyIn:(NSString *)message {
    CGFloat flyInTime = 0.8;
    dispatch_async(dispatch_get_main_queue(), ^{
        __block CGFloat currentX = [self.messageLabel center].x;
        [[self messageLabel] setText:message];
        [self.messageLabel setCenter:CGPointMake(currentX + 2 * self.view.bounds.size.width, self.messageLabel.center.y)];
        currentX = [self.messageLabel center].x;
        [UIView animateWithDuration:flyInTime animations:^{
            [self.messageLabel setCenter:CGPointMake(currentX - self.view.bounds.size.width, self.messageLabel.center.y)];
        }];
    });
}

-(void)showLoading{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self makeLabelFlyAway:^{
            [self.progressView setHidden:NO];
        }];
    });
}

-(void)removeLoading{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView setHidden:YES];
    });
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
-(void)takeToFinishedView{
    NSLog(@"Take to finished view");
    dispatch_async(dispatch_get_main_queue(), ^{
        EnrollFinishViewController * enrollVC = [[Utilities getVoiceItStoryBoard] instantiateViewControllerWithIdentifier:@"enrollFinishedVC"];
        [[self navigationController] pushViewController:enrollVC animated: YES];
    });
}

-(void)cancelClicked{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [[self navigationController] dismissViewControllerAnimated:YES completion:^{
            [[self myNavController] userEnrollmentsCancelled];
        }];
        [self.myVoiceIt deleteAllEnrollments:self.userToEnrollUserId callback:^(NSString * deleteEnrollmentsJSONResponse){}];
    });
}

#pragma mark - Camera Delegate Methods

// Code to Capture Face Rectangle and other cool metadata stuff
-(void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
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
        if (self.lookingIntoCam && !self.enrollmentStarted) {
            self.enrollmentStarted = YES;
            [self startEnrollmentProcess];
        }
    } else if (!self.enrollmentStarted){
        self.lookingIntoCam = NO;
        self.lookingIntoCamCounter = 0;
        [self.faceRectangleLayer setHidden:YES];
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

    if(self.imageNotSaved){
        // Convert to CIPixelBuffer for faceDetector
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        if (pixelBuffer == NULL) { return; }
        
        // Create CIImage for faceDetector
        CIImage *image = [CIImage imageWithCVImageBuffer:pixelBuffer];
        [self saveImageData:image];
    }

}


#pragma mark - AVAudioRecorderDelegate Methods

-(void)setAudioSessionInactive{
    [self.audioRecorder stop];
    NSError * err;
    [self.audioSession setActive:NO error:&err];
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    [self stopRecording];
    if(self.imageNotSaved){
        [self startDelayedRecording:3.0];
        [self makeLabelFlyIn: [ResponseManager getMessage:@"FNFD"]];
    } else {
        [self showLoading];
        [self.myVoiceIt createVideoEnrollment:self.userToEnrollUserId contentLanguage:self.contentLanguage imageData:self.finalCapturedPhotoData audioPath:self.audioPath phrase:self.thePhrase callback:^(NSString * jsonResponse){
            [Utilities deleteFile:self.audioPath];
            [self removeLoading];
            self.imageNotSaved = YES;
            NSLog(@"Video Enrollment JSON Response : %@", jsonResponse);
            NSDictionary *jsonObj = [Utilities getJSONObject:jsonResponse];
            NSString * responseCode = [jsonObj objectForKey:@"responseCode"];
            if([responseCode isEqualToString:@"SUCC"]){
                self.enrollmentDoneCounter += 1;
                if( self.enrollmentDoneCounter < 3){
                    [self setNavigationTitle:self.enrollmentDoneCounter + 1];
                    [self startDelayedRecording:1];
                } else {
                    [self takeToFinishedView];
                }
            } else {
                if([Utilities isBadResponseCode:responseCode]){
                    [self makeLabelFlyIn:[ResponseManager getMessage: @"CONTACT_DEVELOPER" variable: responseCode]];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        [[self navigationController] dismissViewControllerAnimated:YES completion:^{
                            [[self myNavController] userEnrollmentsCancelled];
                        }];
                    });
                }
                else if([responseCode isEqualToString:@"STTF"] || [responseCode isEqualToString:@"PDNM"]){
                    [self startDelayedRecording:3.0];
                    [self makeLabelFlyIn:[ResponseManager getMessage: responseCode variable:self.thePhrase]];
                } else {
                    [self startDelayedRecording:3.0];
                    [self makeLabelFlyIn:[ResponseManager getMessage:responseCode]];
                }
            }
        }];
    }
}

-(void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    NSLog(@"fail because %@", error.localizedDescription);
}

#pragma mark - Cleanup Methods

-(void)cleanupEverything {
    [self setAudioSessionInactive];
    [self cleanupCaptureSession];
    self.continueRunning = NO;
}

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
@end
