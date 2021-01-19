//
//  SpinningView.h
//  VoiceIt2-IosSDK
//
//  Created by VoiceIt Technologies, LLC
//  Copyright (c) 2020 VoiceIt Technologies, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SpinningView : UIView <CAAnimationDelegate>
@property (nonatomic, strong) CAShapeLayer * circleLayer;
-(void)startAnimation;
-(void)endAnimation;
@end
