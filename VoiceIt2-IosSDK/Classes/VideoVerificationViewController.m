//
//  VideoVerificationViewController.m
//  VoiceIt2-IosSDK
//
//  Created by VoiceIt Technologies, LLC
//  Copyright (c) 2020 VoiceIt Technologies, LLC. All rights reserved.
//

#import "VideoVerificationViewController.h"
#import "Styles.h"

@interface VideoVerificationViewController ()
@property(nonatomic, strong) VoiceItAPITwo * myVoiceIt;
@property(nonatomic, strong) NSString * videoPath;
@property(nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor * pixelBufferAdaptor;
@property(nonatomic, strong) AVAssetWriterInput * assetWriterInput;
@property(nonatomic, strong) AVAssetWriter * assetWriterMyData;
@property CGFloat circleWidth;
@property CGFloat backgroundWidthHeight;
@property NSTimer * timer;

@property int currentChallenge;
@property NSNumber * livenessChallengeTime;
@property BOOL isChallengeRetrieved;

@property NSString * lcoId;
@property NSArray * lcoStrings;
@property NSArray * lco;

@property NSString * result;
@property NSString * uiMessage;
@property NSString * livenessInstruction;
@property NSString * audioPromptType;

@property BOOL isSuccess;
@property BOOL isProcessing;

@property BOOL success;
@end

@implementation VideoVerificationViewController

#pragma mark - Life Cycle Methods

- (id) initWithCoder:(NSCoder *)aDecoder{
    NSLog(@"Init With Coder");
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (IBAction) stopVideoVerification:(id)sender {
    NSLog(@"Stop Video Verification");
    [self dismissViewControllerAnimated:YES completion:^{
        [self userVerificationCancelled]();
    }];
}

- (void) viewDidLoad {
    NSLog(@"View Did Load");
    [super viewDidLoad];
    self.myVoiceIt = (VoiceItAPITwo *) [self voiceItMaster];
    // Initialize Boolean and All
    self.lookingIntoCam = NO;
    NSLog(@"lookingIntoCam = %d", self.lookingIntoCam);
    self.lookingIntoCamCounter = 0;
    self.continueRunning = YES;
    self.verificationStarted = NO;
    self.failCounter = 0;
    self.cancelPlayback = NO;

    self.isProcessing = NO;
    self.isReadyToWrite = NO;

    self.imageIsSaved = NO;
    
    self.isSuccess = NO;
    
    // Do any additional setup after loading the view.
    [self.progressView setHidden:YES];
    
    if([self doLivenessDetection]){
        //Get LCOID, challenge string and liveness time
        [self getLivenessData];
    } else{
        // Set up the AVCapture Session
        [self setupCaptureSession];
        [self setupVideoProcessing];
        [self setupScreen];
    }
}

-(void) viewWillAppear:(BOOL)animated{
    NSLog(@"View Will Appear");
    [super viewWillAppear:animated];
    [self.messageLabel setText: [ResponseManager getMessage:@"LOOK_INTO_CAM"]];
    [self.progressView startAnimation];
}

-(void) viewWillDisappear:(BOOL)animated{
    NSLog(@"View Will Disappear");
    [super viewWillDisappear:animated];
    [self cleanupEverything];
}

- (void) notEnoughEnrollments:(NSString *) jsonResponse{
    NSLog(@"Display Not Enough Enrollements Message");
    [self setMessage:[ResponseManager getMessage: @"TVER"]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated: YES completion:^{
            [self userVerificationFailed](0.0, 0.0, jsonResponse);
        }];
    });
}

#pragma mark - Liveness Data

-(void) handleLivenessResponse: (NSString*)result{
    NSLog(@"Handle Liveness Response");
    NSDictionary *jsonObj = [Utilities getJSONObject:result];
    self.uiMessage = [jsonObj objectForKey:@"uiMessage"];
    BOOL retry = [[jsonObj objectForKey:@"retry"] boolValue];
    self.success = [[jsonObj objectForKey:@"success"] boolValue];
    self.audioPromptType = [jsonObj objectForKey:@"audioPrompt"];
    self.result = result;
    
    // Remove the video file created on last pass
    [Utilities deleteFile:self.videoPath];
    // Remove rotating circle
    [self removeUploadingCircle];

    // Failed Liveness and need to retry
    if(!self.success && retry){
        NSLog(@"Liveness Failed and Retry is True : result : %@", result);
        // Play LCO Failed Audio File
        [self playSound:self.audioPromptType];
        // Display message on UI
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.messageLabel setText:self.uiMessage];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self startRecordingVideo];
        });
    }

    // Failed liveness all attempts now exit back to app
    if(!self.success && !retry){
        NSLog(@"Liveness Failed and Retry is False : result : %@", result);
        // Play LCO Failed Audio File
        [self playSound:self.audioPromptType];
        // Display message on UI
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.messageLabel setText:self.uiMessage];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated: YES completion:^{
                [self userVerificationFailed](0.0, 0.0, self.uiMessage);
            }];
        });
    }
    
    // Passed Liveness and Passed API 2 Verification
    if(self.success){
        NSLog(@"Liveness Passed and Retry is False : result : %@", self.uiMessage);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.messageLabel setText:self.uiMessage];
            // Hide Button
            [self.cancelButton setHidden:YES];
        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated: YES completion:^{
                [self userVerificationSuccessful](0.0, 0.0, self.uiMessage);
            }];
        });
        [self playSound:self.audioPromptType];
    }
}

-(void) getLivenessData{
    NSLog(@"Get Liveness Data");
    if(!self.doLivenessDetection) return;
    
    [[self myVoiceIt] getLivenessID:self.userToVerifyUserId countryCode:
     self.contentLanguage callback:^(NSString *response) {
        
        NSDictionary *data = [Utilities getJSONObject:response];
        self.lcoStrings = [data valueForKey:@"lcoStrings"];
        self.isChallengeRetrieved = [data valueForKey:@"success"];
        self.lcoId = [data valueForKey:@"lcoId"];
        self.livenessChallengeTime = [data valueForKey:@"livenessChallengeTime"];
        self.lco = [data valueForKey:@"lco"];
        self.livenessInstruction = [data valueForKey:@"uiLivenessInstruction"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupCaptureSession];
            [self setupVideoProcessing];
            [self setupScreen];
        });
    } onFailed:^(NSError * error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.messageLabel setText: @"Liveness service failed. Please Try again Later."];
            [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
        });
    } pageCateory:@"verification"];
}

-(void) setLivenessChallengeMessages{
    NSLog(@"Set Liveness Challenge Message");
    if (!self.continueRunning) {
        return;
    }
    // Record time from liveness server + 5 seconds of Audio
    float timeToStop = [self.livenessChallengeTime floatValue] + 5.0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, timeToStop * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self.movieFileOutput stopRecording];
        [self stopRecordingAudio];
        [self clearCircleAnimations];
        [self.messageLabel setText:@""];
        [self showUploadingCircle];
    });
    
    [self setMessage:[self.lcoStrings firstObject]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self illuminateLivenessChallengeOnCircle:[self.lco firstObject]];
    });
    
    for(int i=1;i<self.lco.count;i++){
        float time = [self.livenessChallengeTime floatValue]/(self.lco.count);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self setMessage:self.lcoStrings[i]];
            [self illuminateLivenessChallengeOnCircle:self.lco[i]];
        });
    }
}

#pragma mark - Setup Methods
-(void) setupScreen{
    NSLog(@"Setup Screen");
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

- (void) setupVideoProcessing{
    NSLog(@"Setup Video Processing");
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

-(void) setupCaptureSession{
    NSLog(@"Setup Capture Session");
    // Setup Video Input Devices
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession beginConfiguration];
    [self.captureSession setSessionPreset: AVCaptureSessionPresetMedium];
    self.videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
    NSError * videoError;
    AVCaptureDeviceInput * videoInput = [AVCaptureDeviceInput deviceInputWithDevice: self.videoDevice error:&videoError];
    [self.captureSession addInput:videoInput];
    
    // Add audio only when doing liveness
    // TODO: Need to check why audio recording is lowered
    if(self.doLivenessDetection){

        AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        NSError *error = nil;
        AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];
        if (audioInput){
            [self.captureSession addInput:audioInput];
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:(AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetooth) error:nil];
                  [[AVAudioSession sharedInstance] setActive:YES error:nil];
            self.captureSession.usesApplicationAudioSession = YES;
            self.captureSession.automaticallyConfiguresApplicationAudioSession = NO;
        }
        self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
        Float64 TotalSeconds = 60;
        int32_t preferredTimeScale = 30;
        CMTime maxDuration = CMTimeMakeWithSeconds(TotalSeconds, preferredTimeScale);
        self.movieFileOutput.maxRecordedDuration = maxDuration;
        self.movieFileOutput.minFreeDiskSpaceLimit = 1024 * 1024;
        if ([self.captureSession canAddOutput:self.movieFileOutput]){
            [self.captureSession addOutput:self.movieFileOutput];
            [self.captureSession setSessionPreset:AVCaptureSessionPresetMedium];
        }
        AVCaptureConnection *CaptureConnection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([CaptureConnection isVideoOrientationSupported])
        {
            AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationPortrait;
            [CaptureConnection setVideoOrientation:orientation];
        }
    }
}

-(void) setupCameraCircle{
    NSLog(@"Setup Camera Circle");
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
    self.faceRectangleLayer = [[CALayer alloc] init];
    [Utilities setupFaceRectangle:self.faceRectangleLayer];
    [self.rootLayer addSublayer:self.cameraBorderLayer];
    [self.rootLayer addSublayer:self.progressCircle];
    [self.rootLayer addSublayer:self.previewLayer];
    [self.previewLayer addSublayer:self.faceRectangleLayer];
    [self.captureSession commitConfiguration];
    [self.captureSession startRunning];
}

#pragma mark - Action Methods

-(void) playSound:(NSString*) lco{
    NSLog(@"Play Voice Over");
    if(self.doAudioPrompts && !self.cancelPlayback){
        float time = [self.livenessChallengeTime floatValue];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self.player stop];
        });
        NSBundle * podBundle = [NSBundle bundleForClass: self.classForCoder];
        NSURL * bundleURL = [[podBundle resourceURL] URLByAppendingPathComponent:@"VoiceIt2-IosSDK.bundle"];
        NSString* soundFilePath = [self.contentLanguage isEqualToString:@"es-ES"] ?
        [NSString stringWithFormat:@"%@/%@",[[[NSBundle alloc] initWithURL:bundleURL] resourcePath], [self getSpanishPrompts:lco]] : [NSString stringWithFormat:@"%@/%@",[[[NSBundle alloc] initWithURL:bundleURL] resourcePath], lco];
        NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
        NSError *error;
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
        self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:&error];
        self.player.numberOfLoops = 0; //Infinite
        [self.player play];
    }
}

-(NSString*) getSpanishPrompts: (NSString*)lco{
    NSLog(@"Play Spanish Prompts");
    if([lco isEqualToString:@"FACE_DOWN.wav"])
        return @"FACE_DOWN_ES.wav";
    if([lco isEqualToString:@"FACE_LEFT.wav"])
        return @"FACE_LEFT_ES.wav";
    if([lco isEqualToString:@"FACE_RIGHT.wav"])
        return @"FACE_RIGHT_ES.wav";
    if([lco isEqualToString:@"FACE_TILT_LEFT.wav"])
        return @"FACE_TILT_LEFT_ES.wav";
    if([lco isEqualToString:@"FACE_TILT_RIGHT.wav"])
        return @"FACE_TILT_RIGHT_ES.wav";
    if([lco isEqualToString:@"FACE_NEUTRAL.wav"])
        return @"FACE_NEUTRAL_ES.wav";
    if([lco isEqualToString:@"FACE_UP.wav"])
        return @"FACE_UP_ES.wav";
    if([lco isEqualToString:@"LIVENESS_FAILED.wav"])
        return @"LIVENESS_FAILED_ES.wav";
    if([lco isEqualToString:@"LIVENESS_SUCCESS.wav"])
        return @"LIVENESS_SUCCESS_ES.wav";
    if([lco isEqualToString:@"LIVENESS_TRY_AGAIN.wav"])
        return @"LIVENESS_TRY_AGAIN.wav";
    if([lco isEqualToString:@"SMILE.wav"])
        return @"SMILE_ES.wav";
    return @"";
}

-(void) illuminateLivenessChallengeOnCircle:(NSString*) lcoSignal{
    NSLog(@"Illuminate Liveness Challenge On Circle");
    [self playSound: [NSString stringWithFormat:@"%@.wav",lcoSignal]];
    if ([lcoSignal isEqualToString:@"FACE_UP"]) {
        self.progressCircle.path = [UIBezierPath bezierPathWithArcCenter: self.cameraCenterPoint radius:(self.backgroundWidthHeight / 2) startAngle: 1.2 * M_PI endAngle: 1.8 * M_PI clockwise:YES].CGPath;
        self.progressCircle.drawsAsynchronously = YES;
        self.progressCircle.borderWidth = 20;
        self.progressCircle.fillColor =  [UIColor greenColor].CGColor;
    } else if ([lcoSignal isEqualToString:@"FACE_DOWN"]) {
        self.progressCircle.path = [UIBezierPath bezierPathWithArcCenter: self.cameraCenterPoint radius:(self.backgroundWidthHeight / 2) startAngle: 0.2 * M_PI endAngle: 0.8 * M_PI clockwise:YES].CGPath;
        self.progressCircle.drawsAsynchronously = YES;
        self.progressCircle.borderWidth = 20;
        self.progressCircle.fillColor =  [UIColor greenColor].CGColor;
    } else if ([lcoSignal isEqualToString:@"FACE_RIGHT"]) {
        self.progressCircle.path = [UIBezierPath bezierPathWithArcCenter: self.cameraCenterPoint radius:(self.backgroundWidthHeight / 2) startAngle: 1.75 * M_PI endAngle: 0.25 * M_PI clockwise:YES].CGPath;
        self.progressCircle.drawsAsynchronously = YES;
        self.progressCircle.borderWidth = 20;
        self.progressCircle.fillColor =  [UIColor greenColor].CGColor;
    } else if ([lcoSignal isEqualToString:@"FACE_LEFT"]) {
        self.progressCircle.path = [UIBezierPath bezierPathWithArcCenter: self.cameraCenterPoint radius:(self.backgroundWidthHeight / 2) startAngle: 0.75 * M_PI endAngle: 1.25 * M_PI clockwise:YES].CGPath;
        self.progressCircle.borderWidth = 20;
        self.progressCircle.drawsAsynchronously = YES;
        self.progressCircle.fillColor =  [UIColor greenColor].CGColor;
    } else if([lcoSignal isEqualToString:@"FACE_TILT_LEFT"]){
        self.progressCircle.path = [UIBezierPath bezierPathWithArcCenter: self.cameraCenterPoint radius:(self.backgroundWidthHeight / 2) startAngle: -0.5 * M_PI endAngle:-M_PI clockwise:NO].CGPath;
        self.progressCircle.borderWidth = 20;
        self.progressCircle.drawsAsynchronously = YES;
        self.progressCircle.fillColor =  [UIColor greenColor].CGColor;
    } else if([lcoSignal isEqualToString:@"FACE_TILT_RIGHT"]){
        self.progressCircle.path = [UIBezierPath bezierPathWithArcCenter: self.cameraCenterPoint radius:(self.backgroundWidthHeight / 2) startAngle: 0 endAngle: -0.4 * M_PI clockwise:NO].CGPath;
        self.progressCircle.borderWidth = 20;
        self.progressCircle.drawsAsynchronously = YES;
        self.progressCircle.fillColor =  [UIColor greenColor].CGColor;
    }  else if([lcoSignal isEqualToString:@"SMILE"]){
        self.progressCircle.path = [UIBezierPath bezierPathWithArcCenter: self.cameraCenterPoint radius:(self.backgroundWidthHeight / 2) startAngle: 0 endAngle: 2*M_PI clockwise:NO].CGPath;
        self.progressCircle.borderWidth = 20;
        self.progressCircle.drawsAsynchronously = YES;
        self.progressCircle.fillColor =  [UIColor greenColor].CGColor;
    }
}


-(void) startDelayedAudioRecording:(NSTimeInterval)delayTime{
    NSLog(@"Start Delayed Audio Recording");
    NSLog(@"|-doLivenessDetection = %d", self.doLivenessDetection);
    NSLog(@"|-isChallengeRetrieved = %d", self.isChallengeRetrieved);
    NSLog(@"|-continueRunning = %d", self.continueRunning);

    if(self.doLivenessDetection && self.isChallengeRetrieved) {
        [self startRecordingVideo];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayTime * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if(self.continueRunning){
                [self setMessage:[ResponseManager getMessage:@"VERIFY" variable:self.thePhrase]];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    if(self.continueRunning){
                        [self startRecordingAudio];
                    }
                });
            }
        });
    }
}

-(void) startVerificationProcess{
    NSLog(@"Start Verification Process");
    NSLog(@"|-doLivenessDetection = %d", self.doLivenessDetection);
    NSLog(@"|-lookingIntoCam = %d", self.lookingIntoCam);
    NSLog(@"|-isProcessing = %d", self.isProcessing);
    if (!self.continueRunning) {
        return;
    }
        [self.myVoiceIt getAllVideoEnrollments:_userToVerifyUserId callback:^(NSString * jsonResponse){
            NSDictionary *jsonObj = [Utilities getJSONObject:jsonResponse];
            NSString * responseCode = [jsonObj objectForKey:@"responseCode"];
            if([responseCode isEqualToString:@"SUCC"]){
                int enrollmentsCount = [[jsonObj valueForKey:@"count"] intValue];
                if(enrollmentsCount < 3){
                    [self notEnoughEnrollments:@"{\"responseCode\":\"TVER\",\"message\":\"Not enough video enrollments\"}"];
                } else {
                    // Start Audio recording without Liveness
                    if(!self.doLivenessDetection && self.lookingIntoCam){
                        [self startDelayedAudioRecording:0.4];
                    } else {
                        // Show Livness Instructions before recording Video
                        if(!self.isProcessing){
                            [self setMessage: self.livenessInstruction];
                        }
                    }
                }
            } else {
                [self notEnoughEnrollments:@"{\"responseCode\":\"TVER\",\"message\":\"Not enough video enrollments\"}"];
            }
        }];
}

-(void) startRecordingVideo {
    NSLog(@"Start Recording Video");
    NSLog(@"|-doLivenessDetection = %d", self.doLivenessDetection);
    NSLog(@"|-isChallengeRetrieved = %d", self.isChallengeRetrieved);
    NSLog(@"|-continueRunning = %d", self.continueRunning);

    self.isRecording = YES;
    self.isProcessing = YES;
    
    if(self.doLivenessDetection && self.isChallengeRetrieved){
        // Liveness
        [self startRecordingVideoWithLivenessChallenges];
    } else {
        // No Livness
        [self startWritingToVideoFile];
        [self setMessage:[ResponseManager getMessage:@"VERIFY" variable:self.thePhrase]];
        
        // Start Progress Circle Around Face Animation
        [self animateProgressCircleForAudioRecording];
        
        // Stop recording video/Audio Recording after 5 seconds
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if(self.continueRunning){
                if (!self.doLivenessDetection) {
                    [self stopRecordingAudio];
                }
            }
        });
    }
}

-(void) startRecordingVideoWithLivenessChallenges{
    NSLog(@"Start Recording Video With Liveness Challenges");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, [self.livenessChallengeTime floatValue] * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self setMessage:[ResponseManager getMessage:@"VERIFY" variable:self.thePhrase]];
        [self animateProgressCircleForAudioRecording];
    });
    [self setLivenessChallengeMessages];
    // Setup for callback to on completed video recording captureOutput
    NSString * outputPath = [Utilities pathForTemporaryFileWithSuffix:@"mp4"];
    NSURL * outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
    [self.movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
}

- (UIImage *) imageFromCIImage:(CIImage *)ciImage{
    NSLog(@"Get Image From CIImage");
    CIContext *ciContext = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [ciContext createCGImage:ciImage fromRect:[ciImage extent]];
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return image;
}

-(void) saveImageData:(CIImage *)image{
    NSLog(@"Save Image Dataa");
    if ( image != nil){
        UIImage *uiimage = [self imageFromCIImage:image];
        self.finalCapturedPhotoData  = UIImageJPEGRepresentation(uiimage, 0.4);
        self.imageIsSaved = YES;
    }
}

-(void) showUploadingCircle{
    NSLog(@"Show Upload Circle");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView setHidden:NO];
        [self setMessage:@""];
    });
}

-(void) removeUploadingCircle{
    NSLog(@"Remove Upload Circle");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView setHidden:YES];
    });
}

-(void) setAudioSessionInactive{
    NSLog(@"Set Audio Session To Inactive");
    [self.audioRecorder stop];
    NSError * err;
    [self.audioSession setActive:NO error:&err];
}

-(void) setMessage:(NSString *) newMessage {
//    NSLog(@"Set UI Message");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.messageLabel setText: newMessage];
        [self.messageLabel setAdjustsFontSizeToFitWidth:YES];
    });
}

-(void) animateProgressCircleForAudioRecording{
    NSLog(@"Animate Progress Circle For Audio Recording");
    if(self.doLivenessDetection){
        [self clearCircleAnimations];
      }
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

-(void) startRecordingAudio{
    NSLog(@"Start Recording Audio");
    self.isRecording = YES;
    self.isProcessing = YES;
    self.imageIsSaved = NO;
    self.cameraBorderLayer.backgroundColor = [UIColor clearColor].CGColor;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err;
    [audioSession setCategory:AVAudioSessionCategoryRecord error:&err];
    if (err) {
        NSLog(@"%@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
    }
    err = nil;
    if (err) {
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
    [self animateProgressCircleForAudioRecording];
}

-(void) stopRecordingAudio{
    NSLog(@"Stop Recording Audio");
    [self setAudioSessionInactive];
    self.isRecording = NO;
}

- (IBAction) cancelClicked:(id)sender{
    NSLog(@"Canceled/Continue Button Tapped");
    if(!self.doLivenessDetection){
        self.cancelPlayback = YES;
        self.continueRunning = NO;
        [self dismissViewControllerAnimated:YES completion:^{
            [self userVerificationCancelled]();
        }];
    } else {
        // Liveness
        if(self.verificationStarted == YES && [self.cancelButton.titleLabel.text isEqual:@"Continue"]){
            [self startRecordingVideo];
        }
        if(self.verificationStarted == NO || [self.cancelButton.titleLabel.text isEqual:@"Cancel"]){
            self.cancelPlayback = YES;
            self.continueRunning = NO;
            [self cleanupEverything];
            [self.player stop];
            [self dismissViewControllerAnimated:YES completion:^{
                [self userVerificationCancelled]();
            }];
        }
        if([self.cancelButton.titleLabel.text isEqual:@"Done"]){
            self.cancelPlayback = YES;
            [self dismissViewControllerAnimated:YES completion:^{
                [self userVerificationSuccessful](0,0,self.result);
            }];
        }
    }
}

#pragma mark - Camera Delegate Methods

// Code to Capture Face Rectangle and other cool metadata stuff
-(void)    captureOutput:(AVCaptureOutput *)output
didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects
          fromConnection:(AVCaptureConnection *)connection{
    
//    NSLog(@"lookingIntoCam = %d", self.lookingIntoCam);
//    NSLog(@"verificationStarted = %d", self.verificationStarted);
//    NSLog(@"doLivenessDetection = %d", self.doLivenessDetection);
//    NSLog(@"isRecording = %d", self.isRecording);
//    NSLog(@"isProcessing = %d", self.isProcessing);
//    NSLog(@"isSuccess = %d", self.isSuccess);

    if(self.doLivenessDetection){
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
        
        if(self.doLivenessDetection && !self.isRecording && !self.lookingIntoCam && !self.isProcessing && [self.progressView isHidden] && !self.isSuccess){
            [self setMessage:[ResponseManager getMessage:@"LOOK_INTO_CAM"]];
            self.verificationStarted = NO;
            [self.cancelButton setTitle:[ResponseManager getMessage:@"Cancel"] forState:UIControlStateNormal];
        }
        
        if(self.doLivenessDetection && !self.isRecording && self.lookingIntoCam && !self.isProcessing){
            if (!self.isSuccess) {
                [self setMessage:self.livenessInstruction];
                [self.cancelButton setTitle:[ResponseManager getMessage:@"Continue"] forState:UIControlStateNormal];
            } else {
                [self.cancelButton setHidden:YES];
            }
            
        }
        
        if(self.isProcessing){
            [self.cancelButton setTitle:[ResponseManager getMessage:@"Cancel"] forState:UIControlStateNormal];
        }
        
        if(self.isSuccess){
            [self.cancelButton setTitle:[ResponseManager getMessage:@"Done"] forState:UIControlStateNormal];
        }
    } else {
        // No Liveness
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
                if(!self.doLivenessDetection){
                    [self startVerificationProcess];
                }
            }
        } else {
            self.lookingIntoCam = NO;
            NSLog(@"lookingIntoCam = %d", self.lookingIntoCam);
            self.lookingIntoCamCounter = 0;
            [self.faceRectangleLayer setHidden:YES];
        }
    }
}

- (void)              captureOutput:(AVCaptureFileOutput *)captureOutput
didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
                    fromConnections:(NSArray *)connections
                              error:(NSError *)error
{
    NSLog(@"Making Video Call to Liveness Services");
    if (!self.continueRunning) {
        return;
    }
    [self.myVoiceIt videoVerificationWithLiveness:self.lcoId userId: self.userToVerifyUserId contentLanguage:self.contentLanguage videoPath:[outputFileURL path] phrase:self.thePhrase pageCategory:@"verification" callback:^(NSString * result) {
        [self handleLivenessResponse: result];
    }];
    
}

- (void) captureOutput:(AVCaptureOutput *)captureOutput
 didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
        fromConnection:(AVCaptureConnection *)connection{
    
//    NSLog(@"lookingIntoCam = %d", self.lookingIntoCam);
//    NSLog(@"verificationStarted = %d", self.verificationStarted);
//    NSLog(@"doLivenessDetection = %d", self.doLivenessDetection);
//    NSLog(@"isRecording = %d", self.isRecording);
//    NSLog(@"isProcessing = %d", self.isProcessing);
//    NSLog(@"isSuccess = %d", self.isSuccess);
    
    // Don't do any analysis when not looking into the camera with no liveness test enabled
    if(!self.lookingIntoCam && !self.doLivenessDetection && !self.isProcessing){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.messageLabel setText: [ResponseManager getMessage:@"LOOK_INTO_CAM"]];
            self.verificationStarted = NO;
        });
        return;
    }
    // When enough looking into camera time has passed and recording has not yet begun
    if(self.lookingIntoCamCounter > 5 && !self.imageIsSaved && !self.doLivenessDetection){
        // Convert to CIPixelBuffer for faceDetector
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        if (pixelBuffer == NULL) { return; }
        
        // Create CIImage for faceDetector
        CIImage *image = [CIImage imageWithCVImageBuffer:pixelBuffer];
        [self saveImageData:image];
    }
}

#pragma mark - AVAudioRecorderDelegate Methods

-(void) startWritingToVideoFile{
    NSLog(@"Start Writing to Video File");
    self.isReadyToWrite = YES;
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:640], AVVideoWidthKey, [NSNumber numberWithInt:480], AVVideoHeightKey, AVVideoCodecTypeH264, AVVideoCodecKey,nil];
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
    NSURL * videoURL = [NSURL fileURLWithPath:self.videoPath];
    /* Asset writer with MPEG4 format*/
    self.assetWriterMyData = [[AVAssetWriter alloc]
                              initWithURL: videoURL
                              fileType:AVFileTypeMPEG4
                              error:nil];
    [self.assetWriterMyData addInput:self.assetWriterInput];
    self.assetWriterInput.expectsMediaDataInRealTime = YES;
    [self.assetWriterMyData startWriting];
    [self.assetWriterMyData startSessionAtSourceTime:kCMTimeZero];
}

- (void) audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    NSLog(@"Audio Recording Finsihed Success = %d", flag);
    if (!self.continueRunning) {
        return;
    }
    [self stopRecordingAudio];
    [self clearCircleAnimations];
    [self.messageLabel setText:@""];
    [self showUploadingCircle];
    NSLog(@"Making API2 videoVerication call to server");
    [self.myVoiceIt videoVerification:self.userToVerifyUserId contentLanguage: self.contentLanguage imageData:self.finalCapturedPhotoData audioPath:self.audioPath phrase:self.thePhrase callback:^(NSString * jsonResponse){
        [Utilities deleteFile:self.audioPath];
        self.imageIsSaved = NO;
        
        [self removeUploadingCircle];
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
        } else if([responseCode isEqualToString:@"FNFD"]){
            [self setMessage:[ResponseManager getMessage: responseCode]];
            [self startDelayedAudioRecording:3.0];
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
                    [self startDelayedAudioRecording:3.0];
                } else if ([responseCode isEqualToString:@"TVER"]){
                    [self notEnoughEnrollments:jsonResponse];
                } else {
                    [self setMessage:[ResponseManager getMessage: responseCode]];
                    [self startDelayedAudioRecording:3.0];
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

-(void) stopWritingToVideoFile {
    NSLog(@"Stop Writing To Video File");
    self.isReadyToWrite = NO;
    //make sure file writing is completed
    [self.assetWriterMyData finishWritingWithCompletionHandler:^{
        if(!self.continueRunning){
            return;
        }
    }];
}

-(void) audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    NSLog(@"Audio Failed Because %@", error.localizedDescription);
}

#pragma mark - Cleanup Methods

- (void) cleanupCaptureSession {
    NSLog(@"Cleanup Capture Session");
    [self.captureSession stopRunning];
    [self cleanupVideoProcessing];
    self.captureSession = nil;
    [self.previewLayer removeFromSuperlayer];
}

- (void) cleanupVideoProcessing {
    NSLog(@"Cleanup Video Processing");
    if (self.videoDataOutput) {
        [self.captureSession removeOutput:self.videoDataOutput];
    }
    self.videoDataOutput = nil;
}

-(void) cleanupEverything {
    NSLog(@"Cleanup Everything");
    [self setAudioSessionInactive];
    [self cleanupCaptureSession];
    self.continueRunning = NO;
    if(self.doLivenessDetection){
        [self.player stop];
        self.player = nil;
    }
}

//Reset circle for Animation
-(void) clearCircleAnimations {
    NSLog(@"Clear Circle Animations - Video");
    dispatch_async(dispatch_get_main_queue(), ^{

    self.progressCircle.path = [UIBezierPath bezierPathWithArcCenter: self.cameraCenterPoint radius:(self.backgroundWidthHeight / 2) startAngle: 1.5*M_PI endAngle: (2 * M_PI)+(1.5*M_PI)  clockwise:YES].CGPath;
    self.progressCircle.drawsAsynchronously = YES;
    self.progressCircle.borderWidth = 20;
    self.progressCircle.strokeColor =  [UIColor clearColor].CGColor;
    self.progressCircle.fillColor =  [UIColor clearColor].CGColor;
    });
}
@end
