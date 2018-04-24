//
//  VoiceItAPITwo.m
//  VoiceItAPITwoDemoApp
//
//  Created by Armaan Bindra on 3/7/17.
//  Copyright © 2017 Armaan Bindra. All rights reserved.
//

#import "VoiceItAPITwo.h"
#import "Styles.h"
NSString * const host = @"https://api.voiceit.io/";
@implementation VoiceItAPITwo

#pragma mark - Constructor
- (id)init:(UIViewController *)masterViewController apiKey:(NSString *)apiKey apiToken:(NSString *) apiToken {
    return [self init:masterViewController apiKey:apiKey apiToken:apiToken styles:nil];
}

- (id)init:(UIViewController *)masterViewController apiKey:(NSString *)apiKey apiToken:(NSString *) apiToken styles:(NSMutableDictionary *) styles {
    self.apiKey = apiKey;
    self.apiToken = apiToken;
    self.authHeader = [self createAuthHeader];
    self.contentLanguage = @"en-US";
    self.uniqueId = @"";
    self.boundary = [self generateBoundaryString];
    self.masterViewController = masterViewController;
#pragma mark - Save Styles Passed to Styles Class
    [Styles set:styles];
    return self;
}

#pragma mark - User API Calls

- (void)getAllUsers:(void (^)(NSString *))callback
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:[[NSURL alloc] initWithString:[self buildURL:@"users"]]];
    NSURLSession *session = [NSURLSession sharedSession];
    [request setHTTPMethod:@"GET"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request addValue:self.authHeader forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionDataTask *task =
    [session dataTaskWithRequest:request
               completionHandler:^(NSData *data, NSURLResponse *response,
                                   NSError *error) {
                   
                   NSString *result =
                   [[NSString alloc] initWithData:data
                                         encoding:NSUTF8StringEncoding];
                   NSLog(@"getAllUsers Called and Returned: %@", result);
                   // Add Call to Callback function passing in result
                   callback(result);
               }];
    [task resume];
}

- (void)getUser:(NSString *)userId callback:(void (^)(NSString *))callback
{
    if([userId isEqualToString:@""] || ![[self getFirst:userId numChars:4] isEqualToString:@"usr_"]){
        @throw [NSException exceptionWithName:@"Cannot Call Get User"
                                       reason:@"Invalid userId passed"
                                     userInfo:nil];
        return;
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:[[NSURL alloc] initWithString:[[NSString alloc] initWithFormat:@"%@/%@",[self buildURL:@"users"], userId]]];
    NSURLSession *session = [NSURLSession sharedSession];
    [request setHTTPMethod:@"GET"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request addValue:self.authHeader forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionDataTask *task =
    [session dataTaskWithRequest:request
               completionHandler:^(NSData *data, NSURLResponse *response,
                                   NSError *error) {
                   
                   NSString *result =
                   [[NSString alloc] initWithData:data
                                         encoding:NSUTF8StringEncoding];
                   NSLog(@"getUser Called and Returned: %@", result);
                   callback(result);
               }];
    [task resume];
}

- (void)getGroupsForUser:(NSString *)userId callback:(void (^)(NSString *))callback{
    if([userId isEqualToString:@""] || ![[self getFirst:userId numChars:4] isEqualToString:@"usr_"]){
        @throw [NSException exceptionWithName:@"Cannot Call Get Groups for User"
                                       reason:@"Invalid userId passed"
                                     userInfo:nil];
        return;
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:[[NSURL alloc] initWithString:[[NSString alloc] initWithFormat:@"%@/%@",[self buildURL:@"users/groups"], userId]]];
    NSURLSession *session = [NSURLSession sharedSession];
    [request setHTTPMethod:@"GET"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request addValue:self.authHeader forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionDataTask *task =
    [session dataTaskWithRequest:request
               completionHandler:^(NSData *data, NSURLResponse *response,
                                   NSError *error) {
                   
                   NSString *result =
                   [[NSString alloc] initWithData:data
                                         encoding:NSUTF8StringEncoding];
                   NSLog(@"getGroupsForUser Called and Returned: %@", result);
                   callback(result);
               }];
    [task resume];
}

- (void)createUser:(void (^)(NSString *))callback
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:[[NSURL alloc] initWithString:[self buildURL:@"users"]]];
    NSURLSession *session = [NSURLSession sharedSession];
    [request setHTTPMethod:@"POST"];
    [request addValue:self.authHeader forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionDataTask *task =
    [session dataTaskWithRequest:request
               completionHandler:^(NSData *data, NSURLResponse *response,
                                   NSError *error) {
                   
                   NSString *result =
                   [[NSString alloc] initWithData:data
                                         encoding:NSUTF8StringEncoding];
                   NSLog(@"createUser Called and Returned: %@", result);
                   callback(result);
               }];
    [task resume];
}

- (void)deleteUser: (NSString *)userId callback:(void (^)(NSString *))callback{
    
    if([userId isEqualToString:@""] || ![[self getFirst:userId numChars:4] isEqualToString:@"usr_"]){
        @throw [NSException exceptionWithName:@"Cannot Call Delete User"
                                       reason:@"Invalid userId passed"
                                     userInfo:nil];
        return;
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:[[NSURL alloc] initWithString:[[NSString alloc] initWithFormat:@"%@/%@",[self buildURL:@"users"], userId]]];
    NSURLSession *session = [NSURLSession sharedSession];
    [request setHTTPMethod:@"DELETE"];
    [request addValue:self.authHeader forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionDataTask *task =
    [session dataTaskWithRequest:request
               completionHandler:^(NSData *data, NSURLResponse *response,
                                   NSError *error) {
                   
                   NSString *result =
                   [[NSString alloc] initWithData:data
                                         encoding:NSUTF8StringEncoding];
                   NSLog(@"deleteUser Called and Returned: %@", result);
                   callback(result);
               }];
    [task resume];
}


#pragma mark - Group API Calls

- (void)getAllGroups:(void (^)(NSString *))callback
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:[[NSURL alloc] initWithString:[self buildURL:@"groups"]]];
    NSURLSession *session = [NSURLSession sharedSession];
    [request setHTTPMethod:@"GET"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request addValue:self.authHeader forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionDataTask *task =
    [session dataTaskWithRequest:request
               completionHandler:^(NSData *data, NSURLResponse *response,
                                   NSError *error) {
                   
                   NSString *result =
                   [[NSString alloc] initWithData:data
                                         encoding:NSUTF8StringEncoding];
                   NSLog(@"getAllGroups Called and Returned: %@", result);
                   callback(result);
               }];
    [task resume];
}

- (void)getGroup:(NSString *)groupId callback:(void (^)(NSString *))callback
{
    if([groupId isEqualToString:@""] || ![[self getFirst:groupId numChars:4] isEqualToString:@"grp_"]){
        @throw [NSException exceptionWithName:@"Cannot Call Get Group"
                                       reason:@"Invalid groupId passed"
                                     userInfo:nil];
        return;
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:[[NSURL alloc] initWithString:[[NSString alloc] initWithFormat:@"%@/%@",[self buildURL:@"groups"], groupId]]];
    
    NSURLSession *session = [NSURLSession sharedSession];
    [request setHTTPMethod:@"GET"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request addValue:self.authHeader forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionDataTask *task =
    [session dataTaskWithRequest:request
               completionHandler:^(NSData *data, NSURLResponse *response,
                                   NSError *error) {
                   
                   NSString *result =
                   [[NSString alloc] initWithData:data
                                         encoding:NSUTF8StringEncoding];
                   // Add Call to Callback function passing in result
                   callback(result);
               }];
    [task resume];
}

- (void)groupExists:(NSString *)groupId callback:(void (^)(NSString *))callback{
    if([groupId isEqualToString:@""] || ![[self getFirst:groupId numChars:4] isEqualToString:@"grp_"]){
        @throw [NSException exceptionWithName:@"Cannot Call Group Exists"
                                       reason:@"Invalid groupId passed"
                                     userInfo:nil];
        return;
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:[[NSURL alloc] initWithString:[[NSString alloc] initWithFormat:@"%@/%@/exists",[self buildURL:@"groups"], groupId]]];
    
    NSURLSession *session = [NSURLSession sharedSession];
    [request setHTTPMethod:@"GET"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request addValue:self.authHeader forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionDataTask *task =
    [session dataTaskWithRequest:request
               completionHandler:^(NSData *data, NSURLResponse *response,
                                   NSError *error) {
                   
                   NSString *result =
                   [[NSString alloc] initWithData:data
                                         encoding:NSUTF8StringEncoding];
                   // Add Call to Callback function passing in result
                   callback(result);
               }];
    [task resume];
}

- (void)createGroup:(void (^)(NSString *))callback{
    [self createGroup:@"" callback:callback];
}

- (void)createGroup:(NSString *)description callback:(void (^)(NSString *))callback
{
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", self.boundary];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:[[NSURL alloc] initWithString:[self buildURL:@"groups"]]];
    NSURLSession *session = [NSURLSession sharedSession];
    [request setHTTPMethod:@"POST"];
    
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    [request addValue:self.authHeader forHTTPHeaderField:@"Authorization"];
    
    NSDictionary *params = @{@"description" : description};
    NSData *body = [self createBodyWithBoundary:self.boundary parameters:params paths:nil fieldName:nil];
    NSURLSessionDataTask *task =  [session uploadTaskWithRequest:request fromData:body completionHandler:^(NSData *data, NSURLResponse *response,
                                                                                                           NSError *error) {
        NSString *result =
        [[NSString alloc] initWithData:data
                              encoding:NSUTF8StringEncoding];
        // Add Call to Callback function passing in result
        callback(result);
    }];
    
    [task resume];
}

- (void)addUserToGroup:(NSString *)groupId userId:(NSString *)userId callback:(void (^)(NSString *))callback
{
    if([userId isEqualToString:@""] || ![[self getFirst:userId numChars:4] isEqualToString:@"usr_"]){
        @throw [NSException exceptionWithName:@"Cannot Call Add User from Group"
                                       reason:@"Invalid userId passed"
                                     userInfo:nil];
        return;
    }
    
    if([groupId isEqualToString:@""] || ![[self getFirst:groupId numChars:4] isEqualToString:@"grp_"]){
        @throw [NSException exceptionWithName:@"Cannot Call Add User from Group"
                                       reason:@"Invalid groupId passed"
                                     userInfo:nil];
        return;
    }
    
    
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", self.boundary];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:[[NSURL alloc] initWithString:[self buildURL:@"groups/addUser"]]];
    NSURLSession *session = [NSURLSession sharedSession];
    [request setHTTPMethod:@"PUT"];
    
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    [request addValue:self.authHeader forHTTPHeaderField:@"Authorization"];
    
    NSDictionary *params = @{@"userId" : userId, @"groupId": groupId};
    NSData *body = [self createBodyWithBoundary:self.boundary parameters:params paths:nil fieldName:nil];
    NSURLSessionDataTask *task =  [session uploadTaskWithRequest:request fromData:body completionHandler:^(NSData *data, NSURLResponse *response,
                                                                                                           NSError *error) {
        NSString *result =
        [[NSString alloc] initWithData:data
                              encoding:NSUTF8StringEncoding];
        // Add Call to Callback function passing in result
        callback(result);
    }];
    
    [task resume];
}

- (void)removeUserFromGroup:(NSString *)groupId userId:(NSString *)userId callback:(void (^)(NSString *))callback{
    
    if([userId isEqualToString:@""] || ![[self getFirst:userId numChars:4] isEqualToString:@"usr_"]){
        @throw [NSException exceptionWithName:@"Cannot Call Remove User from Group"
                                       reason:@"Invalid userId passed"
                                     userInfo:nil];
        return;
    }
    
    if([groupId isEqualToString:@""] || ![[self getFirst:groupId numChars:4] isEqualToString:@"grp_"]){
        @throw [NSException exceptionWithName:@"Cannot Call Remove User from Group"
                                       reason:@"Invalid groupId passed"
                                     userInfo:nil];
        return;
    }
    
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", self.boundary];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:[[NSURL alloc] initWithString:[self buildURL:@"groups/removeUser"]]];
    NSURLSession *session = [NSURLSession sharedSession];
    [request setHTTPMethod:@"PUT"];
    
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    [request addValue:self.authHeader forHTTPHeaderField:@"Authorization"];
    
    NSDictionary *params = @{@"userId" : userId, @"groupId": groupId};
    NSData *body = [self createBodyWithBoundary:self.boundary parameters:params paths:nil fieldName:nil];
    NSURLSessionDataTask *task =  [session uploadTaskWithRequest:request fromData:body completionHandler:^(NSData *data, NSURLResponse *response,
                                                                                                           NSError *error) {
        NSString *result =
        [[NSString alloc] initWithData:data
                              encoding:NSUTF8StringEncoding];
        // Add Call to Callback function passing in result
        callback(result);
    }];
    
    [task resume];
}

- (void)deleteGroup: (NSString *)groupId callback:(void (^)(NSString *))callback{
    
    if([groupId isEqualToString:@""] || ![[self getFirst:groupId numChars:4] isEqualToString:@"grp_"]){
        @throw [NSException exceptionWithName:@"Cannot Call Delete Group"
                                       reason:@"Invalid groupId passed"
                                     userInfo:nil];
        return;
    }
    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:[[NSURL alloc] initWithString:[[NSString alloc] initWithFormat:@"%@/%@",[self buildURL:@"groups"], groupId]]];
    NSURLSession *session = [NSURLSession sharedSession];
    [request setHTTPMethod:@"DELETE"];
    [request addValue:self.authHeader forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionDataTask *task =
    [session dataTaskWithRequest:request
               completionHandler:^(NSData *data, NSURLResponse *response,
                                   NSError *error) {
                   
                   NSString *result =
                   [[NSString alloc] initWithData:data
                                         encoding:NSUTF8StringEncoding];
                   // Add Call to Callback function passing in result
                   callback(result);
               }];
    [task resume];
}

#pragma mark - Enrollment API Calls
- (void)getAllEnrollmentsForUser:(NSString *)userId callback:(void (^)(NSString *))callback{
    
    if([userId isEqualToString:@""] || ![[self getFirst:userId numChars:4] isEqualToString:@"usr_"]){
        @throw [NSException exceptionWithName:@"Cannot Get All Enrollment for User"
                                       reason:@"Invalid userId passed"
                                     userInfo:nil];
        return;
    }
    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:[[NSURL alloc] initWithString:[[NSString alloc] initWithFormat:@"%@/%@",[self buildURL:@"enrollments"], userId]]];
    NSURLSession *session = [NSURLSession sharedSession];
    [request setHTTPMethod:@"GET"];
    [request addValue:self.authHeader forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionDataTask *task =
    [session dataTaskWithRequest:request
               completionHandler:^(NSData *data, NSURLResponse *response,
                                   NSError *error) {
                   
                   NSString *result =
                   [[NSString alloc] initWithData:data
                                         encoding:NSUTF8StringEncoding];
                   // Add Call to Callback function passing in result
                   callback(result);
               }];
    [task resume];
}

- (void)deleteEnrollmentForUser:(NSString *)userId enrollmentId:(NSString *)enrollmentId callback:(void (^)(NSString *))callback{
    
    if([userId isEqualToString:@""] || ![[self getFirst:userId numChars:4] isEqualToString:@"usr_"]){
        @throw [NSException exceptionWithName:@"Cannot Delete Enrollments for User"
                                       reason:@"Invalid userId passed"
                                     userInfo:nil];
        return;
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:[[NSURL alloc] initWithString:[[NSString alloc] initWithFormat:@"%@/%@/%@",[self buildURL:@"enrollments"], userId, enrollmentId]]];
    NSURLSession *session = [NSURLSession sharedSession];
    [request setHTTPMethod:@"DELETE"];
    [request addValue:self.authHeader forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionDataTask *task =
    [session dataTaskWithRequest:request
               completionHandler:^(NSData *data, NSURLResponse *response,
                                   NSError *error) {
                   
                   NSString *result =
                   [[NSString alloc] initWithData:data
                                         encoding:NSUTF8StringEncoding];
                   // Add Call to Callback function passing in result
                   callback(result);
               }];
    [task resume];
}

- (void)deleteAllUserEnrollments: (NSString *)userId callback:(void (^)(NSString *))callback{
    
    if([userId isEqualToString:@""] || ![[self getFirst:userId numChars:4] isEqualToString:@"usr_"]){
        @throw [NSException exceptionWithName:@"Cannot Call Delete User"
                                       reason:@"Invalid userId passed"
                                     userInfo:nil];
        return;
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:[[NSURL alloc] initWithString:[[NSString alloc] initWithFormat:@"%@/%@/all",[self buildURL:@"enrollments"], userId]]];
    NSURLSession *session = [NSURLSession sharedSession];
    [request setHTTPMethod:@"DELETE"];
    [request addValue:self.authHeader forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionDataTask *task =
    [session dataTaskWithRequest:request
               completionHandler:^(NSData *data, NSURLResponse *response,
                                   NSError *error) {
                   
                   NSString *result =
                   [[NSString alloc] initWithData:data
                                         encoding:NSUTF8StringEncoding];
                   NSLog(@"deleteUser Called and Returned: %@", result);
                   callback(result);
               }];
    [task resume];
}

- (void)createVoiceEnrollment:(NSString *)userId
              contentLanguage:(NSString*)contentLanguage
            recordingFinished:(void (^)(void))recordingFinished
                     callback:(void (^)(NSString *))callback
{
    
    if([userId isEqualToString:@""] || ![[self getFirst:userId numChars:4] isEqualToString:@"usr_"]){
        @throw [NSException exceptionWithName:@"Cannot Create Audio Enrollment"
                                       reason:@"Invalid userId passed"
                                     userInfo:nil];
        return;
    }
    
    _uniqueId = userId;
    _contentLanguage = contentLanguage;
    _recType = enrollment;
    _voiceEnrollmentCompleted = callback;
    _recordingCompleted = recordingFinished;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self recordAudio];
    });
    
}

- (void)createVoiceEnrollment
{
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", self.boundary];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:[[NSURL alloc] initWithString:[self buildURL:@"enrollments"]]];
    NSURLSession *session = [NSURLSession sharedSession];
    [request setHTTPMethod:@"POST"];
    
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    [request addValue:self.authHeader forHTTPHeaderField:@"Authorization"];
    
    NSDictionary *params = @{@"contentLanguage" : _contentLanguage, @"userId": _uniqueId};
    NSMutableData *body = [NSMutableData data];
    
    [self addParamsToBody:body parameters:params];
    [self addFileToBody:body filePath:_recordingFilePath fieldName:@"recording"];
    [self endBody:body];
    
    NSURLSessionDataTask *task =  [session uploadTaskWithRequest:request fromData:body completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSString *result =
        [[NSString alloc] initWithData:data
                              encoding:NSUTF8StringEncoding];
        if(self.voiceEnrollmentCompleted){
            self.voiceEnrollmentCompleted(result);
        }
        
    }];
    
    [task resume];
}

- (void)encapsulatedVideoEnrollUser:(NSString *)userId
                    contentLanguage:(NSString*)contentLanguage
                   voicePrintPhrase:(NSString*)voicePrintPhrase
           userEnrollmentsCancelled:(void (^)(void))userEnrollmentsCancelled
              userEnrollmentsPassed:(void (^)(void))userEnrollmentsPassed
{
    
    if([userId isEqualToString:@""] || ![[self getFirst:userId numChars:4] isEqualToString:@"usr_"]){
        @throw [NSException exceptionWithName:@"Cannot Create Video Enrollment"
                                       reason:@"Invalid userId passed"
                                     userInfo:nil];
        return;
    }
    
    MainNavigationController * controller = (MainNavigationController *) [[Utilities getVoiceItStoryBoard] instantiateViewControllerWithIdentifier:@"mainNavController"];
    controller.uniqueId = userId;
    controller.contentLanguage = contentLanguage;
    controller.voicePrintPhrase = voicePrintPhrase;
    controller.userEnrollmentsCancelled = userEnrollmentsCancelled;
    controller.userEnrollmentsPassed = userEnrollmentsPassed;
    controller.myVoiceIt = self;
    [[self masterViewController] presentViewController:controller animated:YES completion:nil];
}

- (void)encapsulatedVideoVerification:(NSString *)userId
                      contentLanguage:(NSString*)contentLanguage
                     voicePrintPhrase:(NSString*)voicePrintPhrase
                  doLivenessDetection:(bool)doLivenessDetection
            userVerificationCancelled:(void (^)(void))userVerificationCancelled
           userVerificationSuccessful:(void (^)(float, float, NSString *))userVerificationSuccessful
               userVerificationFailed:(void (^)(float, float, NSString *))userVerificationFailed
{
    
    if([userId isEqualToString:@""] || ![[self getFirst:userId numChars:4] isEqualToString:@"usr_"]){
        @throw [NSException exceptionWithName:@"Cannot Do Video Verification"
                                       reason:@"Invalid userId passed"
                                     userInfo:nil];
        return;
    }
    
    VideoVerificationViewController *verifyVC = [[Utilities getVoiceItStoryBoard] instantiateViewControllerWithIdentifier:@"videoVerifyVC"];
    verifyVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    verifyVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    verifyVC.userToVerifyUserId = userId;
    verifyVC.contentLanguage = contentLanguage;
    verifyVC.thePhrase = voicePrintPhrase;
    verifyVC.userVerificationCancelled = userVerificationCancelled;
    verifyVC.userVerificationSuccessful = userVerificationSuccessful;
    verifyVC.userVerificationFailed = userVerificationFailed;
    verifyVC.doLivenessDetection = doLivenessDetection;
    verifyVC.voiceItMaster = self;
    [[self masterViewController] presentViewController: verifyVC animated:YES completion:nil];
}

- (void)encapsulatedFaceVerification:(NSString *)userId
                 doLivenessDetection:(bool)doLivenessDetection
           userVerificationCancelled:(void (^)(void))userVerificationCancelled
           userVerificationSuccessful:(void (^)(float, NSString *))userVerificationSuccessful
               userVerificationFailed:(void (^)(float, NSString *))userVerificationFailed
{
    
    if([userId isEqualToString:@""] || ![[self getFirst:userId numChars:4] isEqualToString:@"usr_"]){
        @throw [NSException exceptionWithName:@"Cannot Do Face Verification"
                                       reason:@"Invalid userId passed"
                                     userInfo:nil];
        return;
    }
    
    FaceVerificationViewController *faceVerificationVC = [[Utilities getVoiceItStoryBoard] instantiateViewControllerWithIdentifier:@"faceVerificationVC"];
    faceVerificationVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    faceVerificationVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    faceVerificationVC.userToVerifyUserId = userId;
    faceVerificationVC.userVerificationCancelled = userVerificationCancelled;
    faceVerificationVC.userVerificationSuccessful = userVerificationSuccessful;
    faceVerificationVC.userVerificationFailed = userVerificationFailed;
    faceVerificationVC.voiceItMaster = self;
    faceVerificationVC.doLivenessDetection = doLivenessDetection;
    [[self masterViewController] presentViewController: faceVerificationVC animated:YES completion:nil];
}

- (void)encapsulatedVoiceVerification:(NSString *)userId
                      contentLanguage:(NSString*)contentLanguage
                     voicePrintPhrase:(NSString*)voicePrintPhrase
            userVerificationCancelled:(void (^)(void))userVerificationCancelled
           userVerificationSuccessful:(void (^)(float, NSString *))userVerificationSuccessful
               userVerificationFailed:(void (^)(float, NSString *))userVerificationFailed
{
    
    if([userId isEqualToString:@""] || ![[self getFirst:userId numChars:4] isEqualToString:@"usr_"]){
        @throw [NSException exceptionWithName:@"Cannot Do Video Verification"
                                       reason:@"Invalid userId passed"
                                     userInfo:nil];
        return;
    }
    
    VoiceVerificationViewController *verifyVoice = [[Utilities getVoiceItStoryBoard] instantiateViewControllerWithIdentifier:@"verifyVoiceVC"];
    verifyVoice.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    verifyVoice.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    verifyVoice.userToVerifyUserId = userId;
    verifyVoice.contentLanguage = contentLanguage;
    verifyVoice.thePhrase = voicePrintPhrase;
    verifyVoice.userVerificationCancelled = userVerificationCancelled;
    verifyVoice.userVerificationSuccessful = userVerificationSuccessful;
    verifyVoice.userVerificationFailed = userVerificationFailed;
    verifyVoice.voiceItMaster = self;
    [[self masterViewController] presentViewController: verifyVoice animated:YES completion:nil];
}

- (void)createVideoEnrollment:(NSString *)userId
              contentLanguage:(NSString*)contentLanguage
                    imageData:(NSData*)imageData
                    audioPath:(NSString*)audioPath
                     callback:(void (^)(NSString *))callback
{
    
    if([userId isEqualToString:@""] || ![[self getFirst:userId numChars:4] isEqualToString:@"usr_"]){
        @throw [NSException exceptionWithName:@"Cannot Create Video Enrollment"
                                       reason:@"Invalid userId passed"
                                     userInfo:nil];
        return;
    }
    
    _uniqueId = userId;
    _contentLanguage = contentLanguage;
    _recType = enrollment;
    _videoEnrollmentCompleted = callback;
    _recordingFilePath = audioPath;
    _photoData = imageData;
    [self createVideoEnrollment];
}

- (void)createVideoEnrollment
{
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", self.boundary];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:[[NSURL alloc] initWithString:[self buildURL:@"enrollments/video"]]];
    NSURLSession *session = [NSURLSession sharedSession];
    [request setHTTPMethod:@"POST"];
    
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    [request addValue:self.authHeader forHTTPHeaderField:@"Authorization"];
    
    NSDictionary *params = @{@"contentLanguage" : _contentLanguage, @"userId": _uniqueId};
    NSMutableData *body = [NSMutableData data];
    
    [self addParamsToBody:body parameters:params];
    [self addFileToBody:body filePath:_recordingFilePath fieldName:@"audio"];
    [self addImageToBody:body imageData:_photoData fieldName:@"photo"];
    [self endBody:body];
    
    NSURLSessionDataTask *task =  [session uploadTaskWithRequest:request fromData:body completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSString *result =
        [[NSString alloc] initWithData:data
                              encoding:NSUTF8StringEncoding];
        if(self.videoEnrollmentCompleted){
            self.videoEnrollmentCompleted(result);
        }
    }];
    
    [task resume];
}


#pragma mark - Verification API Calls

- (void)voiceVerification:(NSString *)userId
          contentLanguage:(NSString*)contentLanguage
        recordingFinished:(void (^)(void))recordingFinished
                 callback:(void (^)(NSString *))callback
{
    if([userId isEqualToString:@""] || ![[self getFirst:userId numChars:4] isEqualToString:@"usr_"]){
        @throw [NSException exceptionWithName:@"Cannot Call Audio Verification"
                                       reason:@"Invalid userId passed"
                                     userInfo:nil];
        return;
    }
    
    _uniqueId = userId;
    _contentLanguage = contentLanguage;
    _recType = verification;
    _voiceVerificationCompleted = callback;
    _recordingCompleted = recordingFinished;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self recordAudio];
    });
}

- (void)voiceVerification:(NSString *)userId
          contentLanguage:(NSString*)contentLanguage
                audioPath:(NSString*)audioPath
                 callback:(void (^)(NSString *))callback
{
    
    if([userId isEqualToString:@""] || ![[self getFirst:userId numChars:4] isEqualToString:@"usr_"]){
        @throw [NSException exceptionWithName:@"Cannot Call Video Verification"
                                       reason:@"Invalid userId passed"
                                     userInfo:nil];
        return;
    }
    
    _uniqueId = userId;
    _contentLanguage = contentLanguage;
    _recType = verification;
    _voiceVerificationCompleted = callback;
    
    _recordingFilePath = audioPath;
    // TODO: Save Photo to Photos for Testing
    //    [Utilities savePhotoToPhotos:[UIImage imageWithData:_photoData]];
    [self voiceVerification];
}

-(void)voiceVerification{
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; charset=utf-8; boundary=%@", self.boundary];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:[[NSURL alloc] initWithString:[self buildURL:@"verification"]]];
    NSURLSession *session = [NSURLSession sharedSession];
    [request setHTTPMethod:@"POST"];
    
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    [request addValue:self.authHeader forHTTPHeaderField:@"Authorization"];
    
    NSDictionary *params = @{@"contentLanguage" : _contentLanguage, @"userId": _uniqueId};
    NSMutableData *body = [NSMutableData data];
    
    [self addParamsToBody:body parameters:params];
    [self addFileToBody:body filePath:_recordingFilePath fieldName:@"recording"];
    [self endBody:body];
    
    NSURLSessionDataTask *task =  [session uploadTaskWithRequest:request fromData:body completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSString *result =
        [[NSString alloc] initWithData:data
                              encoding:NSUTF8StringEncoding];
        
        if(self.voiceVerificationCompleted){
            self.voiceVerificationCompleted(result);
        }
    }];
    
    [task resume];
}

- (void)faceVerification:(NSString *)userId
               videoPath:(NSString*)videoPath
                callback:(void (^)(NSString *))callback
{
    
    if([userId isEqualToString:@""] || ![[self getFirst:userId numChars:4] isEqualToString:@"usr_"]){
        @throw [NSException exceptionWithName:@"Cannot Call Face Verification"
                                       reason:@"Invalid userId passed"
                                     userInfo:nil];
        return;
    }
    
    _uniqueId = userId;
    _faceVerificationCompleted = callback;
    _recordingFilePath = videoPath;
    [self faceVerification];
}

-(void)faceVerification{
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; charset=utf-8; boundary=%@", self.boundary];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:[[NSURL alloc] initWithString:[self buildURL:@"verification/face"]]];
    NSURLSession *session = [NSURLSession sharedSession];
    [request setHTTPMethod:@"POST"];
    
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    [request addValue:self.authHeader forHTTPHeaderField:@"Authorization"];
    
    NSDictionary *params = @{@"userId": _uniqueId, @"doBlinkDetection" : @false};
    NSMutableData *body = [NSMutableData data];
    [self addParamsToBody:body parameters:params];
    [self addFileToBody:body filePath:_recordingFilePath fieldName:@"video"];
    [self endBody:body];
    
    NSURLSessionDataTask *task =  [session uploadTaskWithRequest:request fromData:body completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSString *result =
        [[NSString alloc] initWithData:data
                              encoding:NSUTF8StringEncoding];
        if(self.faceVerificationCompleted){
            self.faceVerificationCompleted(result);
        }
    }];
    
    [task resume];
}

- (void)videoVerification:(NSString *)userId
          contentLanguage:(NSString*)contentLanguage
                imageData:(NSData*)imageData
                audioPath:(NSString*)audioPath
                 callback:(void (^)(NSString *))callback
{
    
    if([userId isEqualToString:@""] || ![[self getFirst:userId numChars:4] isEqualToString:@"usr_"]){
        @throw [NSException exceptionWithName:@"Cannot Call Video Verification"
                                       reason:@"Invalid userId passed"
                                     userInfo:nil];
        return;
    }
    
    _uniqueId = userId;
    _contentLanguage = contentLanguage;
    _recType = verification;
    _videoVerificationCompleted = callback;
    
    _recordingFilePath = audioPath;
    _photoData = imageData;
    // TODO: Save Photo to Photos for Testing
    //    [Utilities savePhotoToPhotos:[UIImage imageWithData:_photoData]];
    [self videoVerification];
}

-(void)videoVerification{
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; charset=utf-8; boundary=%@", self.boundary];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:[[NSURL alloc] initWithString:[self buildURL:@"verification/video"]]];
    NSURLSession *session = [NSURLSession sharedSession];
    [request setHTTPMethod:@"POST"];
    
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    [request addValue:self.authHeader forHTTPHeaderField:@"Authorization"];
    
    NSDictionary *params = @{@"contentLanguage" : _contentLanguage, @"userId": _uniqueId};
    NSMutableData *body = [NSMutableData data];
    
    [self addParamsToBody:body parameters:params];
    [self addFileToBody:body filePath:_recordingFilePath fieldName:@"audio"];
    [self addImageToBody:body imageData:_photoData fieldName:@"photo"];
    [self endBody:body];
    
    NSURLSessionDataTask *task =  [session uploadTaskWithRequest:request fromData:body completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSString *result =
        [[NSString alloc] initWithData:data
                              encoding:NSUTF8StringEncoding];
        if(self.videoVerificationCompleted){
            self.videoVerificationCompleted(result);
        }
    }];
    
    [task resume];
}

#pragma mark - Identification API Calls
- (void)voiceIdentification:(NSString *)groupId
            contentLanguage:(NSString*)contentLanguage
          recordingFinished:(void (^)(void))recordingFinished
                   callback:(void (^)(NSString *))callback
{
    
    if([groupId isEqualToString:@""] || ![[self getFirst:groupId numChars:4] isEqualToString:@"grp_"]){
        @throw [NSException exceptionWithName:@"Cannot Call Audio Identification"
                                       reason:@"Invalid groupId passed"
                                     userInfo:nil];
        return;
    }
    
    _uniqueId = groupId;
    _contentLanguage = contentLanguage;
    _recType = identification;
    _voiceIdentificationCompleted = callback;
    _recordingCompleted = recordingFinished;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self recordAudio];
    });
}

- (void)voiceIdentification{
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; charset=utf-8; boundary=%@", self.boundary];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:[[NSURL alloc] initWithString:[self buildURL:@"identification"]]];
    NSURLSession *session = [NSURLSession sharedSession];
    [request setHTTPMethod:@"POST"];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    [request addValue:self.authHeader forHTTPHeaderField:@"Authorization"];
    
    NSDictionary *params = @{@"contentLanguage" : _contentLanguage, @"groupId": _uniqueId, @"doBlinkDetection" : @NO };
    NSMutableData *body = [NSMutableData data];
    
    [self addParamsToBody:body parameters:params];
    [self addFileToBody:body filePath:_recordingFilePath fieldName:@"recording"];
    [self endBody:body];
    
    NSURLSessionDataTask *task =  [session uploadTaskWithRequest:request fromData:body completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSString *result =
        [[NSString alloc] initWithData:data
                              encoding:NSUTF8StringEncoding];
        if(self.voiceIdentificationCompleted){
            self.voiceIdentificationCompleted(result);
        }
    }];
    
    [task resume];
}

#pragma mark - Utilities
-(NSString*)getFirst:(NSString *)str numChars:(int)numChars{
    return [str substringWithRange:NSMakeRange(0, numChars)];
}

-(NSString*)buildURL:(NSString*)endpoint
{
    return [[NSString alloc] initWithFormat:@"%@%@", host, endpoint];
}

-(void)getAudioFromVideo:(NSString * )srcPath dstPath:(NSString *)dstPath callback:(void (^)(NSString *))callback{
    NSURL*      dstURL = [NSURL fileURLWithPath:dstPath];
    NSURL*      srcURL = [NSURL fileURLWithPath:srcPath];
    
    [[NSFileManager defaultManager] removeItemAtURL:dstURL error:nil];
    
    AVMutableComposition*   newAudioAsset = [AVMutableComposition composition];
    
    AVMutableCompositionTrack*  dstCompositionTrack;
    dstCompositionTrack = [newAudioAsset addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVAsset*    srcAsset = [AVURLAsset URLAssetWithURL:srcURL options:nil];
    AVAssetTrack*   srcTrack = [[srcAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    
    CMTimeRange timeRange = srcTrack.timeRange;
    NSError*    error;
    
    if(NO == [dstCompositionTrack insertTimeRange:timeRange ofTrack:srcTrack atTime:kCMTimeZero error:&error]) {
        return;
    }
    
    AVAssetExportSession*   exportSesh = [[AVAssetExportSession alloc] initWithAsset:newAudioAsset presetName:AVAssetExportPresetPassthrough];
    
    exportSesh.outputFileType = AVFileTypeAppleM4A;
    exportSesh.outputURL = dstURL;
    
    [exportSesh exportAsynchronouslyWithCompletionHandler:^{
        AVAssetExportSessionStatus  status = exportSesh.status;
        callback(dstPath);
        if(AVAssetExportSessionStatusFailed == status) {
            NSLog(@"FAILURE: %@\n", exportSesh.error);
        } else if(AVAssetExportSessionStatusCompleted == status) {
            NSLog(@"SUCCESS!\n");
        }
    }];
}

-(NSString*)createAuthHeader
{
    // Create NSData object
    NSData *nsdata = [[NSString stringWithFormat:@"%@:%@", self.apiKey, self.apiToken]
                      dataUsingEncoding:NSUTF8StringEncoding];
    // Get NSString from NSData object in Base64
    NSString *base64Encoded = [nsdata base64EncodedStringWithOptions:0];
    
    return [NSString stringWithFormat:@"Basic %@", base64Encoded];
}

- (NSString *)generateBoundaryString
{
    return [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];
}

- (void)addParamsToBody:(NSMutableData *)httpBody parameters:(NSDictionary *)parameters {
    // add params (all params are strings)
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *parameterKey, NSString *parameterValue, BOOL *stop) {
        [httpBody appendData:[[NSString stringWithFormat:@"--%@\r\n", self.boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", parameterKey] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"%@\r\n", parameterValue] dataUsingEncoding:NSUTF8StringEncoding]];
    }];
}

-(void)addFileToBody:(NSMutableData *)httpBody filePath:(NSString *)filePath fieldName:(NSString *)fieldName{
    NSString *filename  = [filePath lastPathComponent];
    NSData   *data      = [NSData dataWithContentsOfFile:filePath];
    NSString *mimetype  = [self mimeTypeForPath:filePath];
    
    [httpBody appendData:[[NSString stringWithFormat:@"--%@\r\n", self.boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", fieldName, filename] dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mimetype] dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:data];
    [httpBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
}

-(void)addImageToBody:(NSMutableData *)httpBody imageData:(NSData *)imageData fieldName:(NSString *)fieldName{
    NSString *filename  = @"frame.jpg";
    NSString *mimetype  = @"image/jpeg";
    [httpBody appendData:[[NSString stringWithFormat:@"--%@\r\n", self.boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", fieldName, filename] dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mimetype] dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:imageData];
    [httpBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
}

-(void)endBody:(NSMutableData *)body{
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", self.boundary] dataUsingEncoding:NSUTF8StringEncoding]];
}

-(void)recordAudio{
    //    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err;
    //    [audioSession setCategory:AVAudioSessionCategoryRecord error:&err];
    //    if (err)
    //    {
    //        NSLog(@"%@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
    //    }
    //    err = nil;
    //    if (err)
    //    {
    //        NSLog(@"%@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
    //    }
    
    // Unique recording URL
    NSString *fileName = @"RecordedFile"; // Changed it So It Keeps Replacing File
    _recordingFilePath = [NSTemporaryDirectory()
                          stringByAppendingPathComponent:[NSString
                                                          stringWithFormat:@"%@.wav", fileName]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:_recordingFilePath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:_recordingFilePath
                                                   error:nil];
    }
    
    NSURL *url = [NSURL fileURLWithPath:_recordingFilePath];
    
    err = nil;
    _recorder = [[AVAudioRecorder alloc] initWithURL:url settings:[Utilities getRecordingSettings] error:&err];
    if(!_recorder){
        NSLog(@"recorder: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
        return;
    }
    [_recorder setDelegate:self];
    [_recorder prepareToRecord];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [_recorder recordForDuration:5.0];
}

- (NSData *)createBodyWithBoundary:(NSString *)boundary
                        parameters:(NSDictionary *)parameters
                             paths:(NSArray *)paths
                         fieldName:(NSString *)fieldName
{
    NSMutableData *httpBody = [NSMutableData data];
    
    // add params (all params are strings)
    
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *parameterKey, NSString *parameterValue, BOOL *stop) {
        [httpBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", parameterKey] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"%@\r\n", parameterValue] dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    
    // add audio data
    
    for (NSString *path in paths) {
        NSString *filename  = [path lastPathComponent];
        NSData   *data      = [NSData dataWithContentsOfFile:path];
        NSString *mimetype  = [self mimeTypeForPath:path];
        
        [httpBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", fieldName, filename] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mimetype] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:data];
        [httpBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [httpBody appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    return httpBody;
}

- (NSString *)mimeTypeForPath:(NSString *)path
{
    // get a mime type for an extension using MobileCoreServices.framework
    
    CFStringRef extension = (__bridge CFStringRef)[path pathExtension];
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, extension, NULL);
    assert(UTI != NULL);
    
    NSString *mimetype = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType));
    assert(mimetype != NULL);
    
    CFRelease(UTI);
    return mimetype;
}

#pragma mark - AVAudioRecorderDelegate Methods

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err;
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&err];
    if(err){
        NSLog(@"Setting Category Error:%@", err.localizedDescription);
    }
    
    [audioSession setActive:NO error:&err];
    
    NSURL *url = [NSURL fileURLWithPath: _recordingFilePath];
    err = nil;
    NSData *audioData = [NSData dataWithContentsOfFile:[url path] options: 0 error:&err];
    if(!audioData) {
        NSLog(@"audio data: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
    }
    
    if (self.recordingCompleted){
        self.recordingCompleted();
    }
    
    switch (_recType) {
        case enrollment:
            [self createVoiceEnrollment];
            break;
        case verification:
            [self voiceVerification];
            break;
        case identification:
            [self voiceIdentification];
            break;
        default:
            break;
    }
    
}

-(void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    NSLog(@"fail because %@", error.localizedDescription);
}

@end
