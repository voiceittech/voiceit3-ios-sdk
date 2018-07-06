//
//  Liveness.m
//  VoiceItApi2IosSDK
//
//  Created by Armaan Bindra on 4/21/18.
//

#import "Liveness.h"
#import "NSMutableArray+Shuffle.h"
#import "Utilities.h"
#import "ResponseManager.h"

@implementation Liveness

- (id)init:(UIViewController *)mVC cCP:(CGPoint) cCP bgWH:(CGFloat) bgWH cW:(CGFloat) cW rL:(CALayer *)rL mL:(UILabel *)mL lFA:(int)lFA livenessPassed:(void (^)(NSData *))livenessPassed livenessFailed:(void (^)(void))livenessFailed{
    self.masterViewController = mVC;
    self.cameraCenterPoint = cCP;
    self.backgroundWidthHeight = bgWH;
    self.circleWidth = cW;
    self.rootLayer = rL;
    self.messageLabel = mL;
    self.livenessSuccess = livenessPassed;
    self.livenessFailed = livenessFailed;
    self.numberOfLivenessFailsAllowed = lFA;
    
    [self resetVariables];
    // Initialize the face detector.
    NSDictionary *options = @{
                              GMVDetectorFaceMinSize : @(0.5),
                              GMVDetectorFaceTrackingEnabled : @(NO),
                              GMVDetectorFaceClassificationType : @(GMVDetectorFaceClassificationAll),
                              GMVDetectorFaceLandmarkType : @(GMVDetectorFaceLandmarkAll),
                              GMVDetectorFaceMode : @(GMVDetectorFaceAccurateMode)
                              };
    self.faceDetector = [GMVDetector detectorOfType:GMVDetectorTypeFace options:options];
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
    // Setup challenge array
    [self setupChallengeArray];
    [self setupLivenessCircles];
    NSLog(@"ALL LIVENESS VARIABLES ARE RESET");
}

-(void)saveImageData:(UIImage *)image{
    if ( image != nil){
        self.finalCapturedPhotoData  = UIImageJPEGRepresentation(image, 0.8);
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
    self.timer = [NSTimer scheduledTimerWithTimeInterval: seconds
                                                  target:self
                                                selector:@selector(timerDone)
                                                userInfo:nil
                                                 repeats:NO];
}

-(void)stopTimer{
    [self.timer invalidate];
}

-(void)livenessFailedAction{
    [self stopTimer];
    self.failCounter++;
    if(self.failCounter < self.numberOfLivenessFailsAllowed){
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
    
    self.rightCircle.path = [UIBezierPath bezierPathWithArcCenter: self.cameraCenterPoint radius:(self.backgroundWidthHeight / 2) startAngle: 1.75 * M_PI endAngle: 0.25 * M_PI clockwise:YES].CGPath;
    self.rightCircle.fillColor =  [UIColor clearColor].CGColor;
    self.rightCircle.strokeColor = [UIColor clearColor].CGColor;
    self.rightCircle.lineWidth = self.circleWidth + 8.0;
    [self.rootLayer addSublayer:self.leftCircle];
    [self.rootLayer addSublayer:self.rightCircle];
}

-(void)showGreenCircleLeftUnfilled{
    self.leftCircle.strokeColor =  [Utilities getGreenColor].CGColor;
    self.leftCircle.opacity = 0.3;
}

-(void)showGreenCircleRightUnfilled{
    self.rightCircle.strokeColor =  [Utilities getGreenColor].CGColor;
    self.rightCircle.opacity = 0.3;
}

-(void)showGreenCircleLeft:(BOOL) showCircle{
    self.leftCircle.opacity = 1.0;
    if(showCircle){
        self.leftCircle.strokeColor = [Utilities getGreenColor].CGColor;
    } else {
        self.leftCircle.strokeColor = [UIColor clearColor].CGColor;
    }
}

-(void)showGreenCircleRight:(BOOL) showCircle{
    self.rightCircle.opacity = 1.0;
    if(showCircle){
        self.rightCircle.strokeColor = [Utilities getGreenColor].CGColor;
    } else {
        self.rightCircle.strokeColor = [UIColor clearColor].CGColor;
    }
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
}

-(void)doLivenessDetection {
    if(!self.continueRunning){
        return;
    }
    
    NSLog(@"successfulChallengesCounter : %d", self.successfulChallengesCounter);
    if(self.successfulChallengesCounter >= 2){
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
            [self startTimer:2.5];
            break;
        case 1:
            //Blink
            [self setMessage:[ResponseManager getMessage:@"BLINK"]];
            [self startTimer:3.0];
            break;
        case 2:
            //Move head left
            [self setMessage:[ResponseManager getMessage:@"FACE_LEFT"]];
            [self startTimer:2.5];
            [self showGreenCircleLeftUnfilled];
            break;
        case 3:
            //Move head right
            [self setMessage:[ResponseManager getMessage:@"FACE_RIGHT"]];
            [self startTimer:2.5];
            [self showGreenCircleRightUnfilled];
            break;
        default:
            break;
    }
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

-(void)doSmileDetection:(GMVFaceFeature *)face image:(UIImage *) image {
    if(face.hasSmilingProbability){
        if(face.smilingProbability > 0.85){
            self.smileCounter++;
        } else {
            self.smileCounter = -1;
        }
    }
    
    if(self.smileCounter > 5){
        if(!self.smileFound){
            self.smileFound = YES;
            [self saveImageData:image];
            [self livenessChallengePassed];
        }
    }
    
    if(self.smileCounter == -1){
        if(self.smileFound){
            self.smileFound = NO;
        }
    }
}

-(void)doBlinkDetection:(GMVFaceFeature *)face image:(UIImage *) image {
    if(face.hasLeftEyeOpenProbability && face.hasRightEyeOpenProbability){
        if(face.leftEyeOpenProbability > 0.5 && face.rightEyeOpenProbability > 0.5){
            if(self.blinkState == -1) { self.blinkState = 0; }
            if(self.blinkState == 1) {
                self.blinkState = -1;
                self.blinkCounter++;
                if(self.blinkCounter == 3){
                    [self saveImageData:image];
                    [self livenessChallengePassed];
                } else {
                    [self.messageLabel setText: [NSString stringWithFormat:@"Blink %d", self.blinkCounter]];
                }
            }
        }
        if(face.leftEyeOpenProbability < 0.5 && face.rightEyeOpenProbability < 0.5){
            if(self.blinkState == 0) { self.blinkState = 1; }
        }
    }
    
}

-(void)moveHeadLeftDetection:(GMVFaceFeature *)face image:(UIImage *) image {
    if(face.hasHeadEulerAngleY && face.hasHeadEulerAngleZ){
        NSLog(@"Face angle y %f", face.headEulerAngleY);
        NSLog(@"Face angle z %f", face.headEulerAngleZ);
        if( (face.headEulerAngleY > 18.0)){
            self.faceDirection = 1;
            [self showGreenCircleLeftUnfilled];
            [self livenessFailedAction];
        }
        else if(face.headEulerAngleY < - 18.0){
            NSLog(@"Head Facing Left Side : %f", face.headEulerAngleY);
            if(self.faceDirection != -1){
                [self showGreenCircleLeft:YES];
                [self livenessChallengePassed];
                self.faceDirection = -1;
            }
        } else {
            NSLog(@"Head Facing Straight On : %f", face.headEulerAngleY);
            if(self.faceDirection != 0){
                self.faceDirection = 0;
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
            self.faceDirection = 1;
        }  else if(face.headEulerAngleY < - 18.0){
            NSLog(@"Head Facing Left Side : %f", face.headEulerAngleY);
            if(self.faceDirection != -1){
                self.faceDirection = -1;
                [self showGreenCircleRightUnfilled];
                [self livenessFailedAction];
            }
        } else {
            NSLog(@"Head Facing Straight On : %f", face.headEulerAngleY);
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
            
            switch (self.currentChallenge) {
                case 0:
                    // SMILE
                    [self doSmileDetection:(GMVFaceFeature *)face image:image];
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
