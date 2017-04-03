//
//  VoiceItAPITwo.h
//  VoiceItAPITwoDemoApp
//
//  Created by Armaan Bindra on 3/7/17.
//  Copyright © 2017 Armaan Bindra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "CameraViewController.h"
@import MobileCoreServices;



@interface VoiceItAPITwo : NSObject <AVAudioRecorderDelegate, AVAudioPlayerDelegate>
typedef enum { enrollment, verification, identification } RecordingType;
// Properties
@property (nonatomic, strong) NSString *apiKey;
@property (nonatomic, strong) NSString *apiToken;
@property (nonatomic, strong) NSString *authHeader;
@property (nonatomic, strong) NSString *uniqueId;
@property (nonatomic, strong) NSString *recordingFilePath;
@property (nonatomic, strong) NSData *photoData;
@property (nonatomic, strong) NSString *contentLanguage;
@property (nonatomic, strong) NSString *boundary;
@property (nonatomic, strong) AVAudioRecorder * recorder;
@property (nonatomic, strong) UIViewController * masterViewController;
@property (nonatomic, copy) void (^audioEnrollmentCompleted)(NSString * result);
@property (nonatomic, copy) void (^videoEnrollmentCompleted)(NSString * result);
@property (nonatomic, copy) void (^audioVerificationCompleted)(NSString * result);
@property (nonatomic, copy) void (^videoVerificationCompleted)(NSString * result);
@property (nonatomic, copy) void (^audioIdentificationCompleted)(NSString * result);
@property (nonatomic, copy) void (^videoIdentificationCompleted)(NSString * result);
@property (nonatomic, copy) void (^recordingCompleted)();

@property RecordingType recType;

#pragma mark - Constructor
- (id)init:(UIViewController *)masterViewController apiKey:(NSString *)apiKey apiToken:(NSString *) apiToken;

#pragma mark - User API Calls
- (void)getAllUsers:(void (^)(NSString *))callback;
- (void)createUser:(void (^)(NSString *))callback;
- (void)getUser:(NSString *)userId callback:(void (^)(NSString *))callback;
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
- (void)deleteEnrollmentsForUser:(NSString *)userId enrollmentId:(NSString *)enrollmentId callback:(void (^)(NSString *))callback;
- (void)createAudioEnrollment:(NSString *)userId contentLanguage:(NSString*)contentLanguage callback:(void (^)(NSString *))callback recordingFinished:(void (^)(void))recordingFinished;
- (void)createVideoEnrollment:(NSString *)userId contentLanguage:(NSString*)contentLanguage callback:(void (^)(NSString *))callback recordingFinished:(void (^)(void))recordingFinished;
#pragma mark - Verification API Calls
- (void)audioVerification:(NSString *)userId contentLanguage:(NSString*)contentLanguage callback:(void (^)(NSString *))callback recordingFinished:(void (^)(void))recordingFinished;
- (void)videoVerification:(NSString *)userId contentLanguage:(NSString*)contentLanguage callback:(void (^)(NSString *))callback recordingFinished:(void (^)(void))recordingFinished;

#pragma mark - Identification API Calls
- (void)audioIdentification:(NSString *)groupId contentLanguage:(NSString*)contentLanguage callback:(void (^)(NSString *))callback recordingFinished:(void (^)(void))recordingFinished;
- (void)videoIdentification:(NSString *)groupId contentLanguage:(NSString*)contentLanguage callback:(void (^)(NSString *))callback recordingFinished:(void (^)(void))recordingFinished;

@end
