//
//  Liveness.m
//  VoiceIt2-IosSDK
//
//  Created by VoiceIt Technologies, LLC
//  Copyright (c) 2020 VoiceIt Technologies, LLC. All rights reserved.
//

#import "Liveness.h"
#import "NSMutableArray+Shuffle.h"
#import "Utilities.h"
#import "ResponseManager.h"
#import <AVFoundation/AVFoundation.h>

@implementation Liveness

- (id)init:(UIViewController *)mVC cCP:(CGPoint) cCP bgWH:(CGFloat) bgWH cW:(CGFloat) cW rL:(CALayer *)rL mL:(UILabel *)mL doAudio:(BOOL)doAudio lFA:(int)lFA livenessPassed:(void (^)(NSData *))livenessPassed livenessFailed:(void (^)(void))livenessFailed {
    self.masterViewController = mVC;
    self.cameraCenterPoint = cCP;
    self.backgroundWidthHeight = bgWH;
    self.circleWidth = cW;
    self.rootLayer = rL;
    self.messageLabel = mL;
    self.livenessSuccess = livenessPassed;
    self.livenessFailed = livenessFailed;
    self.numberOfLivenessFailsAllowed = lFA;
    self.audioPromptsIsHappening = doAudio;
    
    [self resetVariables];
    
    // Initialize the face detector.
    CIContext *context = [CIContext context];
    NSDictionary *opts = @{ CIDetectorAccuracy : CIDetectorAccuracyHigh };
    self.faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:context
                                              options:opts];
    return self;
}

-(void)resetVariables{
    self.continueRunning = YES;
    self.successfulChallengesCounter = 0;
    self.currentChallenge = -1;
    self.currentChallengeIndex = 0;
    self.smileFound = NO;
    self.smileCounter = 0;
    self.blinkCounter = 0;
    self.faceDirection = -2;
    self.blinkState = -1;
    self.failCounter = 0;
    self.livenessChallengeIsHappening = NO;
    self.numberOfSuccessfulChallengesNeeded = 2;
    // Setup challenge array
    [self setupChallengeArray];
    [self setupLivenessCircles];
    NSLog(@"ALL LIVENESS VARIABLES ARE RESET");
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
    }
}

-(void)setMessage:(NSString *) newMessage {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.messageLabel setText: newMessage];
        [self.messageLabel setAdjustsFontSizeToFitWidth:YES];
    });
}

-(void)setupChallengeArray{
    self.challengeArray = [NSMutableArray array];
    for (NSInteger i = 0; i < 4; i++){
        [self.challengeArray addObject:[NSNumber numberWithInteger:i]];
    }
    [self.challengeArray shuffle];
}

-(int)pickChallenge{
    NSInteger itemIndex = (NSInteger) self.currentChallengeIndex;
    int pickedItem = [[self.challengeArray objectAtIndex:itemIndex] intValue];
    if(self.currentChallengeIndex >= ([self.challengeArray count] - 1)){
        self.currentChallengeIndex = 0;
    } else {
        self.currentChallengeIndex++;
    }
    return pickedItem;
}

-(void)startTimer:(float)seconds {
    if ([NSThread isMainThread]) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval: seconds target: self selector: @selector(timerDone) userInfo: nil repeats: NO];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
        self.timer = [NSTimer scheduledTimerWithTimeInterval: seconds target: self selector: @selector(timerDone) userInfo: nil repeats: NO];
    });
    }
}

-(void)stopTimer{
    [self.timer invalidate];
}

-(void)livenessFailedAction{
    [self stopTimer];
    self.failCounter++;
    if(self.failCounter <= self.numberOfLivenessFailsAllowed){
        [self livenessChallengeTryAgain];
    } else {
        self.continueRunning = NO;
        self.livenessFailed();
    }
}

-(void)timerDone{
    [self livenessFailedAction];
}

-(void)setupLivenessCircles{
    self.leftCircle = [CAShapeLayer layer];
    self.rightCircle = [CAShapeLayer layer];
    
    self.leftCircle.path = [UIBezierPath bezierPathWithArcCenter: self.cameraCenterPoint radius:(self.backgroundWidthHeight / 2) startAngle: 0.75 * M_PI endAngle: 1.25 * M_PI clockwise:YES].CGPath;
    self.leftCircle.fillColor =  [UIColor clearColor].CGColor;
    self.leftCircle.strokeColor = [UIColor clearColor].CGColor;
    self.leftCircle.lineWidth = self.circleWidth + 8.0;
    self.leftCircle.drawsAsynchronously = YES;
    [self.leftCircle needsLayout];
    
    self.rightCircle.path = [UIBezierPath bezierPathWithArcCenter: self.cameraCenterPoint radius:(self.backgroundWidthHeight / 2) startAngle: 1.75 * M_PI endAngle: 0.25 * M_PI clockwise:YES].CGPath;
    self.rightCircle.fillColor =  [UIColor clearColor].CGColor;
    self.rightCircle.strokeColor = [UIColor clearColor].CGColor;
    self.rightCircle.lineWidth = self.circleWidth + 8.0;
    self.rightCircle.drawsAsynchronously = YES;
    [self.rightCircle needsLayout];

    [self.rootLayer addSublayer:self.leftCircle];
    [self.rootLayer addSublayer:self.rightCircle];
}

-(void)showGreenCircleLeftUnfilled{
    self.leftCircle.strokeColor = [UIColor greenColor].CGColor;
    self.leftCircle.opacity = 0.3;
    [self.rootLayer replaceSublayer:self.leftCircle with:self.leftCircle];
}

-(void)showGreenCircleRightUnfilled{
    self.rightCircle.strokeColor =  [UIColor greenColor].CGColor;
    self.rightCircle.opacity = 0.3;
    [self.rootLayer replaceSublayer:self.rightCircle with:self.rightCircle];
}

-(void)showGreenCircleLeft:(BOOL) showCircle{
    self.leftCircle.opacity = 1.0;
    if(showCircle){
        self.leftCircle.strokeColor = [UIColor greenColor].CGColor;
    } else {
        self.leftCircle.strokeColor = [UIColor clearColor].CGColor;
    }
    [self.rootLayer replaceSublayer:self.leftCircle with:self.leftCircle];

}

-(void)showGreenCircleRight:(BOOL) showCircle{
    self.rightCircle.opacity = 1.0;
    if(showCircle){
        self.rightCircle.strokeColor = [UIColor greenColor].CGColor;
    } else {
        self.rightCircle.strokeColor = [UIColor clearColor].CGColor;
    }
    [self.rootLayer replaceSublayer:self.rightCircle with:self.rightCircle];
}

-(void)setupLivenessDetection{
    [self showGreenCircleLeft:NO];
    [self showGreenCircleRight:NO];
    self.blinkCounter = 0;
    self.smileFound = NO;
    self.smileCounter = 0;
    self.faceDirection = -2;
    self.blinkState = -1;
    self.livenessChallengeIsHappening = YES;
    self.numberOfSuccessfulChallengesNeeded = 2;
}

-(void)doLivenessDetection {
    if(!self.continueRunning){
        return;
    }
    
    NSLog(@"successfulChallengesCounter : %d", self.successfulChallengesCounter);
    if(self.successfulChallengesCounter >= self.numberOfSuccessfulChallengesNeeded){
        self.continueRunning = NO;
        [self showGreenCircleLeft:NO];
        [self showGreenCircleRight:NO];
        self.livenessSuccess(_finalCapturedPhotoData);
        // TODO: Successfully Finished Liveness Detection Call Success Callback
        return;
    }

    self.currentChallenge = [self pickChallenge];
    NSLog(@"Current Challenge is %d", self.currentChallenge);
    [self setupLivenessDetection];

    // TODO: Continue putting more logic here.
    switch (self.currentChallenge) {
        case 0:
            //SMILE
            [self setMessage:[ResponseManager getMessage:@"SMILE"]];

            //Play SMILE.wav
            if (self.audioPromptsIsHappening) {
                NSBundle * podBundle = [NSBundle bundleForClass: self.classForCoder];
                NSURL * bundleURL = [[podBundle resourceURL] URLByAppendingPathComponent:@"VoiceIt2-IosSDK.bundle"];
                NSString *soundFilePath = [NSString stringWithFormat:@"%@/SMILE.wav",[[[NSBundle alloc] initWithURL:bundleURL] resourcePath]];
                NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
                NSError *error;

                AVAudioSession *session = [AVAudioSession sharedInstance];
                [session setCategory:AVAudioSessionCategoryPlayback error:nil];
                self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:&error];
                self.player.numberOfLoops = 0; //Infinite
                [self.player play];
            }
            // How long to wait for liveness Challenge
            [self startTimer:3.5];
            break;
        case 1:
            //Blink
            [self setMessage:[ResponseManager getMessage:@"BLINK"]];

            //Play BLINK.wav
            if (self.audioPromptsIsHappening) {
                NSBundle * podBundle = [NSBundle bundleForClass: self.classForCoder];
                NSURL * bundleURL = [[podBundle resourceURL] URLByAppendingPathComponent:@"VoiceIt2-IosSDK.bundle"];
                NSString *soundFilePath = [NSString stringWithFormat:@"%@/BLINK.wav",[[[NSBundle alloc] initWithURL:bundleURL] resourcePath]];
                NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
                NSError *error;

                AVAudioSession *session = [AVAudioSession sharedInstance];
                [session setCategory:AVAudioSessionCategoryPlayback error:nil];
                self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:&error];
                self.player.numberOfLoops = 0; //Infinite
                [self.player play];
            }
            // How long to wait for liveness Challenge
            [self startTimer:4.0];
            break;
        case 2:
            //Move head left
            [self setMessage:[ResponseManager getMessage:@"FACE_LEFT"]];

            //Play FACE_LEFT.wav
            if (self.audioPromptsIsHappening) {
                NSBundle * podBundle = [NSBundle bundleForClass: self.classForCoder];
                NSURL * bundleURL = [[podBundle resourceURL] URLByAppendingPathComponent:@"VoiceIt2-IosSDK.bundle"];
                NSString *soundFilePath = [NSString stringWithFormat:@"%@/FACE_LEFT.wav",[[[NSBundle alloc] initWithURL:bundleURL] resourcePath]];
                NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
                NSError *error;

                AVAudioSession *session = [AVAudioSession sharedInstance];
                [session setCategory:AVAudioSessionCategoryPlayback error:nil];
                self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:&error];
                self.player.numberOfLoops = 0; //Infinite
                [self.player play];
            }
            // How long to wait for liveness Challenge
            [self startTimer:3.5];
            break;
        case 3:
            //Move head right
            [self setMessage:[ResponseManager getMessage:@"FACE_RIGHT"]];

            //Play FACE_RIGHT.wav
            if (self.audioPromptsIsHappening) {
                NSBundle * podBundle = [NSBundle bundleForClass: self.classForCoder];
                NSURL * bundleURL = [[podBundle resourceURL] URLByAppendingPathComponent:@"VoiceIt2-IosSDK.bundle"];
                NSString *soundFilePath = [NSString stringWithFormat:@"%@/FACE_RIGHT.wav",[[[NSBundle alloc] initWithURL:bundleURL] resourcePath]];
                NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
                NSError *error;

                AVAudioSession *session = [AVAudioSession sharedInstance];
                [session setCategory:AVAudioSessionCategoryPlayback error:nil];
                self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:&error];
                self.player.numberOfLoops = 0; //Infinite
                [self.player play];
            }
            // How long to wait for liveness Challenge
            [self startTimer:3.5];
            break;
        default:
            break;
    }
}

-(void)doLivenessDetection: (NSString *) challengeString
                        challengeTime: (NSNumber *) challengeTime{
    [self setMessage:challengeString];
    [self startTimer:[challengeTime floatValue]];

    
    //API Call to face/voice endpoints
    
}

-(void)livenessChallengePassed {
    self.livenessChallengeIsHappening = NO;
    self.successfulChallengesCounter++;
    [self setMessage:[ResponseManager getMessage:@"LIVENESS_SUCCESS"]];

    [self stopTimer];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if(self.continueRunning){
            [self doLivenessDetection];
        }
    });
}

-(void)livenessChallengeTryAgain {
    self.livenessChallengeIsHappening = NO;
    [self setMessage:[ResponseManager getMessage:@"LIVENESS_TRY_AGAIN"]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if(self.continueRunning){
            [self doLivenessDetection];
        }
    });
}

# pragma mark - Liveness Challenges

-(void)doSmileDetection:(CIFaceFeature *)face image:(CIImage *) image {
    NSLog(@"Face hasSmile %d", face.hasSmile);

    if(face.hasSmile){
       self.smileCounter++;
    }

    if (self.smileCounter > 3){
        [self saveImageData:image];
        [self livenessChallengePassed];
    }
}

-(void)doBlinkDetection:(CIFaceFeature *)face image:(CIImage *) image {
    NSLog(@"Face leftEyeClosed %d", face.leftEyeClosed);
    NSLog(@"Face rightEyeClosed %d", face.rightEyeClosed);
    NSLog(@"Face blinkState %d", self.blinkState);
    NSLog(@"Face blinkCounter %d", self.blinkCounter);

    // Check if eye are close
    if(face.leftEyeClosed && face.rightEyeClosed){
        if (self.blinkState == -1) {
            self.blinkCounter++;
            self.blinkState = 0;
        }
        if (self.blinkCounter == 3){
            [self saveImageData:image];
            [self livenessChallengePassed];
        } else {
            [self.messageLabel setText: [NSString stringWithFormat:@"Blink %d", self.blinkCounter]];
        }
    } else {
        // Eye are open
        self.blinkState = -1;
    }
}

-(void)moveHeadLeftDetection:(CIFaceFeature *)face image:(CIImage *) image {
    NSLog(@"Face hasLeftEyePosition %d", face.hasLeftEyePosition);
    NSLog(@"Face hasRightEyePosition %d", face.hasRightEyePosition);
    NSLog(@"Face rightEyePosition %@", NSStringFromCGPoint(face.rightEyePosition));
    NSLog(@"Face leftEyePosition %@", NSStringFromCGPoint(face.leftEyePosition));

    if (face.hasLeftEyePosition && face.hasRightEyePosition) {
        // Head Not facing left side
        if ( (( fabs(face.rightEyePosition.x - face.rightEyePosition.y) > 80.0)
           && ( fabs(face.leftEyePosition.x - face.leftEyePosition.y) > 150.0)) ) {
            NSLog(@"Head Not Facing Left Side");
            self.faceDirection = 1;
            [self livenessFailedAction];
        }
        else if ( (( fabs(face.rightEyePosition.x - face.rightEyePosition.y) < 80.0)
            && ( fabs(face.leftEyePosition.x - face.leftEyePosition.y) < 25.0))
                 && (abs((int) image.extent.origin.y - (int) face.mouthPosition.x) > 270) ) {
            // Head facing left side
            NSLog(@"Head Facing Left Side");
            if(self.faceDirection != -1){
                [self showGreenCircleLeft:YES];
                [self livenessChallengePassed];
                self.faceDirection = -1;
            }
        } else {
            NSLog(@"Head Facing Straight On");
            if(self.faceDirection != 0){
                self.faceDirection = 0;
                [self saveImageData:image];
                [self showGreenCircleLeftUnfilled];
            }
        }
    }
}

-(void)moveHeadRightDetection:(CIFaceFeature *)face image:(CIImage *) image {
    NSLog(@"Face hasLeftEyePosition %d", face.hasLeftEyePosition);
    NSLog(@"Face hasRightEyePosition %d", face.hasRightEyePosition);
    NSLog(@"Face rightEyePosition %@", NSStringFromCGPoint(face.rightEyePosition));
    NSLog(@"Face leftEyePosition %@", NSStringFromCGPoint(face.leftEyePosition));

    if (face.hasLeftEyePosition && face.hasRightEyePosition) {
        // Head Not facing right side
       if ( (( fabs(face.rightEyePosition.x - face.rightEyePosition.y) < 80.0)
          && ( fabs(face.leftEyePosition.x - face.leftEyePosition.y) < 25.0)) ) {
            NSLog(@"Head Not Facing Right Side");
            self.faceDirection = 1;
            [self livenessFailedAction];
        }
        else if ( (( fabs(face.rightEyePosition.x - face.rightEyePosition.y) > 80.0)
                && ( fabs(face.leftEyePosition.x - face.leftEyePosition.y) > 150.0))
                && ( abs((int) image.extent.origin.y - (int) face.mouthPosition.x) < 370) ) {
            // Head facing right side
            NSLog(@"Head Facing Right Side");
            if(self.faceDirection != -1){
                self.faceDirection = -1;
                [self showGreenCircleRight:YES];
                [self livenessChallengePassed];
            }
        } else {
            NSLog(@"Head Facing Straight On");
            if(self.faceDirection != 0){
                self.faceDirection = 0;
                [self saveImageData:image];
                [self showGreenCircleRightUnfilled];
            }
        }
    }
}

-(void)processFrame:(CMSampleBufferRef)sampleBuffer{
    if(!self.livenessChallengeIsHappening || !self.continueRunning){
        return;
    }
    // Convert to CIPixelBuffer for faceDetector
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (pixelBuffer == NULL) { return; }

    // Create CIImage for faceDetector
    CIImage *image = [CIImage imageWithCVImageBuffer:pixelBuffer];
    // Used for Portrait
    int exifOrientation = 0;

    // Establish the image orientation CI Detectors
    NSDictionary *options = @{CIDetectorSmile: @(YES), CIDetectorEyeBlink: @(YES), CIDetectorImageOrientation: [NSNumber numberWithInt:exifOrientation], CIDetectorNumberOfAngles: @(11), CIDetectorTracking: @(YES), CIDetectorMinFeatureSize: @(0.10),};

    // Detect features using CIFaceFeatures
    NSArray<CIFeature *> *faces = [self.faceDetector featuresInImage:image options:options];
    dispatch_sync(dispatch_get_main_queue(), ^{

        // Display detected features in overlay.
        for (CIFaceFeature *face in faces) {

            switch (self.currentChallenge) {
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

@end
