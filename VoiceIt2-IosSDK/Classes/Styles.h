//
//  Styles.h
//  VoiceIt2-IosSDK
//
//  Created by VoiceIt Technologies, LLC
//  Copyright (c) 2020 VoiceIt Technologies, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Utilities.h"

@interface Styles : NSObject
+(NSMutableDictionary *)get;
+(void)set:(NSMutableDictionary*)styleSettings;
+(NSString *)getMainColor;
+(UIColor *)getMainUIColor;
+(CGColorRef)getMainCGColor;
+(UIColor *)getIconUIColor;
@end

