//
//  FaceEnrollmentViewController.h
//  VoiceItApi2IosSDK
//
//  Created by VoiceIt Technolopgies, LLC on 5/7/18.
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

@interface FaceEnrollmentViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>

#pragma mark -  Graphics/UI/Constraints/Animations
@property CGFloat originalMessageLeftConstraintContstant;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageleftConstraint;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet SpinningView *progressView;
@property  CGPoint cameraCenterPoint;
@property CAShapeLayer * progressCircle;
@property CALayer * cameraBorderLayer;
@property CALayer * faceRectangleLayer;

#pragma mark -  Camera Related Stuff
@property AVCaptureSession * captureSession;
@property AVCaptureDevice * videoDevice;
@property AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) NSData *finalCapturedPhotoData;
@property(nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property(nonatomic, strong) dispatch_queue_t videoDataOutputQueue;

#pragma mark -  Boolean Switches
@property BOOL lookingIntoCam;
@property BOOL enrollmentStarted;
@property BOOL isRecording;
@property BOOL continueRunning;
@property BOOL enoughRecordingTimePassed;
@property BOOL enrollmentComplete;
@property BOOL isReadyToWrite;

#pragma mark -  Counters to keep track of stuff

@property int lookingIntoCamCounter;

#pragma mark -  Developer Passed Options
@property (strong, nonatomic)  NSString * userToEnrollUserId;
@property (strong, nonatomic)  VoiceItAPITwo * myVoiceIt;
@property (strong, nonatomic)  MainNavigationController * myNavController;
@end
