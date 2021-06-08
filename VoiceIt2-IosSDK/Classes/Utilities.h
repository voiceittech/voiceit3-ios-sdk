//
//  Utilities.h
//  VoiceIt2-IosSDK
//
//  Created by VoiceIt Technologies, LLC
//  Copyright (c) 2020 VoiceIt Technologies, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#define MAX_TIME_TO_WAIT_TILL_FACE_FOUND 5
#define ENROLLMENT_BACKGROUND_VIEW_Y 110.0
#define VERIFICATION_BACKGROUND_VIEW_Y 30.0

@interface Utilities : NSObject
+(UIColor *)getGreenColor;
+(UIColor *)uiColorFromHexString:(NSString *)hexString;
+(CGColorRef)cgColorFromHexString:(NSString *)hexString;
+(NSDictionary *)getJSONObject:(NSString *)jsonString;
+(BOOL)isStrSame:(NSString *)firstString secondString:(NSString *) secondString;
+(BOOL)checkNetwork;
+(BOOL) checkUserId: (NSString *) userId;
+(NSData *)imageFromVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time;
+(NSDictionary *)getRecordingSettings;
+(UIStoryboard *)getVoiceItStoryBoard;
+(NSString *)pathForTemporaryFileWithSuffix:(NSString *)suffix;
+(void)deleteFile:(NSString *)filePath;
+(void)setupFaceRectangle:(CALayer *)faceRectangleLayer;
+(void)showFaceRectangle:(CALayer *)faceRectangleLayer face:(AVMetadataObject *)face;
+(NSString*) getFirst:(NSString *)str numChars:(int)numChars;
+(void)setBottomCornersForCancelButton:(UIButton *)cancelButton;
+(bool)isBadResponseCode:(NSString*) responseCode;
+(CGFloat)normalizedPowerLevelFromDecibels:(AVAudioRecorder *)audioRecorder;
@end
