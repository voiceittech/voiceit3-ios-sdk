//
//  SpinningView.m
//  VoiceItApi2IosSDK
//
//  Created by VoiceIt Technolopgies, LLC on 10/4/17.
//  Copyright © 2017 VoiceIt Technologies LLC. All rights reserved.
//

#import "SpinningView.h"
#import "Utilities.h"
#import "Styles.h"

@implementation SpinningView
- (id)initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder;
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.circleLayer = [[CAShapeLayer alloc] init];
    self.circleLayer.lineWidth = 8;
    self.circleLayer.fillColor = nil;
    self.circleLayer.strokeColor = [Styles getMainCGColor];
    [[self layer] addSublayer:self.circleLayer];
    NSLog(@"Setup Finished");
}

-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    if(flag){
        [self startAnimation];
    }
}

-(void)drawRightCircle {
    CGFloat radius = 100;
    
    CGFloat starttime = M_PI/6; //1 pm = 1/6 rad
    CGFloat endtime = M_PI;  //6 pm = 1 rad
    
    //draw arc
    CGPoint center = CGPointMake(radius,radius);
    UIBezierPath *arc = [UIBezierPath bezierPath]; //empty path
    [arc moveToPoint:center];
    CGPoint next;
    next.x = center.x + radius * cos(starttime);
    next.y = center.y + radius * sin(starttime);
    [arc addLineToPoint:next]; //go one end of arc
    [arc addArcWithCenter:center radius:radius startAngle:starttime endAngle:endtime clockwise:YES]; //add the arc
    [arc addLineToPoint:center]; //back to center
    
    [[UIColor yellowColor] set];
    [arc fill];
}

-(void)startAnimation{
    CABasicAnimation * inAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    [inAnimation setFromValue: [NSNumber numberWithFloat:0.0]];
    [inAnimation setToValue:[NSNumber numberWithFloat:1.0]];
    [inAnimation setDuration:2.0];
    [inAnimation setTimingFunction:[CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseIn]];
    
    CABasicAnimation * outAnimation = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
    [outAnimation setBeginTime:1.0];
    [outAnimation setFromValue: [NSNumber numberWithFloat:0.0]];
    [outAnimation setToValue:[NSNumber numberWithFloat:1.0]];
    [outAnimation setDuration:2.0];
    [outAnimation setTimingFunction:[CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseOut]];
    
    [self.circleLayer removeAnimationForKey:@"strokeAnimation"];
    CAAnimationGroup * strokeAnimationGroup = [CAAnimationGroup animation];
    [strokeAnimationGroup setDuration:2.0 + [outAnimation beginTime] ];
    [strokeAnimationGroup setRepeatCount:MAXFLOAT];
    [strokeAnimationGroup setAnimations: [[NSArray alloc] initWithObjects:inAnimation, outAnimation, nil]];
    [self.circleLayer addAnimation:strokeAnimationGroup forKey:@"strokeAnimation"];
    [strokeAnimationGroup setDelegate:self];
}

-(void)endAnimation{
    [self.circleLayer removeAllAnimations];
}

-(void)layoutSubviews{
    [super layoutSubviews];
    // Code to Build Basic Circle
    CGFloat yPoint = [self frame].size.height * 0.75;
    CGPoint bottomPoint = CGPointMake([self center].x, yPoint );
    CGFloat radius = 75.0 / 2 - self.circleLayer.lineWidth /2;
    CGFloat startAngle = M_PI_2;
    CGFloat endAngle = startAngle + (M_PI * 2);
    UIBezierPath * path = [UIBezierPath bezierPathWithArcCenter:CGPointZero radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
    [self.circleLayer setPosition:bottomPoint];
    [self.circleLayer setPath:[path CGPath]];
    [self startAnimation];
    CABasicAnimation * rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    [rotationAnimation setFromValue: [NSNumber numberWithFloat: 0]];
    [rotationAnimation setToValue:[NSNumber numberWithFloat: 2 * M_PI]];
    [rotationAnimation setDuration:4.0];
    [rotationAnimation setRepeatCount:MAXFLOAT];
    [self.circleLayer addAnimation: rotationAnimation forKey:@"rotateAnimation"];
}

-(void)awakeFromNib{
    [super awakeFromNib];
    [self setup];
}
@end
