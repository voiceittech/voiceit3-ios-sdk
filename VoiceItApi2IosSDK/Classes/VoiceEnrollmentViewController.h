//
//  VoiceEnrollmentViewController.h
//  VoiceItApi2IosSDK
//
//  Created by VoiceIt Technolopgies, LLC on 10/1/17.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "Utilities.h"
#import "VoiceItAPITwo.h"
#import "ResponseManager.h"
#import "SpinningView.h"
#import "EnrollFinishViewController.h"
#import "MainNavigationController.h"
#import "Styles.h"

@interface VoiceEnrollmentViewController : UIViewController <AVAudioRecorderDelegate>

#pragma mark - Audio Recording Stuff
@property (nonatomic, strong) AVAudioRecorder * audioRecorder;
@property (nonatomic, strong) NSString *audioPath;
@property(nonatomic, strong) AVAudioSession *audioSession;
#pragma mark -  Graphics/UI/Constraints/Animations
@property CGFloat originalMessageLeftConstraintContstant;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageleftConstraint;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet SpinningView *progressView;

#pragma mark -  Boolean Switches
@property BOOL enrollmentStarted;
@property BOOL isRecording;
@property BOOL continueRunning;

#pragma mark -  Counters to keep track of stuff
@property int enrollmentDoneCounter;
@property int lookingIntoCamCounter;

#pragma mark -  Developer Passed Options
@property (strong, nonatomic)  NSString * userToEnrollUserId;
@property (strong, nonatomic)  NSString * thePhrase;
@property (strong, nonatomic)  NSString * contentLanguage;
@property (strong, nonatomic)  VoiceItAPITwo * myVoiceIt;
@property (strong, nonatomic)  MainNavigationController * myNavController;
@end
