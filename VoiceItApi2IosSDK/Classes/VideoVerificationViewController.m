//
//  VideoVerificationViewController.m
//  Pods-VoiceItApi2IosSDK_Example
//
//  Created by Armaan Bindra on 3/23/18.
//

#import "VideoVerificationViewController.h"
#import "Styles.h"

@interface VideoVerificationViewController ()
@property(nonatomic, strong)  VoiceItAPITwo * myVoiceIt;
@property(nonatomic, strong)  NSString *videoPath;
@property CGFloat circleWidth;
@property CGFloat backgroundWidthHeight;
@property NSTimer * timer;
@property int currentChallenge;
@property UIColor * greenColor;
@end

@implementation VideoVerificationViewController
int VIDEO_VERIFICATION_TIME_TO_WAIT_TILL_FACE_FOUND = 15;

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue",
                                                          DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

-(int)pickChallenge{
    int rndValue = arc4random_uniform(4);
    while (rndValue == _currentChallenge){
        rndValue = arc4random_uniform(4);
    }
    return rndValue;
}

-(void)startVerificationProcess {
    [self startDelayedRecording:0.4];
}

-(void)startDelayedRecording:(NSTimeInterval)delayTime{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayTime * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if(self.continueRunning){
            [self setMessage:[ResponseManager getMessage:@"VERIFY" variable:_thePhrase]];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                if(self.continueRunning){
                    [self startRecording];
                }
            });
        }
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _greenColor = [UIColor colorWithRed:39.0f/255.0f
                                  green:174.0f/255.0f
                                   blue:96.0f/255.0f
                                  alpha:1.0f];
    _successfulChallengesCounter = 0;
    _currentChallenge = -1;
    _okResponseCodes = [[NSMutableArray alloc] initWithObjects:@"FNFD",  nil];
    _myVoiceIt = (VoiceItAPITwo *) [self voiceItMaster];
    // Initialize Boolean and All
    _lookingIntoCam = NO;
    _livenessDetectionIsHappening  = NO;
    _continueRunning = YES;
    _smileFound = NO;
    _lookingIntoCamCounter = 0;
    _smileCounter = 0;
    _blinkCounter = 0;
    _faceDirection = -2;
    _blinkState = -1;
    _failCounter = 0;
    
    // Do any additional setup after loading the view.
    [_progressView setHidden:YES];
    
    // Set up the AVCapture Session
    [self setupCaptureSession];
    [self setupVideoProcessing];
    
    // Initialize the face detector.
    NSDictionary *options = @{
                              GMVDetectorFaceMinSize : @(0.3),
                              GMVDetectorFaceTrackingEnabled : @(YES),
                              GMVDetectorFaceClassificationType : @(GMVDetectorFaceClassificationAll),
                              GMVDetectorFaceLandmarkType : @(GMVDetectorFaceLandmarkAll),
                              GMVDetectorFaceMode : @(GMVDetectorFaceAccurateMode)
                              };
    self.faceDetector = [GMVDetector detectorOfType:GMVDetectorTypeFace options:options];
    [self setupScreen];
}

-(void)startTimer:(float)seconds {
    _timer = [NSTimer scheduledTimerWithTimeInterval: seconds
                                              target:self
                                            selector:@selector(timerDone)
                                            userInfo:nil
                                             repeats:NO];
}

-(void)stopTimer{
    [_timer invalidate];
}

-(void)livenessFailedAction{
    [self stopTimer];
    self.continueRunning = NO;
    _lookingIntoCam = NO;
    [self setMessage:@"Sorry! Face Verification Failed"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.8 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated: YES completion:^{
            NSError *error;
            NSMutableDictionary * jsonResponse = [[NSMutableDictionary alloc] init];
            [jsonResponse setObject:@"LDFA" forKey:@"responseCode"];
            [jsonResponse setObject:@"Liveness detection failed" forKey:@"message"];
            [jsonResponse setObject:@0.0 forKey:@"voiceConfidence"];
            [jsonResponse setObject:@0.0 forKey:@"faceConfidence"];
            [jsonResponse setObject:@"Liveness detection failed" forKey:@"message"];
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject: jsonResponse options:0 error:&error];
            if (! jsonData) {
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

-(void)setupScreen {
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
    [[_verificationBox layer] setCornerRadius:10.0];
    [self setBottomCornersForCancelButton];
    [self setupCameraCircle];
}

- (void)viewDidUnload {
    [self cleanupCaptureSession];
    [super viewDidUnload];
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

- (IBAction)cancelClicked:(id)sender {
    [_captureSession stopRunning];
    _captureSession = nil;
    self.continueRunning = NO;
    [self setAudioSessionInactive];
    [self cleanupCaptureSession];
    [self dismissViewControllerAnimated:YES completion:^{
        [self userVerificationCancelled]();
    }];
}

-(void)setMessage:(NSString *) newMessage {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.messageLabel setText: newMessage];
        [self.messageLabel setAdjustsFontSizeToFitWidth:YES];
    });
}

-(void)setBottomCornersForCancelButton{
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect: _cancelButton.bounds byRoundingCorners:( UIRectCornerBottomLeft | UIRectCornerBottomRight) cornerRadii:CGSizeMake(10.0, 10.0)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = _cancelButton.bounds;
    maskLayer.path  = maskPath.CGPath;
    _cancelButton.layer.mask = maskLayer;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.progressView startAnimation];
    [_messageLabel setText: [ResponseManager getMessage:@"LOOK_INTO_CAM"]];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.captureSession stopRunning];
}

-(void)setupCaptureSession{
    // Setup Video Input Devices
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession beginConfiguration];
    [_captureSession setSessionPreset: AVCaptureSessionPresetMedium];
    _videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
    NSError * videoError;
    AVCaptureDeviceInput * videoInput = [AVCaptureDeviceInput deviceInputWithDevice: _videoDevice error:&videoError];
    [_captureSession addInput:videoInput];
}

-(void)setupCameraCircle{
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession: _captureSession];
    [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    //    [_captureSession addOutput:_movieFileOutput];
    // Setup code to capture face meta data
    AVCaptureMetadataOutput *metadataOutput = [[AVCaptureMetadataOutput alloc] init];
    // Have to add the output before setting metadata types
    [_captureSession addOutput: metadataOutput];
    // We're only interested in faces
    [metadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeFace]];
    // This VC is the delegate. Please call us on the main queue
    [metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    // Setup Little Camera Circle and Positions
    CALayer *rootLayer = [[self verificationBox] layer];
    _backgroundWidthHeight = (CGFloat) [self verificationBox].frame.size.height  * 0.50;
    CGFloat cameraViewWidthHeight = (CGFloat) [self verificationBox].frame.size.height  * 0.48;
    _circleWidth = (_backgroundWidthHeight - cameraViewWidthHeight) / 2;
    CGFloat backgroundViewX = ([self verificationBox].frame.size.width - _backgroundWidthHeight)/2;
    CGFloat cameraViewX = ([self verificationBox].frame.size.width - cameraViewWidthHeight)/2;
    CGFloat backgroundViewY = 30.0; // TODO: Make this number a constant
    CGFloat cameraViewY = backgroundViewY + _circleWidth;
    
    _cameraBorderLayer = [[CALayer alloc] init];
    _leftCircle = [CAShapeLayer layer];
    _rightCircle = [CAShapeLayer layer];
    _downCircle = [CAShapeLayer layer];
    _upCircle = [CAShapeLayer layer];
    _progressCircle = [CAShapeLayer layer];
    
    [_cameraBorderLayer setFrame:CGRectMake(backgroundViewX, backgroundViewY, _backgroundWidthHeight, _backgroundWidthHeight)];
    [_previewLayer setFrame:CGRectMake(cameraViewX, cameraViewY, cameraViewWidthHeight, cameraViewWidthHeight)];
    [_previewLayer setCornerRadius: cameraViewWidthHeight / 2];
    _cameraCenterPoint = CGPointMake(_cameraBorderLayer.frame.origin.x + (_backgroundWidthHeight/2), _cameraBorderLayer.frame.origin.y + (_backgroundWidthHeight/2) );
    
    if ([_videoDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        CGPoint autofocusPoint = _cameraCenterPoint;
        [_videoDevice setFocusPointOfInterest:autofocusPoint];
        [_videoDevice setFocusMode:AVCaptureFocusModeLocked];
    }
    
    _leftCircle.path = [UIBezierPath bezierPathWithArcCenter: _cameraCenterPoint radius:(_backgroundWidthHeight / 2) startAngle: 0.75 * M_PI endAngle: 1.25 * M_PI clockwise:YES].CGPath;
    _leftCircle.fillColor =  [UIColor clearColor].CGColor;
    _leftCircle.strokeColor = [UIColor clearColor].CGColor;
    _leftCircle.lineWidth = _circleWidth + 8.0;
    
    _rightCircle.path = [UIBezierPath bezierPathWithArcCenter: _cameraCenterPoint radius:(_backgroundWidthHeight / 2) startAngle: 1.75 * M_PI endAngle: 0.25 * M_PI clockwise:YES].CGPath;
    _rightCircle.fillColor =  [UIColor clearColor].CGColor;
    _rightCircle.strokeColor = [UIColor clearColor].CGColor;
    _rightCircle.lineWidth = _circleWidth + 8.0;
    
    _downCircle.path = [UIBezierPath bezierPathWithArcCenter: _cameraCenterPoint radius:(_backgroundWidthHeight / 2) startAngle: 0.75 * M_PI endAngle: 0.25 * M_PI clockwise:NO].CGPath;
    _downCircle.fillColor =  [UIColor clearColor].CGColor;
    _downCircle.strokeColor = [UIColor clearColor].CGColor;
    _downCircle.lineWidth = _circleWidth + 8.0;
    
    _upCircle.path = [UIBezierPath bezierPathWithArcCenter: _cameraCenterPoint radius:(_backgroundWidthHeight / 2) startAngle: 1.25 * M_PI endAngle: 1.75 * M_PI clockwise:YES].CGPath;
    _upCircle.fillColor =  [UIColor clearColor].CGColor;
    _upCircle.strokeColor = [UIColor clearColor].CGColor;
    _upCircle.lineWidth = _circleWidth + 8.0;
    
    // Setup Progress Circle
    _progressCircle .path = [UIBezierPath bezierPathWithArcCenter: _cameraCenterPoint radius:(_backgroundWidthHeight / 2) startAngle:-M_PI_2 endAngle:2 * M_PI - M_PI_2 clockwise:YES].CGPath;
    _progressCircle.fillColor = [UIColor clearColor].CGColor;
    _progressCircle.strokeColor = [UIColor clearColor].CGColor;
    _progressCircle.lineWidth = _circleWidth + 8.0;
    
    [_cameraBorderLayer setBackgroundColor: [UIColor clearColor].CGColor];
    _cameraBorderLayer.cornerRadius = _backgroundWidthHeight / 2;
    
    // Setup Rectangle Around Face
    _faceRectangleLayer = [[CALayer alloc] init];
    _faceRectangleLayer.zPosition = 1;
    _faceRectangleLayer.borderColor = [Styles getMainCGColor];
    _faceRectangleLayer.borderWidth  = 4.0;
    _faceRectangleLayer.opacity = 0.7;
    [_faceRectangleLayer setHidden:YES];
    
    [rootLayer addSublayer:_cameraBorderLayer];
    [rootLayer addSublayer:_leftCircle];
    [rootLayer addSublayer:_rightCircle];
    [rootLayer addSublayer:_downCircle];
    [rootLayer addSublayer:_upCircle];
    [rootLayer addSublayer:_progressCircle];
    [rootLayer addSublayer:_previewLayer];
    [_previewLayer addSublayer:_faceRectangleLayer];
    [_captureSession commitConfiguration];
    [_captureSession startRunning];
}

-(void)animateProgressCircle {
    dispatch_async(dispatch_get_main_queue(), ^{
        _progressCircle.strokeColor = [Styles getMainCGColor];
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        animation.duration = 5;
        animation.removedOnCompletion = YES;//NO;
        animation.fromValue = @(0);
        animation.toValue = @(1);
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        [_progressCircle addAnimation:animation forKey:@"drawCircleAnimation"];
    });
}

-(void)showGreenCircleLeftUnfilled{
    _leftCircle.strokeColor =  _greenColor.CGColor;
    _leftCircle.opacity = 0.3;
}

-(void)showGreenCircleRightUnfilled{
    _rightCircle.strokeColor =  _greenColor.CGColor;
    _rightCircle.opacity = 0.3;
}

-(void)showGreenCircleLeft:(BOOL) showCircle{
    _leftCircle.opacity = 1.0;
    if(showCircle){
        _leftCircle.strokeColor = _greenColor.CGColor;
    } else {
        _leftCircle.strokeColor = [UIColor clearColor].CGColor;
    }
}

-(void)showGreenCircleRight:(BOOL) showCircle{
    _rightCircle.opacity = 1.0;
    if(showCircle){
        _rightCircle.strokeColor = _greenColor.CGColor;
    } else {
        _rightCircle.strokeColor = [UIColor clearColor].CGColor;
    }
}

-(void)startRecording {
    NSLog(@"Starting RECORDING");
    _isRecording = YES;
    
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
    
    // Unique recording URL
    NSString *fileName = @"OriginalFile"; // Changed it So It Keeps Replacing File
    _audioPath = [NSTemporaryDirectory()
                  stringByAppendingPathComponent:[NSString
                                                  stringWithFormat:@"%@.wav", fileName]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:_audioPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:_audioPath
                                                   error:nil];
    }
    
    NSURL *url = [NSURL fileURLWithPath:_audioPath];
    err = nil;
    _audioRecorder = [[AVAudioRecorder alloc] initWithURL:url settings:[Utilities getRecordingSettings] error:&err];
    if(!_audioRecorder){
        NSLog(@"recorder: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
        return;
    }
    [_audioRecorder setDelegate:self];
    [_audioRecorder prepareToRecord];
    [_audioRecorder recordForDuration:4.8];
    
    // Start Progress Circle Around Face Animation
    [self animateProgressCircle];
}

-(void)stopRecording{
    _isRecording = NO;
    _progressCircle.strokeColor = [UIColor clearColor].CGColor;
}

// Code to Capture Face Rectangle and other cool metadata stuff
-(void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    BOOL faceFound = NO;
    for(AVMetadataObject *metadataObject in metadataObjects) {
        if([metadataObject.type isEqualToString:AVMetadataObjectTypeFace]) {
            [_faceRectangleLayer setHidden:NO];
            faceFound = YES;
            AVMetadataObject * face = [_previewLayer transformedMetadataObjectForMetadataObject:metadataObject];
            _faceRectangleLayer.frame = face.bounds;
            _faceRectangleLayer.cornerRadius = 10.0;
        }
    }
    
    if(faceFound) {
        if (_lookingIntoCamCounter > VIDEO_VERIFICATION_TIME_TO_WAIT_TILL_FACE_FOUND && !_lookingIntoCam && !_livenessDetectionIsHappening) {
            _lookingIntoCam = YES;
            _livenessDetectionIsHappening = YES;
            [self startLivenessDetection];
        }
        _lookingIntoCamCounter += 1;
    } else if (!_livenessDetectionIsHappening){
        [self setMessage: [ResponseManager getMessage:@"LOOK_INTO_CAM"]];
        _lookingIntoCam = NO;
        _lookingIntoCamCounter = 0;
        [_faceRectangleLayer setHidden:YES];
    } else {
        _lookingIntoCam = NO;
        _lookingIntoCamCounter = 0;
        [_faceRectangleLayer setHidden:YES];
    }
}

-(void)setupLivenessDetection{
    // TODO: Put all liveness detection setup into one method
    _lookingIntoCam = YES;
    [self showGreenCircleLeft:NO];
    [self showGreenCircleRight:NO];
    _blinkCounter = 0;
    _smileFound = NO;
    _smileCounter = 0;
    _faceDirection = -2;
    _blinkState = -1;
}

-(void)startLivenessDetection {
    if(_successfulChallengesCounter >= 2){
        _lookingIntoCam = NO;
        [self showGreenCircleLeft:NO];
        [self showGreenCircleRight:NO];
        [self startVerificationProcess];
        return;
    }
    
    _currentChallenge = [self pickChallenge];
    //    _currentChallenge = 5;
    NSLog(@"Current Challenge %d", _currentChallenge);
    [self setupLivenessDetection];
    
    // TODO: Continue putting more logic here.
    switch (_currentChallenge) {
        case 0:
            //SMILE
            [self setMessage:@"Please smile into the camera"];
            [self startTimer:2.5];
            break;
        case 1:
            //Blink
            [self setMessage:@"Please blink three times into the camera"];
            [self startTimer:3.0];
            break;
        case 2:
            //Move head left
            [self setMessage:@"Please Turn your face to the left"];
            [self startTimer:2.5];
            [self showGreenCircleLeftUnfilled];
            break;
        case 3:
            //Move head right
            [self setMessage:@"Please Turn your face to the right"];
            [self startTimer:2.5];
            [self showGreenCircleRightUnfilled];
            break;
        default:
            break;
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [_captureSession stopRunning];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)livenessChallengePassed {
    _successfulChallengesCounter++;
    _lookingIntoCam = NO;
    [_messageLabel setText:@"Perfect! You got it"];
    [self stopTimer];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if(self.continueRunning){
            [self startLivenessDetection];
        }
        
    });
}

-(void)doSmileDetection:(GMVFaceFeature *)face image:(UIImage *) image {
    if(face.hasSmilingProbability){
        if(face.smilingProbability > 0.85){
            NSLog(@"\nSMILING\n");
            _smileCounter++;
        } else {
            NSLog(@"NOT SMILING\n");
            _smileCounter = -1;
        }
    }
    
    if(_smileCounter > 5){
        if(!_smileFound){
            _smileFound = YES;
            [self saveImageData:image];
            [self livenessChallengePassed];
        }
    }
    
    if(_smileCounter == -1){
        if(_smileFound){
            //            [_messageLabel setText:@"I don't see you smiling"];
            _smileFound = NO;
        }
    }
}

-(void)doBlinkDetection:(GMVFaceFeature *)face image:(UIImage *) image {
    if(face.hasLeftEyeOpenProbability && face.hasRightEyeOpenProbability){
        if(face.leftEyeOpenProbability > 0.8 && face.rightEyeOpenProbability > 0.8){
            if(_blinkState == -1) { _blinkState = 0; }
            if(_blinkState == 1) {
                _blinkState = -1;
                _blinkCounter++;
                if(_blinkCounter == 3){
                    [self saveImageData:image];
                    [self livenessChallengePassed];
                } else {
                    [_messageLabel setText: [NSString stringWithFormat:@"Blink %d", _blinkCounter]];
                }
            }
        }
        if(face.leftEyeOpenProbability < 0.4 && face.rightEyeOpenProbability < 0.4){
            if(_blinkState == 0) { _blinkState = 1; }
        }
    }
    
}

-(void)moveHeadLeftDetection:(GMVFaceFeature *)face image:(UIImage *) image {
    if(face.hasHeadEulerAngleY && face.hasHeadEulerAngleZ){
        NSLog(@"Face angle y %f", face.headEulerAngleY);
        NSLog(@"Face angle z %f", face.headEulerAngleZ);
        if( (face.headEulerAngleY > 18.0)){
            _faceDirection = 1;
            [self showGreenCircleLeftUnfilled];
            [self livenessFailedAction];
        }
        else if(face.headEulerAngleY < - 18.0){
            NSLog(@"Head Facing Left Side : %f", face.headEulerAngleY);
            if(_faceDirection != -1){
                [self showGreenCircleLeft:YES];
                [self livenessChallengePassed];
                _faceDirection = -1;
            }
        } else {
            NSLog(@"Head Facing Straight On : %f", face.headEulerAngleY);
            if(_faceDirection != 0){
                _faceDirection = 0;
                [self saveImageData:image];
                [self showGreenCircleLeftUnfilled];
            }
        }
    }
}

-(void)moveHeadRightDetection:(GMVFaceFeature *)face image:(UIImage *) image {
    NSLog(@"Face angle y %f", face.headEulerAngleY);
    if(face.hasHeadEulerAngleY && face.hasHeadEulerAngleZ){
        if( (face.headEulerAngleY > 18.0)){
            [self showGreenCircleRight:YES];
            [self livenessChallengePassed];
            _faceDirection = 1;
        }  else if(face.headEulerAngleY < - 18.0){
            NSLog(@"Head Facing Left Side : %f", face.headEulerAngleY);
            if(_faceDirection != -1){
                _faceDirection = -1;
                [self showGreenCircleRightUnfilled];
                [self livenessFailedAction];
            }
        } else {
            NSLog(@"Head Facing Straight On : %f", face.headEulerAngleY);
            if(_faceDirection != 0){
                _faceDirection = 0;
                [self saveImageData:image];
                [self showGreenCircleRightUnfilled];
            }
        }
    }
    
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    
    // Don't do any analysis when not looking into the camera
    if(!_lookingIntoCam){
        return;
    }
    
    UIImage *image = [GMVUtility sampleBufferTo32RGBA:sampleBuffer];

    // Establish the image orientation.
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    GMVImageOrientation orientation = [GMVUtility
                                       imageOrientationFromOrientation:deviceOrientation
                                       withCaptureDevicePosition:AVCaptureDevicePositionFront
                                       defaultDeviceOrientation:deviceOrientation];
    NSDictionary *options = @{GMVDetectorImageOrientation : @(orientation)};
    // Detect features using GMVDetector.
    NSArray<GMVFaceFeature *> *faces = [self.faceDetector featuresInImage:image options:options];
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        // Display detected features in overlay.
        for (GMVFaceFeature *face in faces) {
            
            switch (_currentChallenge) {
                case 0:
                    // SMILE
                    [self doSmileDetection:face image:image];
                    break;
                case 1:
                    // Do Blink Detection
                    [self doBlinkDetection:face image:image];
                    break;
                case 2:
                    //Move head left
                    [self moveHeadLeftDetection:face image:image];
                    break;
                case 3:
                    //Move head right
                    [self moveHeadRightDetection:face image:image];
                    break;
                default:
                    break;
            }
        }
    });
}

-(void)saveImageData:(UIImage *)image{
    if ( image != nil){
        _finalCapturedPhotoData  = UIImageJPEGRepresentation(image, 0.8);
    }
}

-(void)showLoading{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_progressView setHidden:NO];
        [self setMessage:@""];
    });
}

-(void)removeLoading{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_progressView setHidden:YES];
    });
}


-(void)setAudioSessionInactive{
    [self.audioRecorder stop];
    NSError * err;
    [_audioSession setActive:NO error:&err];
}

#pragma mark - AVAudioRecorderDelegate Methods

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    NSLog(@"AUDIO RECORDED FINISHED SUCCESS = %d", flag);
    [self setAudioSessionInactive];
    [self stopRecording];
    [self showLoading];
    [_myVoiceIt videoVerification:_userToVerifyUserId contentLanguage: _contentLanguage imageData:_finalCapturedPhotoData audioPath:_audioPath callback:^(NSString * jsonResponse){
            [self removeLoading];
            NSLog(@"Video Verification JSON Response : %@", jsonResponse);
            NSDictionary *jsonObj = [Utilities getJSONObject:jsonResponse];
            NSLog(@"Response Code is %@ and message is : %@", [jsonObj objectForKey:@"responseCode"], [jsonObj objectForKey:@"message"]);
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
            } else {
                if(![_okResponseCodes containsObject:responseCode]){
                    _failCounter += 1;
                }
                
                if(_failCounter < 3){
                    if([responseCode isEqualToString:@"STTF"]){
                        [self setMessage:[ResponseManager getMessage: responseCode variable:_thePhrase]];
                        [self startDelayedRecording:3.0];
                    }
                    else if ([responseCode isEqualToString:@"TVER"]){
                        [self setMessage:[ResponseManager getMessage: responseCode]];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                            [self dismissViewControllerAnimated: YES completion:^{
                                [self userVerificationFailed](0.0, 0.0, jsonResponse);
                            }];
                        });
                    }else{
                        [self setMessage:[ResponseManager getMessage: responseCode]];
                        [self startDelayedRecording:3.0];
                    }
                } else {
                    [self setMessage:[ResponseManager getMessage: @"TOO_MANY_ATTEMPTS"]];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        float faceConfidence = [[jsonObj objectForKey:@"faceConfidence"] floatValue];
                        float voiceConfidence = [[jsonObj objectForKey:@"voiceConfidence"] floatValue];
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

@end

