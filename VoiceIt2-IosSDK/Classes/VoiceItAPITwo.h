//
//  VoiceItAPITwo.h
//  VoiceIt2-IosSDK
//
//  Created by VoiceIt Technologies, LLC
//  Copyright (c) 2020 VoiceIt Technologies, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "Utilities.h"
#import "MainNavigationController.h"
#import "VoiceVerificationViewController.h"
#import "FaceVerificationViewController.h"
#import "VideoVerificationViewController.h"
#import "VoiceIdentificationViewController.h"


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
- (void)getAllUsers:(void (^)(NSString *, NSInteger *))callback;
- (void)getPhrases:(NSString *)contentLanguage callback:(void (^)(NSString *, NSInteger *))callback;
- (void)createUser:(void (^)(NSString *, NSInteger *))callback;
- (void)checkUserExists:(NSString *)userId callback:(void (^)(NSString *, NSInteger *))callback;
- (void)getGroupsForUser:(NSString *)userId callback:(void (^)(NSString *, NSInteger *))callback;
- (void)deleteUser: (NSString *)userId callback:(void (^)(NSString *, NSInteger *))callback;

#pragma mark - Group API Calls
- (void)getAllGroups:(void (^)(NSString *, NSInteger *))callback;
- (void)getGroup:(NSString *)groupId callback:(void (^)(NSString *, NSInteger *))callback;
- (void)groupExists:(NSString *)groupId callback:(void (^)(NSString *, NSInteger *))callback;
- (void)createGroup:(void (^)(NSString *))callback;
- (void)createGroup:(NSString *)description callback:(void (^)(NSString *))callback;
- (void)addUserToGroup:(NSString *)groupId userId:(NSString *)userId callback:(void (^)(NSString *, NSInteger *))callback;
- (void)removeUserFromGroup:(NSString *)groupId userId:(NSString *)userId callback:(void (^)(NSString *, NSInteger *))callback;
- (void)deleteGroup: (NSString *)groupId callback:(void (^)(NSString *))callback;

#pragma mark - Enrollment API Calls
- (void)getAllVoiceEnrollments:(NSString *)userId callback:(void (^)(NSString *, NSInteger *))callback;
- (void)getAllFaceEnrollments:(NSString *)userId callback:(void (^)(NSString *, NSInteger *))callback;
- (void)getAllVideoEnrollments:(NSString *)userId callback:(void (^)(NSString *, NSInteger *))callback;
- (void)deleteAllEnrollments:(NSString *)userId callback:(void (^)(NSString *, NSInteger *))callback;

- (void)createVoiceEnrollment:(NSString *)userId
              contentLanguage:(NSString *)contentLanguage
                    audioPath:(NSString *)audioPath
                       phrase:(NSString *)phrase
                     callback:(void (^)(NSString *, NSInteger *))callback;

- (void)createFaceEnrollment:(NSString *)userId
                   videoPath:(NSString *)videoPath
                    callback:(void (^)(NSString *, NSInteger *))callback;

- (void)createVideoEnrollment:(NSString *)userId
              contentLanguage:(NSString *)contentLanguage
                    imageData:(NSData *)imageData
                    audioPath:(NSString *)audioPath
                       phrase:(NSString *)phrase
                     callback:(void (^)(NSString *, NSInteger *))callback;

- (void)createVideoEnrollment:(NSString *)userId
              contentLanguage:(NSString *)contentLanguage
                    videoPath:(NSString *)videoPath
                       phrase:(NSString *)phrase
                     callback:(void (^)(NSString *, NSInteger *))callback;

#pragma mark - Verification API Calls

- (void)voiceVerification:(NSString *)userId
          contentLanguage:(NSString *)contentLanguage
                audioPath:(NSString *)audioPath
                   phrase:(NSString *)phrase
                 callback:(void (^)(NSString *, NSInteger *))callback;

- (void)faceVerification:(NSString *)userId
               videoPath:(NSString *)videoPath
                callback:(void (^)(NSString *, NSInteger *))callback;

- (void)faceVerification:(NSString *)userId
               imageData:(NSData *)imageData
                callback:(void (^)(NSString *, NSInteger *))callback;

- (void)faceVerificationWithLiveness:(NSString *)userId
                           videoPath:(NSString *)videoPath
                            callback:(void (^)(NSString *, NSInteger *))callback
                               lcoId:(NSString *) lcoId
                        pageCategory:(NSString *) pageCategory;

- (void)videoVerification:(NSString *)userId
          contentLanguage:(NSString *)contentLanguage
                videoPath:(NSString *)videoPath
                   phrase:(NSString *)phrase
                 callback:(void (^)(NSString *, NSInteger *))callback;

- (void)videoVerification:(NSString *)userId
          contentLanguage:(NSString *)contentLanguage
                imageData:(NSData *)imageData
                audioPath:(NSString *)audioPath
                   phrase:(NSString *)phrase
                 callback:(void (^)(NSString *, NSInteger *))callback;

- (void)videoVerificationWithLiveness:(NSString *)lcoId
                               userId:(NSString *)userId
                      contentLanguage:(NSString *)contentLanguage
                            videoPath:(NSString *)videoPath
                               phrase:(NSString *)phrase
                         pageCategory:(NSString *) pageCategory
                             callback:(void (^)(NSString *, NSInteger *))callback;


#pragma mark - Identification API Calls
- (void)voiceIdentification:(NSString *)groupId
            contentLanguage:(NSString *)contentLanguage
                  audioPath:(NSString *)audioPath
                     phrase:(NSString *)phrase
                   callback:(void (^)(NSString *, NSInteger *))callback;


#pragma mark - Encapsulated Enrollment Methods

- (void)encapsulatedVoiceEnrollUser:(NSString *)userId
                    contentLanguage:(NSString *)contentLanguage
                   voicePrintPhrase:(NSString *)voicePrintPhrase
           userEnrollmentsCancelled:(void (^)(void))userEnrollmentsCancelled
              userEnrollmentsPassed:(void (^)(NSString *))userEnrollmentsPassed;

- (void)encapsulatedFaceEnrollUser:(NSString *)userId
          userEnrollmentsCancelled:(void (^)(void))userEnrollmentsCancelled
             userEnrollmentsPassed:(void (^)(NSString *))userEnrollmentsPassed;

- (void)encapsulatedVideoEnrollUser:(NSString *)userId
                    contentLanguage:(NSString *)contentLanguage
                   voicePrintPhrase:(NSString *)voicePrintPhrase
           userEnrollmentsCancelled:(void (^)(void))userEnrollmentsCancelled
              userEnrollmentsPassed:(void (^)(NSString *))userEnrollmentsPassed;

#pragma mark - Encapsulated Verification Methods

- (void)encapsulatedVoiceVerification:(NSString *)userId
                      contentLanguage:(NSString *)contentLanguage
                     voicePrintPhrase:(NSString *)voicePrintPhrase
            userVerificationCancelled:(void (^)(void))userVerificationCancelled
           userVerificationSuccessful:(void (^)(float, NSString *))userVerificationSuccessful
               userVerificationFailed:(void (^)(float, NSString *))userVerificationFailed;

- (void)encapsulatedVoiceVerification:(NSString *)userId
                      contentLanguage:(NSString *)contentLanguage
                     voicePrintPhrase:(NSString *)voicePrintPhrase
                      numFailsAllowed:(int)numFailsAllowed
            userVerificationCancelled:(void (^)(void))userVerificationCancelled
           userVerificationSuccessful:(void (^)(float, NSString *))userVerificationSuccessful
               userVerificationFailed:(void (^)(float, NSString *))userVerificationFailed;

- (void)encapsulatedFaceVerification:(NSString *)userId
                 doLivenessDetection:(bool)doLivenessDetection
                      doAudioPrompts:(bool)doAudioPrompts
                      contentLanguage:(NSString *)contentLanguage
           userVerificationCancelled:(void (^)(void))userVerificationCancelled
          userVerificationSuccessful:(void (^)(float, NSString *))userVerificationSuccessful
              userVerificationFailed:(void (^)(float, NSString *))userVerificationFailed;

- (void)encapsulatedFaceVerification:(NSString *)userId
                 doLivenessDetection:(bool)doLivenessDetection
                      doAudioPrompts:(bool)doAudioPrompts
                     numFailsAllowed:(int)numFailsAllowed
                     contentLanguage:(NSString *)contentLanguage
       livenessChallengeFailsAllowed:(int)livenessChallengeFailsAllowed
           userVerificationCancelled:(void (^)(void))userVerificationCancelled
          userVerificationSuccessful:(void (^)(float, NSString *))userVerificationSuccessful
              userVerificationFailed:(void (^)(float, NSString *))userVerificationFailed;

- (void)encapsulatedVideoVerification:(NSString *)userId
                      contentLanguage:(NSString *)contentLanguage
                     voicePrintPhrase:(NSString *)voicePrintPhrase
                  doLivenessDetection:(bool)doLivenessDetection
                       doAudioPrompts:(bool)doAudioPrompts
            userVerificationCancelled:(void (^)(void))userVerificationCancelled
           userVerificationSuccessful:(void (^)(float, float, NSString *))userVerificationSuccessful
               userVerificationFailed:(void (^)(float, float, NSString *))userVerificationFailed;

- (void)encapsulatedVideoVerification:(NSString *)userId
                      contentLanguage:(NSString *)contentLanguage
                     voicePrintPhrase:(NSString *)voicePrintPhrase
                  doLivenessDetection:(bool)doLivenessDetection
                       doAudioPrompts:(bool)doAudioPrompts
                      numFailsAllowed:(int)numFailsAllowed
         livenessChallengeFailsAllowed:(int)livenessChallengeFailsAllowed
            userVerificationCancelled:(void (^)(void))userVerificationCancelled
           userVerificationSuccessful:(void (^)(float, float, NSString *))userVerificationSuccessful
               userVerificationFailed:(void (^)(float, float, NSString *))userVerificationFailed;

#pragma mark - Encapsulated Identification Methods

- (void)encapsulatedVoiceIdentification:(NSString *)groupId
                        contentLanguage:(NSString *)contentLanguage
                       voicePrintPhrase:(NSString *)voicePrintPhrase
            userIdentificationCancelled:(void (^)(void))userIdentificationCancelled
           userIdentificationSuccessful:(void (^)(float, NSString *, NSString *))userIdentificationSuccessful
               userIdentificationFailed:(void (^)(float, NSString *))userIdentificationFailed;

- (void)encapsulatedVoiceIdentification:(NSString *)groupId
                        contentLanguage:(NSString *)contentLanguage
                       voicePrintPhrase:(NSString *)voicePrintPhrase
                        numFailsAllowed:(int)numFailsAllowed
            userIdentificationCancelled:(void (^)(void))userIdentificationCancelled
           userIdentificationSuccessful:(void (^)(float, NSString *, NSString *))userIdentificationSuccessful
               userIdentificationFailed:(void (^)(float, NSString *))userIdentificationFailed;


#pragma mark - Liveness API Calls
- (void)getLivenessID:(NSString *)userId
          countryCode:(NSString *) countryCode
             callback:(void (^)(NSString *, NSInteger *))callback
             onFailed:(void(^)(NSError *))onFailed
          pageCateory:(NSString *) pageCategory;

@end
