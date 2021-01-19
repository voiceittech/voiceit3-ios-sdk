//
//  EnrollFinishViewController.h
//  VoiceIt2-IosSDK
//
//  Created by VoiceIt Technologies, LLC
//  Copyright © 2020 VoiceIt Technologies LLC. All rights reserved.
//

#import "MainNavigationController.h"

@interface EnrollFinishViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *enrollmentFinishTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *enrollmentFinishSubtitleLabel;
@property (strong, nonatomic)  MainNavigationController * myNavController;
@end
