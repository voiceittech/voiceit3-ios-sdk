//
//  VoiceItViewController.m
//  VoiceItApi2IosSDK
//
//  Created by VoiceIt Technologies, LLC on 03/23/2017.
//  Copyright (c) 2017 VoiceIt Technologies, LLC. All rights reserved.
//

#import "VoiceItViewController.h"
#import "VoiceItAPITwo.h"
@interface VoiceItViewController ()
@property (weak, nonatomic) IBOutlet UIPickerView *userPickerView;
@end

@implementation VoiceItViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.API_KEY = @"API_KEY_HERE";
    self.API_TOKEN = @"API_TOKEN_HERE";
    self.TEST_USER_ID_ONE = @"USER_ID_HERE";
    self.TEST_USER_ID_TWO = @"USER_ID_HERE";
    self.TEST_USER_ID = self.TEST_USER_ID_ONE;
    self.TEST_GROUP_ID = @"GROUP_ID_HERE";
    self.TEST_PHRASE = @"never forget tomorrow is a new day";
    self.TEST_CONTENT_LANGUAGE = @"en-US";
    
    NSMutableDictionary * styles = [[NSMutableDictionary alloc] init];
    [styles setObject:@"#FBC132" forKey:@"kThemeColor"];
    [styles setObject:@"default" forKey:@"kIconStyle"];
    self.myVoiceIt  = [[VoiceItAPITwo alloc] init:self apiKey: self.API_KEY apiToken: self.API_TOKEN styles:styles];
    self.userPickerView.delegate = self;
    self.userPickerView.dataSource = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)voiceEnrollmentClicked:(id)sender {
    [self.myVoiceIt encapsulatedVoiceEnrollUser: self.TEST_USER_ID contentLanguage:self.TEST_CONTENT_LANGUAGE voicePrintPhrase:self.TEST_PHRASE userEnrollmentsCancelled:^{
        NSLog(@"User Voice Enrollments Cancelled");
    } userEnrollmentsPassed:^{
        NSLog(@"User Voice Enrollments Completed");
    }];
}

- (IBAction)faceEnrollmentClicked:(id)sender {
    [self.myVoiceIt encapsulatedFaceEnrollUser: self.TEST_USER_ID userEnrollmentsCancelled:^{
        NSLog(@"User Face Enrollments Cancelled");
    } userEnrollmentsPassed:^{
        NSLog(@"User Face Enrollments Completed");
    }];
}

- (IBAction)videoEnrollmentClicked:(id)sender {
    [self.myVoiceIt encapsulatedVideoEnrollUser: self.TEST_USER_ID contentLanguage:self.TEST_CONTENT_LANGUAGE voicePrintPhrase:self.TEST_PHRASE userEnrollmentsCancelled:^{
        NSLog(@"User Video Enrollments Cancelled");
    } userEnrollmentsPassed:^{
        NSLog(@"User Video Enrollments Completed");
    }];
}

- (IBAction)voiceVerificationClicked:(id)sender {
    [self.myVoiceIt encapsulatedVoiceVerification:self.TEST_USER_ID
                                  contentLanguage:self.TEST_CONTENT_LANGUAGE
                                 voicePrintPhrase:self.TEST_PHRASE
    userVerificationCancelled:^{
        NSLog(@"User Voice Verication Cancelled");
    } userVerificationSuccessful:^(float voiceConfidence, NSString * jsonResponse){
        NSLog(@"User Voice Verication Successful voiceConfidence : %g ",voiceConfidence);
    } userVerificationFailed:^(float voiceConfidence, NSString * jsonResponse){
        NSLog(@"User Voice Verication Failed voiceConfidence : %g",voiceConfidence);
    }];
}

- (IBAction)voiceIdentificationClicked:(id)sender {
    NSLog(@"VOICE IDENTIFICATION CLICKED");
    [self.myVoiceIt encapsulatedVoiceIdentification:self.TEST_GROUP_ID
                                    contentLanguage:self.TEST_CONTENT_LANGUAGE
                                   voicePrintPhrase:self.TEST_PHRASE
    userIdentificationCancelled:^{
        NSLog(@"User Voice Identification Cancelled");
    } userIdentificationSuccessful:^(float voiceConfidence , NSString * foundUserId, NSString * jsonResponse){
        NSLog(@"User Voice Identification Successful voiceConfidence : %g and RESPONSE : %@", voiceConfidence, jsonResponse);
        [self showAlert:[[NSString alloc] initWithFormat:@"Succesfully identified user : %@ with voiceConfidence %g", foundUserId, voiceConfidence]];
        NSLog(@"Found user %@", foundUserId);
    } userIdentificationFailed:^(float voiceConfidence , NSString * jsonResponse){
        NSLog(@"User Voice Identification Failed voiceConfidence : %g and RESPONSE : %@", voiceConfidence, jsonResponse);
    }];
}

- (IBAction)faceIdentificationClicked:(id)sender {
    NSLog(@"FACE IDENTIFICATION CLICKED");
    [self.myVoiceIt encapsulatedFaceIdentification:self.TEST_GROUP_ID
                               doLivenessDetection:self.livenessToggle.isOn
                                    doAudioPrompts:self.audioPromptsToggle.isOn
    userIdentificationCancelled:^{
        NSLog(@"User Face Identification Cancelled");
    } userIdentificationSuccessful:^(float voiceConfidence , NSString * foundUserId, NSString * jsonResponse){
        NSLog(@"User Face Identification Successful faceConfidence : %g and RESPONSE : %@", voiceConfidence, jsonResponse);
        [self showAlert:[[NSString alloc] initWithFormat:@"Succesfully identified user : %@ with faceConfidence %g", foundUserId, voiceConfidence]];
        NSLog(@"Found user %@", foundUserId);
    } userIdentificationFailed:^(float voiceConfidence , NSString * jsonResponse){
        NSLog(@"User Voice Identification Failed voiceConfidence : %g and RESPONSE : %@", voiceConfidence, jsonResponse);
    }];
}

- (IBAction)videoIdentificationClicked:(id)sender {
    NSLog(@"VIDEO IDENTIFICATION CLICKED");
    [self.myVoiceIt encapsulatedVideoIdentification:self.TEST_GROUP_ID
                                    contentLanguage:self.TEST_CONTENT_LANGUAGE
                                   voicePrintPhrase:self.TEST_PHRASE
                                doLivenessDetection:self.livenessToggle.isOn
                                     doAudioPrompts:self.audioPromptsToggle.isOn
    userIdentificationCancelled:^{
        NSLog(@"User Video Identification Cancelled");
    } userIdentificationSuccessful:^(float voiceConfidence , float faceConfidence, NSString * foundUserId, NSString * jsonResponse){
        NSLog(@"User Video Identification Successful voiceConfidence : %g and faceConfidence : %g and RESPONSE : %@", voiceConfidence, faceConfidence, jsonResponse);
        [self showAlert:[[NSString alloc] initWithFormat:@"Succesfully identified user : %@ with voiceConfidence %g and faceConfidence %g", foundUserId, voiceConfidence, faceConfidence]];
        NSLog(@"Found user %@", foundUserId);
    } userIdentificationFailed:^(float voiceConfidence , float faceConfidence, NSString * jsonResponse){
        NSLog(@"User Video Identification Failed voiceConfidence : %g and RESPONSE : %@", voiceConfidence, jsonResponse);
    }];
}

- (IBAction)faceVerificationClicked:(id)sender {
    [self.myVoiceIt encapsulatedFaceVerification:self.TEST_USER_ID
                             doLivenessDetection:self.livenessToggle.isOn
                                  doAudioPrompts:self.audioPromptsToggle.isOn
    userVerificationCancelled:^{
        NSLog(@"User Face Verification Cancelled");
    } userVerificationSuccessful:^(float faceConfidence , NSString * jsonResponse){
        NSLog(@"User Face Verication Successful faceConfidence : %g and RESPONSE : %@", faceConfidence, jsonResponse);
    } userVerificationFailed:^(float faceConfidence , NSString * jsonResponse){
        NSLog(@"User Face Verication Failed faceConfidence : %g and RESPONSE : %@", faceConfidence, jsonResponse);
    }];
}

- (IBAction)videoVerificationClicked:(id)sender {
    [self.myVoiceIt encapsulatedVideoVerification:self.TEST_USER_ID
                                  contentLanguage:self.TEST_CONTENT_LANGUAGE
                                 voicePrintPhrase:self.TEST_PHRASE
                              doLivenessDetection:self.livenessToggle.isOn
                                   doAudioPrompts:self.audioPromptsToggle.isOn
    userVerificationCancelled:^{
         NSLog(@"User Verication Cancelled");
    } userVerificationSuccessful:^(float faceConfidence ,float voiceConfidence, NSString * jsonResponse){
        NSLog(@"User Verication Successful voiceConfidence : %g , faceConfidence : %g",voiceConfidence, faceConfidence);
    } userVerificationFailed:^(float faceConfidence ,float voiceConfidence, NSString * jsonResponse){
        NSLog(@"User Verication Failed voiceConfidence : %g , faceConfidence : %g",voiceConfidence, faceConfidence);
    }];
}

- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 2;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    if(row == 0){
        return self.TEST_USER_ID_ONE;
    }
    if(row == 1){
        return self.TEST_USER_ID_TWO;
    }
    return @"";
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    if(row == 0){
        self.TEST_USER_ID = self.TEST_USER_ID_ONE;
    }
    if(row == 1){
        self.TEST_USER_ID = self.TEST_USER_ID_TWO;
    }
}

-(void)showAlert:(NSString *) alertMessage {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Message"
                                                                   message:alertMessage
   preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)viewDidAppear:(BOOL)animated{
    if([self.TEST_USER_ID isEqualToString:@"USER_ID_HERE"]){
        [self showAlert:@"Please replace variables under VoiceItViewController.m with your credentials, groupId and userIds"];
    }
}
@end
