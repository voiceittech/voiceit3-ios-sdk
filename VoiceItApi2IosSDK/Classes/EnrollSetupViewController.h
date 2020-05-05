//
//  EnrollSetupViewController.h
//  VoiceItApi2IosSDK
//
//  Created by VoiceIt Technolopgies, LLC on 10/2/17.
//  Copyright © 2017 VoiceIt Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "SpinningView.h"
#import "Utilities.h"
#import "Styles.h"

#import "MainNavigationController.h"
#import "VoiceEnrollmentViewController.h"
#import "FaceEnrollmentViewController.h"
#import "VideoEnrollmentViewController.h"

@interface EnrollSetupViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *enrollmentSetupTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *enrollmentSetupSubtitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *continueButton;
@property (strong, nonatomic)  MainNavigationController * myNavController;
@end

