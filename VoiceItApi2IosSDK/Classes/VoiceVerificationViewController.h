//
//  VoiceVerificationViewController.h
//  VoiceItApi2IosSDK
//
//  Created by VoiceIt Technolopgies, LLC on 3/24/18.
//

#import <AVFoundation/AVFoundation.h>
#import "SpinningView.h"
#import "Utilities.h"

@interface VoiceVerificationViewController : UIViewController <AVAudioRecorderDelegate>

@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

#pragma mark - Audio Recording Stuff
@property (nonatomic, strong) AVAudioRecorder * audioRecorder;
@property (nonatomic, strong) NSString *audioPath;
@property(nonatomic, strong) AVAudioSession *audioSession;

#pragma mark -  Graphics/UI/Constraints/Animations
@property CGFloat originalMessageLeftConstraintContstant;
@property (weak, nonatomic) IBOutlet UIView *verificationBox;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet SpinningView *progressView;


#pragma mark -  Boolean Switches
@property BOOL isRecording;
@property BOOL continueRunning;

#pragma mark -  Counters to keep track of stuff
@property int failCounter;
@property int failsAllowed;


#pragma mark -  Developer Passed Options
@property (strong, nonatomic)  NSString * userToVerifyUserId;
@property (strong, nonatomic)  NSString * thePhrase;
@property (strong, nonatomic)  NSString * contentLanguage;
@property (strong, nonatomic)  NSObject * voiceItMaster;

#pragma mark - callbacks
@property (nonatomic, copy) void (^userVerificationCancelled)(void);
@property (nonatomic, copy) void (^userVerificationSuccessful)(float, NSString *);
@property (nonatomic, copy) void (^userVerificationFailed)(float, NSString *);
@end
