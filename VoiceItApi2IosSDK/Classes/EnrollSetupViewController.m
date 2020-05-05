//
//  EnrollSetupViewController.m
//  VoiceItApi2IosSDK
//
//  Created by VoiceIt Technolopgies, LLC on 10/2/17.
//  Copyright © 2017 VoiceIt Technologies LLC. All rights reserved.
//

#import "EnrollSetupViewController.h"

@interface EnrollSetupViewController ()
@property BOOL cameraPermissionGranted;
@property BOOL microphonePermissionGranted;
@end

@implementation EnrollSetupViewController
#pragma mark - Life Cycle Methods

- (void)viewDidLoad {
    // Do any additional setup after loading the view.
    [super viewDidLoad];
    self.myNavController = (MainNavigationController*) [self navigationController];
    
    self.continueButton.layer.cornerRadius = 10.0;
    [self.continueButton setBackgroundColor:[Styles getMainUIColor]];
    [self.continueButton setTitle:[ResponseManager getMessage:@"CONTINUE"] forState:UIControlStateNormal];
    
    switch (self.myNavController.enrollmentType) {
        case video:
            [self.enrollmentSetupTitleLabel setText:[ResponseManager getMessage:@"VOICE_FACE_SETUP"]];
            [self.enrollmentSetupSubtitleLabel setText:[ResponseManager getMessage:@"VOICE_FACE_SETUP_SUBTITLE"]];
            break;
        case face:
            [self.enrollmentSetupTitleLabel setText:[ResponseManager getMessage:@"FACE_SETUP"]];
            [self.enrollmentSetupSubtitleLabel setText:[ResponseManager getMessage:@"FACE_SETUP_SUBTITLE"]];
            break;
        case voice:
            [self.enrollmentSetupTitleLabel setText:[ResponseManager getMessage:@"VOICE_SETUP"]];
            [self.enrollmentSetupSubtitleLabel setText:[ResponseManager getMessage:@"VOICE_SETUP_SUBTITLE"]];
            break;
        default:
            break;
    }
}

#pragma mark - Action Methods

- (IBAction)continueClicked:(id)sender {
    if(self.myNavController.enrollmentType == video){
        [self checkMicrophonePermission];
        [self checkCameraPermission];
        NSLog(@"Microphone = %d, Camera = %d", self.microphonePermissionGranted, self.cameraPermissionGranted);
        if(self.cameraPermissionGranted && self.microphonePermissionGranted){
            [self launchEnrollmentProcess];
        } else {
            [self requestCameraAccess:^{
                [self requestMicAccess:^{
                    if(self.cameraPermissionGranted && self.microphonePermissionGranted){
                        [self launchEnrollmentProcess];
                    }
                }];
            }];
        }
    }
    
    if(self.myNavController.enrollmentType == face){
        [self checkCameraPermission];
        if(self.cameraPermissionGranted){
            [self launchEnrollmentProcess];
        } else {
            [self requestCameraAccess:^{
                if(self.cameraPermissionGranted){
                        [self launchEnrollmentProcess];
                    }
            }];
        }
    }
    
    if(self.myNavController.enrollmentType == voice){
        [self checkMicrophonePermission];
        if(self.microphonePermissionGranted){
            [self launchEnrollmentProcess];
        } else {
            [self requestMicAccess:^{
                if(self.microphonePermissionGranted){
                    [self launchEnrollmentProcess];
                }
            }];
        }
    }
}

-(void)launchEnrollmentProcess {
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.myNavController.enrollmentType == face){
            FaceEnrollmentViewController * enrollVC = [[Utilities getVoiceItStoryBoard] instantiateViewControllerWithIdentifier:@"faceEnrollVC"];
            [[self navigationController] pushViewController:enrollVC animated: YES];
        }
        else if(self.myNavController.enrollmentType == voice){
            VoiceEnrollmentViewController * enrollVC = [[Utilities getVoiceItStoryBoard] instantiateViewControllerWithIdentifier:@"voiceEnrollVC"];
            [[self navigationController] pushViewController:enrollVC animated: YES];
        } else if(self.myNavController.enrollmentType == video){
            VideoEnrollmentViewController * enrollVC = [[Utilities getVoiceItStoryBoard] instantiateViewControllerWithIdentifier:@"videoEnrollVC"];
            [[self navigationController] pushViewController:enrollVC animated: YES];
        }
    });
}

- (IBAction)cancelClicked:(id)sender {
    [[self navigationController] dismissViewControllerAnimated:YES completion: ^{
            [[self myNavController] userEnrollmentsCancelled]();
    }];
}

#pragma mark - Permission Methods

-(void)requestCameraAccess :(void (^)(void))completionBlock {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted){
        if(granted){
            self.cameraPermissionGranted = YES;
        } else {
            self.cameraPermissionGranted = NO;
        }
        completionBlock();
    }];
}

-(void)requestMicAccess :(void (^)(void))completionBlock {
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted){
        if(granted){
            self.microphonePermissionGranted = YES;
        } else {
            self.microphonePermissionGranted = NO;
        }
        completionBlock();
    }];
}

-(void)checkMicrophonePermission {
    switch ([[AVAudioSession sharedInstance] recordPermission]) {
        case AVAudioSessionRecordPermissionGranted:
            self.microphonePermissionGranted = YES;
            break;
        case AVAudioSessionRecordPermissionDenied:
            self.microphonePermissionGranted = NO;
            break;
        case AVAudioSessionRecordPermissionUndetermined:
            self.microphonePermissionGranted = NO;
            break;
        default:
            break;
    }
}

-(void)checkCameraPermission {
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusAuthorized:
            self.cameraPermissionGranted = YES;
            break;
        case AVAuthorizationStatusDenied:
            self.cameraPermissionGranted = NO;
            break;
        case AVAuthorizationStatusRestricted:
            self.cameraPermissionGranted = NO;
            break;
        case  AVAuthorizationStatusNotDetermined:
            self.cameraPermissionGranted = NO;
            break;
        default:
            break;
    }
}

@end

