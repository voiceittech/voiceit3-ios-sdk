//
//  VoiceIdentificationViewController.m
//  VoiceItApi2IosSDK
//
//  Created by VoiceIt Technolopgies, LLC on 8/28/18.
//

#import "VoiceIdentificationViewController.h"
#import "Styles.h"
#import "VoiceItAPITwo.h"
#import "ResponseManager.h"
#import "SCSiriWaveformView.h"
#import "Utilities.h"

@interface VoiceIdentificationViewController ()
@property (weak, nonatomic) IBOutlet SCSiriWaveformView *waveformView;
@property(nonatomic, strong) VoiceItAPITwo * myVoiceIt;
@end

@implementation VoiceIdentificationViewController

#pragma mark - Life Cycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    self.myVoiceIt = (VoiceItAPITwo *) [self voiceItMaster];
    // Initialize Booleans and counters
    self.continueRunning = YES;
    self.failCounter = 0;
    
    // Do any additional setup after loading the view.
    [self.progressView setHidden:YES];
    [self setMessage:[ResponseManager getMessage:@"READY_FOR_VOICE_IDENTIFICATION"]];
    [self setupScreen];
    [self setupWaveform];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.progressView startAnimation];
    [self startIdentificationProcess];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self cleanupEverything];
}

#pragma mark - Setup Methods

-(void)setupScreen {
    [self.cancelButton setTitle:[ResponseManager getMessage:@"CANCEL"] forState:UIControlStateNormal];
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
    [[self.identificationBox layer] setCornerRadius:10.0];
    [Utilities setBottomCornersForCancelButton:self.cancelButton];
}

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

-(void)startIdentificationProcess {
    [self startDelayedRecording:1.5];
}

-(void)startDelayedRecording:(NSTimeInterval)delayTime{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayTime * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if(self.continueRunning){
            [self setMessage:[ResponseManager getMessage:@"IDENTIFY" variable:self.thePhrase]];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
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

-(void)stopRecording{
    self.isRecording = NO;
}

-(void)setMessage:(NSString *) newMessage {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.messageLabel setText: newMessage];
        [self.messageLabel setAdjustsFontSizeToFitWidth:YES];
    });
}

-(void)showLoading{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView setHidden:NO];
        [self setMessage:@""];
    });
}

-(void)removeLoading{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView setHidden:YES];
    });
}

- (IBAction)cancelClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [self userIdentificationCancelled]();
    }];
}

#pragma mark - Audio Recording Methods

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    NSLog(@"AUDIO RECORDED FINISHED SUCCESS = %d", flag);
    if(!self.continueRunning){
        return;
    }
    [self setAudioSessionInactive];
    [self stopRecording];
    [self showLoading];
    [self.myVoiceIt voiceIdentification:_groupToIdentifyGroupId contentLanguage: self.contentLanguage audioPath:self.audioPath phrase: self.thePhrase callback:^(NSString * jsonResponse){
        [Utilities deleteFile:self.audioPath];
        [self removeLoading];
        NSLog(@"Voice Identification JSON Response : %@", jsonResponse);
        NSDictionary *jsonObj = [Utilities getJSONObject:jsonResponse];
        NSLog(@"Response Code is %@ and message is : %@", [jsonObj objectForKey:@"responseCode"], [jsonObj objectForKey:@"message"]);
        NSString * responseCode = [jsonObj objectForKey:@"responseCode"];
        
        if([responseCode isEqualToString:@"SUCC"]){
            
            [self setMessage:[ResponseManager getMessage:@"SUCCESS_IDENTIFIED"]];
            float voiceConfidence = [[jsonObj objectForKey:@"confidence"] floatValue];
            NSString * foundUserId = [jsonObj objectForKey:@"userId"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self dismissViewControllerAnimated: YES completion:^{
                    [self userIdentificationSuccessful](voiceConfidence, foundUserId, jsonResponse);
                }];
            });
        } else {
            self.failCounter += 1;
            if([Utilities isBadResponseCode:responseCode]){
                [self setMessage:[ResponseManager getMessage: @"CONTACT_DEVELOPER" variable: responseCode]];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [self dismissViewControllerAnimated: YES completion:^{
                        [self userIdentificationFailed](0.0, jsonResponse);
                    }];
                });
            }
            else if(self.failCounter < self.failsAllowed){
                if([responseCode isEqualToString:@"STTF"] || [responseCode isEqualToString:@"PDNM"]){
                    [self setMessage:[ResponseManager getMessage: responseCode variable:self.thePhrase]];
                    [self startDelayedRecording:3.0];
                }
                
                else if ([responseCode isEqualToString:@"PNTE"]){
                    [self setMessage:[ResponseManager getMessage: @"PNTE_IDENTIFICATION"]];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        [self dismissViewControllerAnimated: YES completion:^{
                            [self userIdentificationFailed](0.0, jsonResponse);
                        }];
                    });
                } else{
                    [self setMessage:[ResponseManager getMessage: responseCode]];
                    [self startDelayedRecording:3.0];
                }
            } else {
                [self setMessage:[ResponseManager getMessage: @"TOO_MANY_ATTEMPTS"]];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    float voiceConfidence = [responseCode isEqualToString:@"FAIL"] ? [[jsonObj objectForKey:@"confidence"] floatValue] : 0.0;
                    [self dismissViewControllerAnimated: YES completion:^{
                        [self userIdentificationFailed](voiceConfidence, jsonResponse);
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

- (void)updateMeters
{
    [self.audioRecorder updateMeters];
    [self.waveformView updateWithLevel:[Utilities normalizedPowerLevelFromDecibels: self.audioRecorder]];
}

-(void)setAudioSessionInactive{
    [self.audioRecorder stop];
    NSError * err;
    [self.audioSession setActive:NO error:&err];
}

#pragma mark - Cleanup Methods

-(void)cleanupEverything {
    [self setAudioSessionInactive];
    self.continueRunning = NO;
}
@end
