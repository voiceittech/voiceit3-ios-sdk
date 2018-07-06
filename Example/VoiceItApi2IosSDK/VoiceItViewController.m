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
    self.TEST_PHRASE = @"never forget tomorrow is a new day";
    self.TEST_CONTENT_LANGUAGE = @"en-US";
    
    NSMutableDictionary * styles = [[NSMutableDictionary alloc] init];
    [styles setObject:@"#FBC132" forKey:@"kThemeColor"];
    [styles setObject:@"default" forKey:@"kIconStyle"];
    self.myVoiceIt  = [[VoiceItAPITwo alloc] init:self apiKey: self.API_KEY apiToken: self.API_TOKEN styles:styles];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)voiceEnrollmentClicked:(id)sender {
    [self.myVoiceIt encapsulatedVoiceEnrollUser: self.TEST_USER_ID contentLanguage:self.TEST_CONTENT_LANGUAGE voicePrintPhrase:self.TEST_PHRASE userEnrollmentsCancelled:^{
        NSLog(@"User Enrollments Cancelled");
    } userEnrollmentsPassed:^{
        NSLog(@"User Enrollments Completed");
    }];
}

- (IBAction)faceEnrollmentClicked:(id)sender {
    [self.myVoiceIt encapsulatedFaceEnrollUser: self.TEST_USER_ID userEnrollmentsCancelled:^{
        NSLog(@"User Enrollments Cancelled");
    } userEnrollmentsPassed:^{
        NSLog(@"User Enrollments Completed");
    }];
}

- (IBAction)videoEnrollmentClicked:(id)sender {
    [self.myVoiceIt encapsulatedVideoEnrollUser: self.TEST_USER_ID contentLanguage:self.TEST_CONTENT_LANGUAGE voicePrintPhrase:self.TEST_PHRASE userEnrollmentsCancelled:^{
        NSLog(@"User Enrollments Cancelled");
    } userEnrollmentsPassed:^{
        NSLog(@"User Enrollments Completed");
    }];
}

- (IBAction)voiceVerificationClicked:(id)sender {
    [self.myVoiceIt encapsulatedVoiceVerification: self.TEST_USER_ID contentLanguage:self.TEST_CONTENT_LANGUAGE voicePrintPhrase:self.TEST_PHRASE userVerificationCancelled:^{
        NSLog(@"User Verication Cancelled");
    } userVerificationSuccessful:^(float voiceConfidence, NSString * jsonResponse){
        NSLog(@"User Verication Successful voiceConfidence : %g ",voiceConfidence);
    } userVerificationFailed:^(float voiceConfidence, NSString * jsonResponse){
        NSLog(@"User Verication Failed voiceConfidence : %g",voiceConfidence);
    }];
}

- (IBAction)faceVerificationClicked:(id)sender {
    [self.myVoiceIt encapsulatedFaceVerification:self.TEST_USER_ID doLivenessDetection:self.livenessToggle.isOn livenessChallengeFailsAllowed:2 userVerificationCancelled:^{
        NSLog(@"User Face Verification Cancelled");
    } userVerificationSuccessful:^(float faceConfidence , NSString * jsonResponse){
        NSLog(@"User Face Verication Failed faceConfidence : %g and RESPONSE : %@", faceConfidence, jsonResponse);
    } userVerificationFailed:^(float faceConfidence , NSString * jsonResponse){
        NSLog(@"User Face Verication Failed faceConfidence : %g and RESPONSE : %@", faceConfidence, jsonResponse);
    }];
}

- (IBAction)videoVerificationClicked:(id)sender {
    [self.myVoiceIt encapsulatedVideoVerification: self.TEST_USER_ID contentLanguage:self.TEST_CONTENT_LANGUAGE voicePrintPhrase:self.TEST_PHRASE doLivenessDetection:self.livenessToggle.isOn
                        userVerificationCancelled:^{
         NSLog(@"User Verication Cancelled");
    } userVerificationSuccessful:^(float faceConfidence ,float voiceConfidence, NSString * jsonResponse){
        NSLog(@"User Verication Successful voiceConfidence : %g , faceConfidence : %g",voiceConfidence, faceConfidence);
    } userVerificationFailed:^(float faceConfidence ,float voiceConfidence, NSString * jsonResponse){
        NSLog(@"User Verication Failed voiceConfidence : %g , faceConfidence : %g",voiceConfidence, faceConfidence);
    }];
}

@end
