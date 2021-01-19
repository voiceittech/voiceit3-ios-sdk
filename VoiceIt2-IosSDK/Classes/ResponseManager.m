//
//  ResponseManager.m
//  VoiceIt2-IosSDK
//
//  Created by VoiceIt Technologies, LLC
//  Copyright (c) 2020 VoiceIt Technologies, LLC. All rights reserved.
//

#import "ResponseManager.h"

@implementation ResponseManager
+(NSString *)getMessage:(NSString*) name{
    NSBundle * podBundle = [NSBundle bundleForClass: self.classForCoder];
    NSURL * bundleURL = [[podBundle resourceURL] URLByAppendingPathComponent:@"VoiceIt2-IosSDK.bundle"];
    NSBundle  * bundle = [[NSBundle alloc] initWithURL:bundleURL];
    NSString *finalString = NSLocalizedStringFromTableInBundle(name, @"Prompts", bundle, nil);
    //    NSString *finalString = NSLocalizedString(name, nil);
    return finalString;
}

+(NSString *)getMessage:(NSString*) name variable:(NSString*)variable{
    NSBundle * podBundle = [NSBundle bundleForClass: self.classForCoder];
    NSURL * bundleURL = [[podBundle resourceURL] URLByAppendingPathComponent:@"VoiceIt2-IosSDK.bundle"];
    NSBundle  * bundle = [[NSBundle alloc] initWithURL:bundleURL];
    NSString *finalString = [[NSString alloc] initWithFormat: NSLocalizedStringFromTableInBundle(name, @"Prompts", bundle, nil) ,variable];
    return finalString;
}
@end
