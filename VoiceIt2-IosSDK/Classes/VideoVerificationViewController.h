//
//  VideoVerificationViewController.h
//  VoiceIt2-IosSDK
//
//  Created by VoiceIt Technologies, LLC
//  Copyright (c) 2020 VoiceIt Technologies, LLC. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "SpinningView.h"
#import "Utilities.h"
#import "ResponseManager.h"
#import "VoiceItAPITwo.h"

@interface VideoVerificationViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,AVAudioRecorderDelegate,AVCaptureFileOutputRecordingDelegate>

@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

#pragma mark -  Graphics/UI/Constraints/Animations
@property CGFloat originalMessageLeftConstraintContstant;
@property (weak, nonatomic) IBOutlet UIView * verificationBox;
@property (weak, nonatomic) IBOutlet UILabel * messageLabel;
@property (weak, nonatomic) IBOutlet SpinningView * progressView;
@property CGPoint cameraCenterPoint;
@property CAShapeLayer * progressCircle;
@property (strong, nonatomic) CALayer * cameraBorderLayer;
@property (strong, nonatomic) CALayer * faceRectangleLayer;
@property (strong, nonatomic) CALayer * rootLayer;

#pragma mark -  Camera Related Stuff
@property AVCaptureSession * captureSession;
@property AVCaptureDevice * videoDevice;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) dispatch_queue_t videoDataOutputQueue;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer * previewLayer;
@property (nonatomic, strong) NSData * finalCapturedPhotoData;
@property (nonatomic, strong) AVAudioPlayer * player;
@property AVCaptureMovieFileOutput * movieFileOutput;

#pragma mark -  Boolean Switches
@property BOOL lookingIntoCam;
@property BOOL isRecording;
@property BOOL continueRunning;
@property BOOL doLivenessDetection;
@property BOOL doAudioPrompts;
@property BOOL verificationStarted;
@property BOOL isReadyToWrite;
@property BOOL imageIsSaved;
@property BOOL cancelPlayback;

#pragma mark -  Counters to keep track of stuff
@property int lookingIntoCamCounter;
@property int failCounter;
@property int failsAllowed;
@property int numberOfLivenessFailsAllowed;

#pragma mark -  Developer Passed Options
@property (strong, nonatomic) NSString * userToVerifyUserId;
@property (strong, nonatomic) NSObject * voiceItMaster;
@property (strong, nonatomic) NSString * contentLanguage;
@property (strong, nonatomic) NSString * thePhrase;

#pragma mark - Audio Recording Stuff
@property (nonatomic, strong) AVAudioRecorder * audioRecorder;
@property (nonatomic, strong) NSString * audioPath;
@property (nonatomic, strong) AVAudioSession * audioSession;

#pragma mark - callbacks
@property (nonatomic, copy) void (^userVerificationCancelled)(void);
@property (nonatomic, copy) void (^userVerificationSuccessful)(float, float, NSString *);
@property (nonatomic, copy) void (^userVerificationFailed)(float, float, NSString *);

@property (nonatomic, copy) void (^userVerificationSuccessfulWithLiveness)(NSString *);
@property (nonatomic, copy) void (^userVerificationFailedWithLiveness)(NSString *);
@end
