//
//  Liveness.h
//  VoiceItApi2IosSDK
//
//  Created by Armaan Bindra on 4/21/18.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@import GoogleMobileVision;

@interface Liveness : NSObject

- (id)init:(UIViewController *)mVC cCP:(CGPoint) cCP bgWH:(CGFloat) bgWH cW:(CGFloat) cW rL:(CALayer *)rL mL:(UILabel *)mL doAudio:(BOOL)doAudio lFA:(int)lFA livenessPassed:(void (^)(NSData *))livenessPassed livenessFailed:(void (^)(void))livenessFailed ;
-(void)processFrame:(CMSampleBufferRef)sampleBuffer;
-(void)doLivenessDetection;
-(void)setupLivenessCircles;
-(void)resetVariables;

@property NSTimer * timer;
@property int currentChallenge;
@property NSMutableArray * challengeArray;
@property (nonatomic, strong) UIViewController * masterViewController;
@property(nonatomic, strong) GMVDetector *faceDetector;
@property UILabel *messageLabel;
@property (nonatomic, strong) NSData *finalCapturedPhotoData;
@property (nonatomic,strong) AVAudioPlayer *player;

#pragma mark -  Boolean Switches
@property BOOL isRecording;
@property BOOL enoughRecordingTimePassed;
@property BOOL continueRunning;
@property BOOL livenessChallengeIsHappening;
@property BOOL audioPromptsIsHappening;

#pragma mark -  Counters to keep track of stuff
@property int numberOfLivenessFailsAllowed;
@property int currentChallengeIndex;
@property int successfulChallengesCounter;
@property int lookingIntoCamCounter;
@property int smileCounter;
@property int failCounter;
@property int blinkCounter;
@property BOOL smileFound;
@property int faceDirection;
@property int blinkState;

#pragma mark - Left Right Circle Related Code
@property CALayer * rootLayer;
@property CGPoint cameraCenterPoint;
@property CGFloat backgroundWidthHeight;
@property CGFloat circleWidth;
@property CAShapeLayer * leftCircle;
@property CAShapeLayer * rightCircle;
#pragma mark - callbacks
@property (nonatomic, copy) void (^livenessFailed)(void);
@property (nonatomic, copy) void (^livenessSuccess)(NSData *);
@end
