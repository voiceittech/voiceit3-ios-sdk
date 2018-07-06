//
//  VoiceItAPITwo.h
//  VoiceItAPITwoDemoApp
//
//  Created by Armaan Bindra on 3/7/17.
//  Copyright © 2017 Armaan Bindra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "Utilities.h"
#import "MainNavigationController.h"
#import "FaceVerificationViewController.h"
#import "VideoVerificationViewController.h"
#import "VoiceVerificationViewController.h"

@import MobileCoreServices;

@interface VoiceItAPITwo : NSObject
// Properties
@property (nonatomic, strong) NSString *apiKey;
@property (nonatomic, strong) NSString *apiToken;
@property (nonatomic, strong) NSString *authHeader;
@property (nonatomic, strong) NSString *boundary;
@property (nonatomic, strong) UIViewController * masterViewController;

#pragma mark - Constructor
- (id)init:(UIViewController *)masterViewController apiKey:(NSString *)apiKey apiToken:(NSString *) apiToken;
- (id)init:(UIViewController *)masterViewController apiKey:(NSString *)apiKey apiToken:(NSString *) apiToken styles:(NSMutableDictionary *) styles;

#pragma mark - User API Calls
- (void)getAllUsers:(void (^)(NSString *))callback;
- (void)createUser:(void (^)(NSString *))callback;
- (void)checkUserExists:(NSString *)userId callback:(void (^)(NSString *))callback;
- (void)getGroupsForUser:(NSString *)userId callback:(void (^)(NSString *))callback;
- (void)deleteUser: (NSString *)userId callback:(void (^)(NSString *))callback;

#pragma mark - Group API Calls
- (void)getAllGroups:(void (^)(NSString *))callback;
- (void)getGroup:(NSString *)groupId callback:(void (^)(NSString *))callback;
- (void)groupExists:(NSString *)groupId callback:(void (^)(NSString *))callback;
- (void)createGroup:(void (^)(NSString *))callback;
- (void)createGroup:(NSString *)description callback:(void (^)(NSString *))callback;
- (void)addUserToGroup:(NSString *)groupId userId:(NSString *)userId callback:(void (^)(NSString *))callback;
- (void)removeUserFromGroup:(NSString *)groupId userId:(NSString *)userId callback:(void (^)(NSString *))callback;
- (void)deleteGroup: (NSString *)groupId callback:(void (^)(NSString *))callback;

#pragma mark - Enrollment API Calls
- (void)getAllEnrollmentsForUser:(NSString *)userId callback:(void (^)(NSString *))callback;
- (void)getAllFaceEnrollmentsForUser:(NSString *)userId callback:(void (^)(NSString *))callback;
- (void)deleteEnrollmentForUser:(NSString *)userId enrollmentId:(NSString *)enrollmentId callback:(void (^)(NSString *))callback;
- (void)deleteAllUserEnrollments: (NSString *)userId callback:(void (^)(NSString *))callback;

- (void)createVoiceEnrollment:(NSString *)userId
              contentLanguage:(NSString*)contentLanguage
                    audioPath:(NSString*)audioPath
                     callback:(void (^)(NSString *))callback;

- (void)createFaceEnrollment:(NSString *)userId
                   videoPath:(NSString*)videoPath
                    callback:(void (^)(NSString *))callback;

- (void)createVideoEnrollment:(NSString *)userId
              contentLanguage:(NSString*)contentLanguage
                    imageData:(NSData*)imageData
                    audioPath:(NSString*)audioPath
                     callback:(void (^)(NSString *))callback;

- (void)createVideoEnrollment:(NSString *)userId
              contentLanguage:(NSString*)contentLanguage
                    videoPath:(NSString*)videoPath
                     callback:(void (^)(NSString *))callback;

#pragma mark - Verification API Calls

- (void)voiceVerification:(NSString *)userId
          contentLanguage:(NSString*)contentLanguage
                audioPath:(NSString*)audioPath
                 callback:(void (^)(NSString *))callback;

- (void)faceVerification:(NSString *)userId
               videoPath:(NSString*)videoPath
                callback:(void (^)(NSString *))callback;

- (void)faceVerification:(NSString *)userId
               imageData:(NSData*)imageData
                callback:(void (^)(NSString *))callback;

- (void)videoVerification:(NSString *)userId
          contentLanguage:(NSString*)contentLanguage
                videoPath:(NSString*)videoPath
                 callback:(void (^)(NSString *))callback;

- (void)videoVerification:(NSString *)userId
          contentLanguage:(NSString*)contentLanguage
                imageData:(NSData*)imageData
                audioPath:(NSString*)audioPath
                 callback:(void (^)(NSString *))callback;

#pragma mark - Identification API Calls
- (void)voiceIdentification:(NSString *)groupId
            contentLanguage:(NSString*)contentLanguage
                  audioPath:(NSString*)audioPath
                   callback:(void (^)(NSString *))callback;

- (void)videoIdentification:(NSString *)groupId
            contentLanguage:(NSString*)contentLanguage
                  videoPath:(NSString*)videoPath
                   callback:(void (^)(NSString *))callback;

#pragma mark - Encapsulated Enrollment Methods

- (void)encapsulatedVoiceEnrollUser:(NSString *)userId
                    contentLanguage:(NSString*)contentLanguage
                   voicePrintPhrase:(NSString*)voicePrintPhrase
           userEnrollmentsCancelled:(void (^)(void))userEnrollmentsCancelled
              userEnrollmentsPassed:(void (^)(void))userEnrollmentsPassed;

- (void)encapsulatedFaceEnrollUser:(NSString *)userId
          userEnrollmentsCancelled:(void (^)(void))userEnrollmentsCancelled
             userEnrollmentsPassed:(void (^)(void))userEnrollmentsPassed;

- (void)encapsulatedVideoEnrollUser:(NSString *)userId
                    contentLanguage:(NSString*)contentLanguage
                   voicePrintPhrase:(NSString*)voicePrintPhrase
           userEnrollmentsCancelled:(void (^)(void))userEnrollmentsCancelled
              userEnrollmentsPassed:(void (^)(void))userEnrollmentsPassed;

#pragma mark - Encapsulated Verification Methods

- (void)encapsulatedVoiceVerification:(NSString *)userId
                      contentLanguage:(NSString*)contentLanguage
                     voicePrintPhrase:(NSString*)voicePrintPhrase
            userVerificationCancelled:(void (^)(void))userVerificationCancelled
           userVerificationSuccessful:(void (^)(float, NSString *))userVerificationSuccessful
               userVerificationFailed:(void (^)(float, NSString *))userVerificationFailed;

- (void)encapsulatedFaceVerification:(NSString *)userId
                 doLivenessDetection:(bool)doLivenessDetection
           userVerificationCancelled:(void (^)(void))userVerificationCancelled
          userVerificationSuccessful:(void (^)(float, NSString *))userVerificationSuccessful
              userVerificationFailed:(void (^)(float, NSString *))userVerificationFailed;

- (void)encapsulatedFaceVerification:(NSString *)userId
                 doLivenessDetection:(bool)doLivenessDetection
       livenessChallengeFailsAllowed:(int)livenessChallengeFailsAllowed
           userVerificationCancelled:(void (^)(void))userVerificationCancelled
          userVerificationSuccessful:(void (^)(float, NSString *))userVerificationSuccessful
              userVerificationFailed:(void (^)(float, NSString *))userVerificationFailed;

- (void)encapsulatedVideoVerification:(NSString *)userId
                      contentLanguage:(NSString*)contentLanguage
                     voicePrintPhrase:(NSString*)voicePrintPhrase
                  doLivenessDetection:(bool)doLivenessDetection
            userVerificationCancelled:(void (^)(void))userVerificationCancelled
           userVerificationSuccessful:(void (^)(float, float, NSString *))userVerificationSuccessful
               userVerificationFailed:(void (^)(float, float, NSString *))userVerificationFailed;

- (void)encapsulatedVideoVerification:(NSString *)userId
                      contentLanguage:(NSString*)contentLanguage
                     voicePrintPhrase:(NSString*)voicePrintPhrase
                  doLivenessDetection:(bool)doLivenessDetection
         livenessChallengeFailsAllowed:(int)livenessChallengeFailsAllowed
            userVerificationCancelled:(void (^)(void))userVerificationCancelled
           userVerificationSuccessful:(void (^)(float, float, NSString *))userVerificationSuccessful
               userVerificationFailed:(void (^)(float, float, NSString *))userVerificationFailed;

@end

