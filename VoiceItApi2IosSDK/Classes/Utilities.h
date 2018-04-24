//
//  Utilities.h
//  TestingVoiceItAPI2iOSSDKCode
//
//  Created by Armaan Bindra on 10/2/17.
//  Copyright © 2017 VoiceIt Technologies LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@interface Utilities : NSObject
+(UIColor *)getGreenColor;
+(UIColor *)uiColorFromHexString:(NSString *)hexString;
+(CGColorRef)cgColorFromHexString:(NSString *)hexString;
+(NSDictionary *)getJSONObject:(NSString *)jsonString;
+(BOOL)isStrSame:(NSString *)firstString secondString:(NSString *) secondString;
//+(void)savePhotoToPhotos:(UIImage *)thePhoto;
+(NSData *)imageFromVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time;
+(NSDictionary *)getRecordingSettings;
+(UIStoryboard *)getVoiceItStoryBoard;

@end
