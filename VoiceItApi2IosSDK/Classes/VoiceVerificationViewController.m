//
//  VoiceVerificationViewController.m
//  VoiceItApi2IosSDK
//
//  Created by Armaan Bindra on 3/24/18.
//

#import "VoiceVerificationViewController.h"
#import "Styles.h"
#import "VoiceItAPITwo.h"
#import "ResponseManager.h"
#import "SCSiriWaveformView.h"

@interface VoiceVerificationViewController ()
@property (weak, nonatomic) IBOutlet SCSiriWaveformView *waveformView;
@property(nonatomic, strong) VoiceItAPITwo * myVoiceIt;
@end

@implementation VoiceVerificationViewController

-(void)startVerificationProcess {
    [self startDelayedRecording:1.5];
}

-(void)startDelayedRecording:(NSTimeInterval)delayTime{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayTime * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if(self.continueRunning){
            [self setMessage:[ResponseManager getMessage:@"VERIFY" variable:self.thePhrase]];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                if(self.continueRunning){
                    [self startRecording];
                }
            });
        }
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.okResponseCodes = [[NSMutableArray alloc] initWithObjects:@"FNFD",  nil];
    self.myVoiceIt = (VoiceItAPITwo *) [self voiceItMaster];
    // Initialize Boolean and All
    self.continueRunning = YES;
    self.failCounter = 0;
    
    // Do any additional setup after loading the view.
    [self.progressView setHidden:YES];
    [self setMessage:[ResponseManager getMessage:@"READY_FOR_VOICE_VERIFICATION"]];
    
    [self setupScreen];
    
    CADisplayLink *displaylink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateMeters)];
    [displaylink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.waveformView setWaveColor:[Styles getMainUIColor]];
    [self.waveformView setPrimaryWaveLineWidth:4.0f];
    [self.waveformView setSecondaryWaveLineWidth:4.0f];
    [self.waveformView setBackgroundColor:[UIColor clearColor]];
}


-(void)setupScreen {
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
    [[self.verificationBox layer] setCornerRadius:10.0];
    [self setBottomCornersForCancelButton];
}

- (IBAction)cancelClicked:(id)sender {
    self.continueRunning = NO;
    [self setAudioSessionInactive];
    [self dismissViewControllerAnimated:YES completion:^{
        [self userVerificationCancelled]();
    }];
}

-(void)setMessage:(NSString *) newMessage {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.messageLabel setText: newMessage];
        [self.messageLabel setAdjustsFontSizeToFitWidth:YES];
    });
}

-(void)setBottomCornersForCancelButton{
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect: self.cancelButton.bounds byRoundingCorners:( UIRectCornerBottomLeft | UIRectCornerBottomRight) cornerRadii:CGSizeMake(10.0, 10.0)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.cancelButton.bounds;
    maskLayer.path  = maskPath.CGPath;
    self.cancelButton.layer.mask = maskLayer;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.progressView startAnimation];
    [self startVerificationProcess];
}

- (void)viewDidDisappear:(BOOL)animated {
    self.continueRunning = NO;
    [self setAudioSessionInactive];
    [super viewDidDisappear:animated];
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
    
    // Unique recording URL
    NSString *fileName = @"OriginalFile"; // Changed it So It Keeps Replacing File
    self.audioPath = [NSTemporaryDirectory()
                  stringByAppendingPathComponent:[NSString
                                                  stringWithFormat:@"%@.wav", fileName]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.audioPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:self.audioPath
                                                   error:nil];
    }
    
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

-(void)viewWillDisappear:(BOOL)animated{
    [self setAudioSessionInactive];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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


-(void)setAudioSessionInactive{
    [self.audioRecorder stop];
    NSError * err;
    [self.audioSession setActive:NO error:&err];
}

#pragma mark - AVAudioRecorderDelegate Methods

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    NSLog(@"AUDIO RECORDED FINISHED SUCCESS = %d", flag);
    [self setAudioSessionInactive];
    [self stopRecording];
    [self showLoading];
    [self.myVoiceIt voiceVerification:_userToVerifyUserId contentLanguage: self.contentLanguage audioPath:self.audioPath callback:^(NSString * jsonResponse){
        [self removeLoading];
        NSLog(@"Video Verification JSON Response : %@", jsonResponse);
        NSDictionary *jsonObj = [Utilities getJSONObject:jsonResponse];
        NSLog(@"Response Code is %@ and message is : %@", [jsonObj objectForKey:@"responseCode"], [jsonObj objectForKey:@"message"]);
        NSString * responseCode = [jsonObj objectForKey:@"responseCode"];
        
        if([responseCode isEqualToString:@"SUCC"]){
            [self setMessage:[ResponseManager getMessage:@"SUCCESS"]];
            float voiceConfidence = [[jsonObj objectForKey:@"confidence"] floatValue];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self dismissViewControllerAnimated: YES completion:^{
                    [self userVerificationSuccessful](voiceConfidence, jsonResponse);
                }];
            });
        } else {
            if(![self.okResponseCodes containsObject:responseCode]){
                self.failCounter += 1;
            }
            
            if(self.failCounter < 3){
                if([responseCode isEqualToString:@"STTF"]){
                    [self setMessage:[ResponseManager getMessage: responseCode variable:self.thePhrase]];
                    [self startDelayedRecording:3.0];
                }
                else if ([responseCode isEqualToString:@"TVER"]){
                    [self setMessage:[ResponseManager getMessage: responseCode]];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        [self dismissViewControllerAnimated: YES completion:^{
                            [self userVerificationFailed](0.0, jsonResponse);
                        }];
                    });
                }else{
                    [self setMessage:[ResponseManager getMessage: responseCode]];
                    [self startDelayedRecording:3.0];
                }
            } else {
                [self setMessage:[ResponseManager getMessage: @"TOO_MANY_ATTEMPTS"]];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    float voiceConfidence = [[jsonObj objectForKey:@"confidence"] floatValue];
                    [self dismissViewControllerAnimated: YES completion:^{
                        [self userVerificationFailed](voiceConfidence, jsonResponse);
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
    CGFloat normalizedValue;
    [self.audioRecorder updateMeters];
    normalizedValue = [self _normalizedPowerLevelFromDecibels:[self.audioRecorder averagePowerForChannel:0]];
    [self.waveformView updateWithLevel:normalizedValue];
}


- (CGFloat)_normalizedPowerLevelFromDecibels:(CGFloat)decibels
{
    if (decibels < -60.0f || decibels == 0.0f) {
        return 0.0f;
    }
    
    return powf((powf(10.0f, 0.05f * decibels) - powf(10.0f, 0.05f * -60.0f)) * (1.0f / (1.0f - powf(10.0f, 0.05f * -60.0f))), 1.0f / 2.0f);
}

@end
