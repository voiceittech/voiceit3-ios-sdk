//
//  FaceVerificationViewController.m
//  VoiceIt2-IosSDK
//
//  Created by VoiceIt Technologies, LLC
//  Copyright (c) 2020 VoiceIt Technologies, LLC. All rights reserved.
//

#import "FaceVerificationViewController.h"
#import "Styles.h"

@interface FaceVerificationViewController ()
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

@implementation FaceVerificationViewController

#pragma mark - Life Cycle Methods

- (id) initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (IBAction) stopFaceVerification:(id)sender {
    NSLog(@"Stop Face Verification");
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
    NSLog(@"view Will Disappear");
    [super viewWillDisappear:animated];
    [self cleanupEverything];
}

- (void)notEnoughFaceEnrollments:(NSString *) jsonResponse {
    NSLog(@"Not Enough Face Enrollments");
    [self setMessage:[ResponseManager getMessage: @"NFEF"]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated: YES completion:^{
            [self userVerificationFailed](0.0, jsonResponse);
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
                [self userVerificationFailed](0.0, self.uiMessage);
            }];
        });
    }
    
    // Passed Liveness and Passed API 2 Verification
    if(self.success){
        NSLog(@"Liveness Passed and Retry is False : result : %@", self.uiMessage);
        self.isProcessing = NO;
        self.isSuccess = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.messageLabel setText:self.uiMessage];
            // Hide Button
            [self.cancelButton setHidden:YES];
        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated: YES completion:^{
                [self userVerificationSuccessful](0.0, self.uiMessage);
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
        NSLog(@"%@",error);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.messageLabel setText: @"Liveness service failed. Please Try again Later."];
            [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
        });
    } pageCateory:@"verification"];
}

-(void) setLivenessChallengeMessages{
    NSLog(@"Set Liveness Challenge Messages");
    if (!self.continueRunning) {
        return;
    }
    // Record time from liveness server
    float timeToStop = [self.livenessChallengeTime floatValue];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, timeToStop * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self stopRecordingVideo];
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
-(void) setupScreen {
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

- (void) setupVideoProcessing {
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
    NSLog(@"Play Sound");
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
    NSLog(@"Get Spanish Prompts");
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
        self.progressCircle.path = [UIBezierPath bezierPathWithArcCenter: self.cameraCenterPoint radius:(self.backgroundWidthHeight / 2) startAngle: 0 endAngle: -0.4*M_PI clockwise:NO].CGPath;
        self.progressCircle.borderWidth = 20;
        self.progressCircle.drawsAsynchronously = YES;
        self.progressCircle.fillColor =  [UIColor greenColor].CGColor;
    } else if([lcoSignal isEqualToString:@"SMILE"]){
        self.progressCircle.path = [UIBezierPath bezierPathWithArcCenter: self.cameraCenterPoint radius:(self.backgroundWidthHeight / 2) startAngle: 0 endAngle: 2*M_PI clockwise:NO].CGPath;
        self.progressCircle.borderWidth = 20;
        self.progressCircle.drawsAsynchronously = YES;
        self.progressCircle.fillColor =  [UIColor greenColor].CGColor;
    }
}

-(void) startWritingToVideoFile{
    NSLog(@"Start Writing To Video File");
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

-(void) finishVerification:(NSString *)jsonResponse{
    NSLog(@"Finished Verification");
    [self removeUploadingCircle];
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
        } else if(self.failCounter < self.failsAllowed){
            if ([responseCode isEqualToString:@"FAIL"]){
                [self setMessage:[ResponseManager getMessage: @"VERIFY_FACE_FAILED_TRY_AGAIN"]];
                [self startDelayedFaceRecording:3.0];
            }
            else if ([responseCode isEqualToString:@"NFEF"]){
                [self notEnoughFaceEnrollments:jsonResponse];
            } else{
                [self setMessage:[ResponseManager getMessage: responseCode]];
                [self startDelayedFaceRecording:3.0];
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

-(void) sendVideo{
    NSLog(@"Send Video");
    if (!self.continueRunning) {
        return;
    }
    [self clearCircleAnimations];
    [self showUploadingCircle];
    [self setMessage:@""];
    [self.myVoiceIt faceVerificationWithLiveness:self.userToVerifyUserId videoPath:self.videoPath callback:^(NSString * jsonResponse){
        [self handleLivenessResponse:jsonResponse];
    } lcoId: self.lcoId pageCategory:@"verification"];
}

-(void) sendPhoto{
    NSLog(@"Send Photo");
    if (!self.continueRunning) {
        return;
    }
    [self clearCircleAnimations];
    [self showUploadingCircle];
    [self.myVoiceIt faceVerification:self.userToVerifyUserId imageData:self.finalCapturedPhotoData callback:^(NSString * jsonResponse){
        [self finishVerification:jsonResponse];
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
        if(self.doLivenessDetection){
            [self sendVideo];
        }
        else{
            [self sendPhoto];
        }
    }];
}

-(void) setMessage:(NSString *) newMessage {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.messageLabel setText: newMessage];
        [self.messageLabel setAdjustsFontSizeToFitWidth:YES];
    });
}

-(void) startVerificationProcess{
    NSLog(@"Start Verificaiton Process");
    if (!self.continueRunning) {
        return;
    }
    [self.myVoiceIt getAllFaceEnrollments:_userToVerifyUserId callback:^(NSString * jsonResponse){
        NSDictionary *jsonObj = [Utilities getJSONObject:jsonResponse];
        NSString * responseCode = [jsonObj objectForKey:@"responseCode"];
        if([responseCode isEqualToString:@"SUCC"]){
            [self.myVoiceIt getAllVideoEnrollments:self.userToVerifyUserId callback:^(NSString * jsonResponse){
                NSDictionary *jsonObj2 = [Utilities getJSONObject:jsonResponse];
                int faceEnrollmentsCount = [[jsonObj valueForKey:@"count"] intValue];
                int videoEnrollmentsCount = [[jsonObj2 valueForKey:@"count"] intValue];
                if(faceEnrollmentsCount < 1 && videoEnrollmentsCount < 1){
                    [self notEnoughFaceEnrollments:@"{\"responseCode\":\"NFEF\",\"message\":\"No face enrollments found\"}"];
                } else {
                    // Start Video Recording without Liveness
                    if(!self.doLivenessDetection){
                        [self startRecordingVideo];
                    } else {
                        // Show Livness Instructions before recording Video
                        if(!self.isProcessing){
                            [self setMessage: self.livenessInstruction];
                        }
                    }
                }
            }];
        } else {
            [self notEnoughFaceEnrollments:@"{\"responseCode\":\"NFEF\",\"message\":\"No face enrollments found\"}"];
        }
    }];
}

-(void) startRecordingVideo {
    NSLog(@"Start Recording Video");
    self.isRecording = YES;
    self.isProcessing = YES;
    
    if(self.doLivenessDetection && self.isChallengeRetrieved){
        [self startWritingToVideoFile];
        [self setLivenessChallengeMessages];
    } else {
        [self startWritingToVideoFile];
        [self setMessage:[ResponseManager getMessage:@"WAIT_FOR_FACE_VERIFICATION"]];
        
        // Start Progress Circle Around Face Animation
        [self animateProgressCircleForFaceRecording];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if(self.continueRunning){
                if (!self.doLivenessDetection) {
                    [self stopRecordingVideo];
                }
            }
        });
    }
}

-(void) startDelayedFaceRecording:(NSTimeInterval)delayTime{
    NSLog(@"Start Delayed Face Recording");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayTime * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if(self.continueRunning){
            [self startRecordingVideo];
        }
    });
}

-(void) animateProgressCircleForFaceRecording {
    NSLog(@"Animate Progress Circle for Face Recording");
    if(self.doLivenessDetection){
        [self clearCircleAnimations];
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

-(void) stopRecordingVideo{
    NSLog(@"Stop Recording Video");
    self.isRecording = NO;
    [self stopWritingToVideoFile];
}

-(void) showUploadingCircle{
    NSLog(@"Show Uploading Circle");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView setHidden:NO];
        [self setMessage:@""];
    });
}

-(void) removeUploadingCircle{
    NSLog(@"Remove Uploading Circle");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView setHidden:YES];
    });
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
                [self userVerificationSuccessful](0,self.result);
            }];
        }
    }
}

#pragma mark - Camera Delegate Methods

// Code to Capture Face Rectangle and other cool metadata stuff
-(void)    captureOutput:(AVCaptureOutput *)output
didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects
          fromConnection:(AVCaptureConnection *)connection{
    
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
}

- (void) captureOutput:(AVCaptureOutput *)captureOutput
 didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
        fromConnection:(AVCaptureConnection *)connection {
    
    // Don't do any analysis when not looking into the camera
    if(!self.lookingIntoCam){
        return;
    }
    
    if (self.isRecording && self.isReadyToWrite){
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
        
        if(!self.doLivenessDetection){
            CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
            if (pixelBuffer == NULL) { return; }
            
            // Create CIImage for faceDetector
            CIImage *image = [CIImage imageWithCVImageBuffer:pixelBuffer];
            [self saveImageData:image];
        }
    }
}

#pragma mark - image capture methods
- (UIImage *) imageFromCIImage:(CIImage *)ciImage{
    NSLog(@"Get Image from CIImage");
    CIContext *ciContext = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [ciContext createCGImage:ciImage fromRect:[ciImage extent]];
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return image;
}

-(void) saveImageData:(CIImage *)image{
    NSLog(@"Save Image Data");
    if ( image != nil){
        UIImage *uiimage = [self imageFromCIImage:image];
        self.finalCapturedPhotoData  = UIImageJPEGRepresentation(uiimage, 0.4);
        self.imageIsSaved = YES;
    }
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
    [self cleanupCaptureSession];
    self.continueRunning = NO;
    if(self.doLivenessDetection){
        [self.player stop];
        self.player = nil;
    }
}

//Reset circle for Animation
-(void) clearCircleAnimations {
    NSLog(@"Clear Circle Animations - Face");
    dispatch_async(dispatch_get_main_queue(), ^{

    self.progressCircle.path = [UIBezierPath bezierPathWithArcCenter: self.cameraCenterPoint radius:(self.backgroundWidthHeight / 2) startAngle: 1.5*M_PI endAngle: (2 * M_PI)+(1.5*M_PI)  clockwise:YES].CGPath;
    self.progressCircle.drawsAsynchronously = YES;
    self.progressCircle.borderWidth = 20;
    self.progressCircle.strokeColor =  [UIColor clearColor].CGColor;
    self.progressCircle.fillColor =  [UIColor clearColor].CGColor;
    });
}
@end
