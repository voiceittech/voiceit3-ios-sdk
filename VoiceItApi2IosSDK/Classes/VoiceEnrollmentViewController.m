//
//  VoiceEnrollmentViewController.m
//  VoiceItApi2IosSDK
//
//  Created by VoiceIt Technolopgies, LLC on 5/7/18.
//

#import "VoiceEnrollmentViewController.h"
#import "SCSiriWaveformView.h"

@interface VoiceEnrollmentViewController()
@property (weak, nonatomic) IBOutlet SCSiriWaveformView *waveformView;
@end

@implementation VoiceEnrollmentViewController

#pragma mark - Life Cycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    self.messageLabel.textColor  = [Utilities uiColorFromHexString:@"#FFFFFF"];
    [self.navigationItem setHidesBackButton: YES];
    self.myNavController = (MainNavigationController*) [self navigationController];
    self.myVoiceIt = (VoiceItAPITwo *) self.myNavController.myVoiceIt;
    self.thePhrase =  self.myNavController.voicePrintPhrase;
    self.contentLanguage =  self.myNavController.contentLanguage;
    self.userToEnrollUserId = self.myNavController.uniqueId;

    // Setup Cancel Button on top left of navigation controller
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithTitle:[ResponseManager getMessage:@"CANCEL"] style:UIBarButtonItemStylePlain target:self action:@selector(cancelClicked)];
    leftBarButton.tintColor = [Utilities uiColorFromHexString:@"#FFFFFF"];
    [self.navigationItem setLeftBarButtonItem:leftBarButton];

    // Initialize Boolean and All
    self.enrollmentStarted = NO;
    self.continueRunning  = YES;
    self.enrollmentDoneCounter = 0;
    [self setNavigationTitle:self.enrollmentDoneCounter + 1];
    [self.messageLabel setText:@""];
    [self setupWaveform];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.originalMessageLeftConstraintContstant = self.messageleftConstraint.constant;
    self.enrollmentStarted = YES;
    [self startEnrollmentProcess];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self cleanupEverything];
}

#pragma mark - Setup Methods

-(void)setupWaveform {
    CADisplayLink *displaylink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateMeters)];
    [displaylink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.waveformView setWaveColor:[Styles getMainUIColor]];
    [self.waveformView setPrimaryWaveLineWidth:4.0f];
    [self.waveformView setSecondaryWaveLineWidth:4.0f];
    [self.waveformView setFrequency:2.0f];
    [self.waveformView setIdleAmplitude:0.0f];
    [self.waveformView setBackgroundColor:[UIColor clearColor]];
}

#pragma mark - Action Methods

-(void)setNavigationTitle:(int) enrollNumber {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString * newTitle = [[NSString alloc] initWithFormat:@"%d of 3", enrollNumber];
        [[self navigationItem] setTitle: newTitle];
    });
}

-(void)startDelayedRecording:(NSTimeInterval)delayTime{
    NSLog(@"Starting Delayed RECORDING with delayTime %f ", delayTime);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayTime * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if(self.continueRunning){
            [self makeLabelFlyIn:[ResponseManager getMessage:[[NSString alloc] initWithFormat:@"ENROLL_%d", self.enrollmentDoneCounter] variable:self.thePhrase]];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.8 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                if(self.continueRunning){
                    [self startRecording];
                }
            });
        }
    });
}

-(void)startRecording {
    NSLog(@"Starting RECORDING");
    self.isRecording = YES;
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

    self.audioPath = [Utilities pathForTemporaryFileWithSuffix:@"wav"];
    NSURL *url = [NSURL fileURLWithPath:self.audioPath];

    err = nil;
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:url settings:[Utilities getRecordingSettings] error:&err];
    if(!self.audioRecorder){
        NSLog(@"recorder: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
        return;
    }
    [self.audioRecorder setDelegate:self];
    [self.audioRecorder prepareToRecord];
    [self.audioRecorder setMeteringEnabled:YES];
    [self.audioRecorder recordForDuration:4.8];
}

-(void)recordingStopped{
    self.isRecording = NO;
}

-(void)startEnrollmentProcess {
    [self.myVoiceIt deleteAllEnrollments:self.userToEnrollUserId callback:^(NSString * deleteEnrollmentsJSONResponse){
                NSLog(@"DELETING ENROLLMENTS IN THE BEGINNING %@",deleteEnrollmentsJSONResponse);
                [self startDelayedRecording:0.0];
    }];
}

-(void)makeLabelFlyAway :(void (^)(void))flewAway {
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat flyAwayTime = 0.4;
        __block CGFloat currentX = [self.messageLabel center].x;
        [UIView animateWithDuration:flyAwayTime animations:^{
            [self.messageLabel setCenter:CGPointMake(currentX - self.view.bounds.size.width, self.messageLabel.center.y)];
        } completion:^(BOOL finished){
            flewAway();
        }];
    });
}

-(void)makeLabelFlyIn:(NSString *)message {
    CGFloat flyInTime = 0.8;
    dispatch_async(dispatch_get_main_queue(), ^{
        __block CGFloat currentX = [self.messageLabel center].x;
        [[self messageLabel] setText:message];
        [self.messageLabel setCenter:CGPointMake(currentX + 2 * self.view.bounds.size.width, self.messageLabel.center.y)];
        currentX = [self.messageLabel center].x;
        [UIView animateWithDuration:flyInTime animations:^{
            [self.messageLabel setCenter:CGPointMake(currentX - self.view.bounds.size.width, self.messageLabel.center.y)];
        }];
    });
}

-(void)showLoading{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self makeLabelFlyAway:^{
            [self.progressView setHidden:NO];
        }];
    });
}

-(void)removeLoading{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView setHidden:YES];
    });
}

-(void)takeToFinishedView{
    NSLog(@"Take to finished view");
    dispatch_async(dispatch_get_main_queue(), ^{
        EnrollFinishViewController * enrollVC = [[Utilities getVoiceItStoryBoard] instantiateViewControllerWithIdentifier:@"enrollFinishedVC"];
        [[self navigationController] pushViewController:enrollVC animated: YES];
    });
}

-(void)cancelClicked{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [[self navigationController] dismissViewControllerAnimated:YES completion:^{
            [[self myNavController] userEnrollmentsCancelled];
        }];
        [self.myVoiceIt deleteAllEnrollments:self.userToEnrollUserId callback:^(NSString * deleteEnrollmentsJSONResponse){}];
    });
}

#pragma mark - AVAudioRecorderDelegate Methods

-(void)setAudioSessionInactive{
    [self.audioRecorder stop];
    NSError * err;
    [self.audioSession setActive:NO error:&err];
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    if(!self.continueRunning){
        return;
    }
    [self setAudioSessionInactive];
    [self recordingStopped];
    [self showLoading];
    [self.myVoiceIt createVoiceEnrollment:self.userToEnrollUserId contentLanguage:self.contentLanguage audioPath:self.audioPath phrase: self.thePhrase callback:^(NSString * jsonResponse){
        [Utilities deleteFile:self.audioPath];
        [self removeLoading];
        NSLog(@"Voice Enrollment JSON Response : %@", jsonResponse);
        NSDictionary *jsonObj = [Utilities getJSONObject:jsonResponse];
        NSLog(@"Response Code is %@ and message is : %@", [jsonObj objectForKey:@"responseCode"], [jsonObj objectForKey:@"message"]);
        NSString * responseCode = [jsonObj objectForKey:@"responseCode"];
        if([responseCode isEqualToString:@"SUCC"]){
            self.enrollmentDoneCounter += 1;
            if( self.enrollmentDoneCounter < 3){
                [self setNavigationTitle:self.enrollmentDoneCounter + 1];
                [self startDelayedRecording:1];
            } else {
                [self takeToFinishedView];
            }
        } else {
            if([Utilities isBadResponseCode:responseCode]){
                [self makeLabelFlyIn:[ResponseManager getMessage: @"CONTACT_DEVELOPER" variable: responseCode]];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [[self navigationController] dismissViewControllerAnimated:YES completion:^{
                        [[self myNavController] userEnrollmentsCancelled];
                    }];
                });
            }
            else if([responseCode isEqualToString:@"STTF"] || [responseCode isEqualToString:@"PDNM"]){
                [self startDelayedRecording:3.0];
                [self makeLabelFlyIn:[ResponseManager getMessage: responseCode variable:self.thePhrase]];
            } else {
                [self startDelayedRecording:3.0];
                [self makeLabelFlyIn:[ResponseManager getMessage:responseCode]];
            }
        }
    }];
}

-(void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    NSLog(@"fail because %@", error.localizedDescription);
}

- (void)updateMeters
{
    [self.audioRecorder updateMeters];
    [self.waveformView updateWithLevel:[Utilities normalizedPowerLevelFromDecibels: self.audioRecorder]];
}

#pragma mark - Cleanup Methods

-(void)cleanupEverything {
    [self setAudioSessionInactive];
    self.continueRunning = NO;
}
@end
