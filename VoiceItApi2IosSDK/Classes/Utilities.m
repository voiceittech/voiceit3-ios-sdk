//
//  Utilities.m
//  VoiceItApi2IosSDK
//
//  Created by VoiceIt Technolopgies, LLC on 10/2/17.
//  Copyright © 2017 VoiceIt Technologies LLC. All rights reserved.
//

#import "Utilities.h"
#import "Styles.h"

@implementation Utilities

/* Utility Methods */
+(UIColor *)uiColorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

+(UIColor *)getGreenColor {
    return [UIColor colorWithRed:39.0f/255.0f
                           green:174.0f/255.0f
                            blue:96.0f/255.0f
                           alpha:1.0f];
}

+(UIStoryboard *)getVoiceItStoryBoard{
    NSBundle * podBundle = [NSBundle bundleForClass: self.classForCoder];
    NSURL * bundleURL = [[podBundle resourceURL] URLByAppendingPathComponent:@"VoiceItApi2IosSDK.bundle"];
    NSBundle  * bundle = [[NSBundle alloc] initWithURL:bundleURL];
    UIStoryboard *voiceItStoryboard = [UIStoryboard storyboardWithName:@"VoiceIt" bundle: bundle];
    return voiceItStoryboard;
}

+(NSDictionary *)getRecordingSettings {
    NSDictionary *recordSettings = [[NSDictionary alloc]
                                    initWithObjectsAndKeys:
                                    [NSNumber numberWithFloat:44100.0], AVSampleRateKey,
                                    [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                    [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
                                    [NSNumber numberWithInt:2], AVNumberOfChannelsKey,
                                    [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
                                    [NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,
                                    nil];
    return recordSettings;
}

+(CGColorRef)cgColorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0].CGColor;
}

+(NSDictionary *)getJSONObject:(NSString *)jsonString {
    NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *jsonObj = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    return jsonObj;
}

+(BOOL)isStrSame:(NSString *)firstString secondString:(NSString *) secondString{
    return [[firstString lowercaseString] isEqualToString:[secondString lowercaseString]];
}

+(NSData *)imageFromVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time {
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    NSParameterAssert(asset);
    AVAssetImageGenerator *assetIG =
    [[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetIG.appliesPreferredTrackTransform = YES;
    assetIG.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    CGImageRef thumbnailImageRef = NULL;
    CFTimeInterval thumbnailImageTime = time;
    NSError *igError = nil;
    thumbnailImageRef =
    [assetIG copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 60)
                    actualTime:NULL
                         error:&igError];
    
    if (!thumbnailImageRef){
        NSLog(@"thumbnailImageGenerationError %@", igError );
    }
    
    UIImage *image = thumbnailImageRef ? [[UIImage alloc] initWithCGImage:thumbnailImageRef] : nil;
    NSData *imageData = nil;
    if ( image != nil){
        imageData  = UIImageJPEGRepresentation(image, 0.5);
    }
    return imageData;
}

+(NSString *)pathForTemporaryFileWithSuffix:(NSString *)suffix
{
    NSString *  result;
    CFUUIDRef   uuid;
    CFStringRef uuidStr;
    
    uuid = CFUUIDCreate(NULL);
    assert(uuid != NULL);
    
    uuidStr = CFUUIDCreateString(NULL, uuid);
    assert(uuidStr != NULL);
    
    result = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", uuidStr, suffix]];
    assert(result != nil);
    
    CFRelease(uuidStr);
    CFRelease(uuid);
    
    return result;
}

+(void)deleteFile:(NSString *)filePath{
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:filePath
                                                   error:nil];
    }
}
    
+(void)setupFaceRectangle:(CALayer *)faceRectangleLayer{
    faceRectangleLayer = [[CALayer alloc] init];
    faceRectangleLayer.zPosition = 1;
    faceRectangleLayer.borderColor = [Styles getMainCGColor];
    faceRectangleLayer.borderWidth  = 1.5;
    faceRectangleLayer.opacity = 0.5;
    [faceRectangleLayer setHidden:YES];
}
    
+(void)showFaceRectangle:(CALayer *)faceRectangleLayer face:(AVMetadataObject *)face {
    [faceRectangleLayer setHidden:NO];
    CGFloat padding = 20.0;
    CGFloat halfPadding = padding/3;
    CGRect faceRectangle = CGRectMake(face.bounds.origin.x - halfPadding, face.bounds.origin.y - halfPadding, face.bounds.size.width, face.bounds.size.height + padding);
    faceRectangleLayer.frame = faceRectangle;
    faceRectangleLayer.cornerRadius = 10.0;
}

+(void)setBottomCornersForCancelButton:(UIButton *)cancelButton{
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect: cancelButton.bounds byRoundingCorners:( UIRectCornerBottomLeft | UIRectCornerBottomRight) cornerRadii:CGSizeMake(10.0, 10.0)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = cancelButton.bounds;
    maskLayer.path  = maskPath.CGPath;
    cancelButton.layer.mask = maskLayer;
}

+(bool)isBadResponseCode:(NSString*) responseCode {
    NSArray* badResponseCodes = [[NSArray alloc] initWithObjects:@"MISP", @"UNFD", @"DDNE", @"IFAD", @"IFVD", @"GERR", @"DAID", @"UNAC", @"CLNE", @"ACLR", nil];
    if([badResponseCodes containsObject:responseCode]){
        return YES;
    }
    return NO;
}

+(CGFloat)normalizedPowerLevelFromDecibels:(AVAudioRecorder *)audioRecorder
{
    CGFloat decibels = [audioRecorder averagePowerForChannel:0];
    if (decibels < -60.0f || decibels == 0.0f) {
        return 0.0f;
    }
    return powf((powf(10.0f, 0.05f * decibels) - powf(10.0f, 0.05f * -60.0f)) * (1.0f / (1.0f - powf(10.0f, 0.05f * -60.0f))), 1.0f / 2.0f);
}
@end
