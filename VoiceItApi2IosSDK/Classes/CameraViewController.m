//
//  CameraViewController.m
//  VoiceItAPITwoDemoApp
//
//  Created by Armaan Bindra on 3/16/17.
//  Copyright © 2017 Armaan Bindra. All rights reserved.
//

#import "CameraViewController.h"
#import "ViewUtils.h"

@interface CameraViewController ()
@property (strong, nonatomic) SimpleCamera *camera;
@property (strong, nonatomic) UILabel *errorLabel;
@property (strong, nonatomic) NSTimer *countdownTimer;
@property (strong, nonatomic) UILabel *timerLabel;
@property int timeCounter;

@end

@implementation CameraViewController

- (id)init:(void (^)(NSString *))callback {
    _videoRecordingCompleted = callback;
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    _timeCounter = 5;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    _timerLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2.0, self.view.frame.size.height / 2.0, 0.0, 0.0)];
    _timerLabel.text = @"5";
    _timerLabel.textColor = [UIColor whiteColor];
    _timerLabel.font = [UIFont fontWithName:@"Futura" size:120.0];
    _timerLabel.alpha = 0.4;
    [_timerLabel sizeToFit];
    _timerLabel.frame = CGRectMake(self.view.frame.size.width / 2.0 - _timerLabel.frame.size.width/2.0, self.view.frame.size.height / 2.0 -  _timerLabel.frame.size.width/2.0, _timerLabel.frame.size.width, _timerLabel.frame.size.height);

    self.camera = [[SimpleCamera alloc] initWithQuality:AVCaptureSessionPresetHigh
                                                 position:LLCameraPositionFront
                                             videoEnabled:YES];
    
    // attach to a view controller
    [self.camera attachToViewController:self withFrame:CGRectMake(0, 0, screenRect.size.width, screenRect.size.height)];
    [self.view addSubview:_timerLabel];
    
    // read: http://stackoverflow.com/questions/5427656/ios-uiimagepickercontroller-result-image-orientation-after-upload
    // you probably will want to set this to YES, if you are going view the image outside iOS.
    self.camera.fixOrientationAfterCapture = NO;
    
    // take the required actions on a device change
    __weak typeof(self) weakSelf = self;
    [self.camera setOnDeviceChange:^(SimpleCamera *camera, AVCaptureDevice * device) {
        
        NSLog(@"Device changed.");
    }];
    
    [self.camera setOnError:^(SimpleCamera *camera, NSError *error) {
        NSLog(@"Camera error: %@", error);
        
        if([error.domain isEqualToString:SimpleCameraErrorDomain]) {
            if(error.code == SimpleCameraErrorCodeCameraPermission ||
               error.code == SimpleCameraErrorCodeMicrophonePermission) {
                
                if(weakSelf.errorLabel) {
                    [weakSelf.errorLabel removeFromSuperview];
                }
                
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
                label.text = @"We need permission for the camera.\nPlease go to your settings.";
                label.numberOfLines = 2;
                label.lineBreakMode = NSLineBreakByWordWrapping;
                label.backgroundColor = [UIColor clearColor];
                label.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:13.0f];
                label.textColor = [UIColor whiteColor];
                label.textAlignment = NSTextAlignmentCenter;
                [label sizeToFit];
                label.center = CGPointMake(screenRect.size.width / 2.0f, screenRect.size.height / 2.0f);
                weakSelf.errorLabel = label;
                [weakSelf.view addSubview:weakSelf.errorLabel];
            }
        }
    }];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.camera start];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self startRecording];
    });
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


-(void)startRecording{
    
    _countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(decreaseTimer)
                                   userInfo:nil
                                    repeats:YES];
    // start recording
    NSURL *outputURL = [[[self applicationDocumentsDirectory]
                         URLByAppendingPathComponent:@"test1"] URLByAppendingPathExtension:@"mov"];
    [self.camera startRecordingWithOutputUrl:outputURL didRecord:^(SimpleCamera *camera, NSURL *outputFileUrl, NSError *error) {
        NSLog(@"Video Finished Recording and the path is %@", outputURL.path);
        self.videoRecordingCompleted(outputURL.path);
        [self dismissViewControllerAnimated:true completion:nil];
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self.camera stopRecording];
        [self.camera stop];
    });
}

-(void)decreaseTimer{
    _timeCounter--;

    dispatch_async(dispatch_get_main_queue(), ^{
        if( _timeCounter < 0){
            [_countdownTimer invalidate];
            _countdownTimer = nil;
            _timerLabel.hidden = YES;
        } else{
            _timerLabel.text = [[NSString alloc] initWithFormat:@"%d",_timeCounter];
        }
    });
    
}
/* other lifecycle methods */

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    self.camera.view.frame = self.view.contentBounds;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
