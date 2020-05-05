//
//  SpinningView.h
//  VoiceItApi2IosSDK
//
//  Created by VoiceIt Technolopgies, LLC on 10/4/17.
//  Copyright © 2017 VoiceIt Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SpinningView : UIView <CAAnimationDelegate>
@property (nonatomic, strong) CAShapeLayer * circleLayer;
-(void)startAnimation;
-(void)endAnimation;
@end
