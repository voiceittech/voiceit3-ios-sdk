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
@property VoiceItAPITwo * myVoiceIt;
@end

@implementation VoiceItViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _myVoiceIt = [[VoiceItAPITwo alloc] init:self apiKey:@"key_4306d632525748ac987cc0385ceff339" apiToken:@"tok_c910f4047d1d425980c856bb3ca8fa5b"];
//    [_myVoiceIt getAllGroups:^(NSString * jsonResult){
//        NSLog(@"JSONResponse: %@", jsonResult);
//    }];
    
//    [_myVoiceIt getAllGroups:^(NSString * jsonResult){
//        NSLog(@"JSONResponse: %@", jsonResult);
//    }];
//    
//    [_myVoiceIt createGroup:@"A Sample Group Description" callback:^(NSString * jsonResult){
//        NSLog(@"JSONResponse: %@", jsonResult);
//    }];
//
//    [_myVoiceIt deleteUser:@"USER_ID_HERE" callback:^(NSString * jsonResult){
//        NSLog(@"JSONResponse: %@", jsonResult);
//    }];
//
//    [_myVoiceIt groupExists:@"grp_7a142d4f4eb54ce4b5b5b36911bcf2fc" callback:^(NSString * jsonResult){
//        NSLog(@"JSONResponse: %@", jsonResult);
//    }];

//    [_myVoiceIt getGroupsForUser:@"USER_ID_HERE" callback:^(NSString * jsonResult){
//        NSLog(@"JSONResponse: %@", jsonResult);
//    }];
    
//    [_myVoiceIt addUserToGroup:@"grp_GROUP_ID_HERE" userId:@"usr_USER_ID_HERE" callback:^(NSString * jsonResult){
//                NSLog(@"JSONResponse: %@", jsonResult);
//    }];
    
    [_myVoiceIt removeUserFromGroup:@"grp_GROUP_ID_HERE" userId:@"usr_USER_ID_HERE" callback:^(NSString * jsonResult){
        NSLog(@"JSONResponse: %@", jsonResult);
    }];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
