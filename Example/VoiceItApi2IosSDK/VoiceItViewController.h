//
//  VoiceItViewController.h
//  VoiceItApi2IosSDK
//
//  Created by VoiceIt Technologies, LLC on 03/23/2017.
//  Copyright (c) 2017 VoiceIt Technologies, LLC. All rights reserved.
//

@import UIKit;
#import "VoiceItAPITwo.h"

@interface VoiceItViewController : UIViewController<UIPickerViewDelegate,UIPickerViewDataSource>
@property VoiceItAPITwo * myVoiceIt;
@property (weak, nonatomic) IBOutlet UISwitch *livenessToggle;
@property (weak, nonatomic) IBOutlet UISwitch *audioPromptsToggle;
@property NSString * API_KEY;
@property NSString * API_TOKEN;
@property NSString * TEST_USER_ID_ONE;
@property NSString * TEST_USER_ID_TWO;
@property NSString * TEST_USER_ID;
@property NSString * TEST_GROUP_ID;
@property NSString * TEST_PHRASE;
@property NSString * TEST_CONTENT_LANGUAGE;
@end
