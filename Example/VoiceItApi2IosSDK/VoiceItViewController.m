//
//  VoiceItViewController.m
//  VoiceItApi2IosSDK
//
//  Created by armaanbindra on 03/23/2017.
//  Copyright (c) 2017 armaanbindra. All rights reserved.
//

#import "VoiceItViewController.h"
#import "VoiceItAPITwo.h"
@interface VoiceItViewController ()
@end

@implementation VoiceItViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.API_KEY = @"API_KEY_HERE";
    self.API_TOKEN = @"API_TOKEN_HERE";
    self.TEST_USER_ID = @"USER_ID_HERE";
    
    NSMutableDictionary * styles = [[NSMutableDictionary alloc] init];
    [styles setObject:@"#FBC132" forKey:@"kThemeColor"];
    [styles setObject:@"default" forKey:@"kIconStyle"];
    _myVoiceIt  = [[VoiceItAPITwo alloc] init:self apiKey: self.API_KEY apiToken: self.API_TOKEN styles:styles];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startEnrollmentClicked:(id)sender {
    [_myVoiceIt encapsulatedVideoEnrollUser: self.TEST_USER_ID contentLanguage:@"en-US" voicePrintPhrase:@"my face and voice identify me" userEnrollmentsCancelled:^{
        NSLog(@"User Enrollments Cancelled");
    } userEnrollmentsPassed:^{
        NSLog(@"User Enrollments Completed");
    }];
}

- (IBAction)videoVerificationClicked:(id)sender {
    [_myVoiceIt encapsulatedVideoVerification: self.TEST_USER_ID contentLanguage:@"en-US" voicePrintPhrase:@"my face and voice identify me" doLivenessDetection:NO userVerificationCancelled:^{
         NSLog(@"User Verication Cancelled");
    } userVerificationSuccessful:^(float faceConfidence ,float voiceConfidence, NSString * jsonResponse){
        NSLog(@"User Verication Successful voiceConfidence : %g , faceConfidence : %g",voiceConfidence, faceConfidence);
    } userVerificationFailed:^(float faceConfidence ,float voiceConfidence, NSString * jsonResponse){
        NSLog(@"User Verication Failed voiceConfidence : %g , faceConfidence : %g",voiceConfidence, faceConfidence);
    }];
    }

- (IBAction)faceVerificationClicked:(id)sender {
    [_myVoiceIt encapsulatedFaceVerification: self.TEST_USER_ID doLivenessDetection:NO userVerificationCancelled:^{
        NSLog(@"User Face Verification Cancelled");
    } userVerificationSuccessful:^(float faceConfidence , NSString * jsonResponse){
        NSLog(@"User Face Verication Successful faceConfidence : %g and RESPONSE : %@", faceConfidence, jsonResponse);
    } userVerificationFailed:^(float faceConfidence , NSString * jsonResponse){
        NSLog(@"User Face Verication Failed faceConfidence : %g and RESPONSE : %@", faceConfidence, jsonResponse);
    }];
}

- (IBAction)voiceVerificationClicked:(id)sender {
    [_myVoiceIt encapsulatedVoiceVerification: self.TEST_USER_ID contentLanguage:@"en-US" voicePrintPhrase:@"my face and voice identify me" userVerificationCancelled:^{
        NSLog(@"User Verication Cancelled");
    } userVerificationSuccessful:^(float voiceConfidence, NSString * jsonResponse){
        NSLog(@"User Verication Successful voiceConfidence : %g ",voiceConfidence);
    } userVerificationFailed:^(float voiceConfidence, NSString * jsonResponse){
        NSLog(@"User Verication Failed voiceConfidence : %g",voiceConfidence);
    }];
}


@end
