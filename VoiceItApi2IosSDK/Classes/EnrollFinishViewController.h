//
//  EnrollFinishViewController.h
//  VoiceItApi2IosSDK
//
//  Created by VoiceIt Technolopgies, LLC on 10/4/17.
//  Copyright © 2017 VoiceIt Technologies LLC. All rights reserved.
//

#import "MainNavigationController.h"

@interface EnrollFinishViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *enrollmentFinishTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *enrollmentFinishSubtitleLabel;
@property (strong, nonatomic)  MainNavigationController * myNavController;
@end
