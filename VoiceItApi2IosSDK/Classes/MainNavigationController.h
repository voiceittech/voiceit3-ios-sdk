//
//  MainNavigationController.h
//  VoiceItApi2IosSDK
//
//  Created by VoiceIt Technolopgies, LLC on 10/2/17.
//  Copyright © 2017 VoiceIt Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Utilities.h"
#import "VoiceItAPITwo.h"

@interface MainNavigationController : UINavigationController
typedef enum { face, video, voice } EnrollmentType;
@property (nonatomic, strong) NSObject * myVoiceIt;
@property NSString * uniqueId;
@property NSString* contentLanguage;
@property NSString* voicePrintPhrase;
@property (nonatomic, copy) void (^userEnrollmentsCancelled)(void);
@property (nonatomic, copy) void (^userEnrollmentsPassed)(void);
@property EnrollmentType enrollmentType;
@end

