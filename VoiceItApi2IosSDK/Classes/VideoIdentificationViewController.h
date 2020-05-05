//
//  VideoIdentificationViewController.h
//  VoiceItApi2IosSDK
//
//  Created by VoiceIt Technolopgies, LLC on 08/28/18.
//

#import <AVFoundation/AVFoundation.h>
#import "SpinningView.h"
#import "Utilities.h"
#import "ResponseManager.h"
#import "VoiceItAPITwo.h"

@interface VideoIdentificationViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,AVAudioRecorderDelegate>

@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
#pragma mark - Audio Recording Stuff
@property (nonatomic, strong) AVAudioRecorder * audioRecorder;
@property (nonatomic, strong) NSString *audioPath;
@property(nonatomic, strong) AVAudioSession *audioSession;

#pragma mark -  Graphics/UI/Constraints/Animations
@property CGFloat originalMessageLeftConstraintContstant;
@property (weak, nonatomic) IBOutlet UIView *identificationBox;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet SpinningView *progressView;
@property  CGPoint cameraCenterPoint;
@property CAShapeLayer * progressCircle;
@property CALayer * cameraBorderLayer;
@property CALayer * faceRectangleLayer;
@property CALayer *rootLayer;

#pragma mark -  Camera Related Stuff
@property  AVCaptureSession * captureSession;
@property AVCaptureDevice * videoDevice;
@property(nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property(nonatomic, strong) dispatch_queue_t videoDataOutputQueue;
@property(nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) NSData *finalCapturedPhotoData;

#pragma mark -  Boolean Switches
@property BOOL lookingIntoCam;
@property BOOL isRecording;
@property BOOL continueRunning;
@property BOOL doLivenessDetection;
@property BOOL doAudioPrompts;
@property BOOL imageNotSaved;
@property BOOL identificationStarted;

#pragma mark -  Counters to keep track of stuff
@property int lookingIntoCamCounter;
@property int failCounter;
@property int failsAllowed;
@property int numberOfLivenessFailsAllowed;

#pragma mark -  Developer Passed Options
@property (strong, nonatomic)  NSString * groupToIdentifyGroupId;
@property (strong, nonatomic)  NSString * thePhrase;
@property (strong, nonatomic)  NSString * contentLanguage;
@property (strong, nonatomic)  NSObject * voiceItMaster;

#pragma mark - callbacks
@property (nonatomic, copy) void (^userIdentificationCancelled)(void);
@property (nonatomic, copy) void (^userIdentificationSuccessful)(float, float, NSString *, NSString *);
@property (nonatomic, copy) void (^userIdentificationFailed)(float, float, NSString *);
@end
