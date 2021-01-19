//
//  Utilities.m
//  VoiceIt2-IosSDK
//
//  Created by VoiceIt Technologies, LLC
//  Copyright (c) 2020 VoiceIt Technologies, LLC. All rights reserved.
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
    NSURL * bundleURL = [[podBundle resourceURL] URLByAppendingPathComponent:@"VoiceIt2-IosSDK.bundle"];
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

+(NSString *)pathForTemporaryMergedFileWithSuffix:(NSString *)suffix
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

+(void) mergeAudio:(NSString *) audURL withVideo:(NSString *) vidURL andSaveToPathUrl:(NSString *) savePath completion:(void (^)(void))completionBlock{
    //Create AVMutableComposition Object which will hold our multiple       AVMutableCompositionTrack or we can say it will hold our video and audio files.
    AVMutableComposition* mixComposition = [AVMutableComposition composition];

    //Now first load your audio file using AVURLAsset. Make sure you give the correct path of your videos.
    NSURL *audio_url = [NSURL fileURLWithPath: audURL];
    AVURLAsset* audioAsset = [[AVURLAsset alloc]initWithURL:audio_url options:nil];
    CMTimeRange audio_timeRange = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);
    NSLog(@"audio_url: %@", audio_url);
    NSLog(@"audioAsset: %@", audioAsset);
    NSLog(@"audio_timeRange: %f",  CMTimeGetSeconds(audio_timeRange.duration));
    
    //Now we are creating the first AVMutableCompositionTrack containing our audio and add it to our AVMutableComposition object.
    AVMutableCompositionTrack *b_compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [b_compositionAudioTrack insertTimeRange:audio_timeRange ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];

    //Now we will load video file.
    NSURL *video_url = [NSURL fileURLWithPath: vidURL];;
    AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:video_url options:nil];
    CMTimeRange video_timeRange = CMTimeRangeMake(kCMTimeZero,audioAsset.duration);
    NSLog(@"video_url: %@", video_url);
    NSLog(@"videoAsset: %@", videoAsset);
    NSLog(@"video_timeRange: %f", CMTimeGetSeconds(video_timeRange.duration));
    NSLog(@"array count => %d",[videoAsset tracksWithMediaType:AVMediaTypeVideo].count);

    AVAssetTrack *assetVideoTrack = [videoAsset tracksWithMediaType:AVMediaTypeVideo].lastObject;
        
    //Now we are creating the second AVMutableCompositionTrack containing our video and add it to our AVMutableComposition object.
    AVMutableCompositionTrack *a_compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [a_compositionVideoTrack insertTimeRange:video_timeRange ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    
    if (assetVideoTrack && a_compositionVideoTrack) {
       [a_compositionVideoTrack setPreferredTransform:assetVideoTrack.preferredTransform];
    }

    //decide the path where you want to store the final video created with audio and video merge.ß
    NSURL *outputFileUrl = [NSURL fileURLWithPath:savePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:savePath])
        [[NSFileManager defaultManager] removeItemAtPath:savePath error:nil];

    //Now create an AVAssetExportSession object that will save your final video at specified path.
    AVAssetExportSession* _assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    _assetExport.outputFileType = @"com.apple.quicktime-movie";
    _assetExport.outputURL = outputFileUrl;

    [_assetExport exportAsynchronouslyWithCompletionHandler:
     ^(void ) {
         dispatch_async(dispatch_get_main_queue(), ^{
             completionBlock();
         });
     }
     ];
}

@end
