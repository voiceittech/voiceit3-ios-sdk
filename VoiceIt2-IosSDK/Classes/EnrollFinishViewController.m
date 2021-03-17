//
//  EnrollFinishViewController.m
//  VoiceIt2-IosSDK
//
//  Created by VoiceIt Technologies, LLC 
//  Copyright © 2020 VoiceIt Technologies LLC. All rights reserved.
//

#import "EnrollFinishViewController.h"
#import "Styles.h"
@interface EnrollFinishViewController ()
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@end

@implementation EnrollFinishViewController

#pragma mark - Life Cycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.doneButton setBackgroundColor:[Styles getMainUIColor]];
    self.myNavController = (MainNavigationController*) [self navigationController];
    [self.navigationItem setHidesBackButton: YES];
    
    self.doneButton.layer.cornerRadius = 10.0;
    [self.doneButton setTitle:[ResponseManager getMessage:@"DONE"] forState:UIControlStateNormal];
    
    switch (self.myNavController.enrollmentType) {
        case video:
            [self.enrollmentFinishTitleLabel setText:[ResponseManager getMessage:@"VOICE_FACE_READY"]];
            [self.enrollmentFinishSubtitleLabel setText:[ResponseManager getMessage:@"VOICE_FACE_READY_SUBTITLE"]];
            break;
        case face:
            [self.enrollmentFinishTitleLabel setText:[ResponseManager getMessage:@"FACE_READY"]];
            [self.enrollmentFinishSubtitleLabel setText:[ResponseManager getMessage:@"FACE_READY_SUBTITLE"]];
            break;
        case voice:
            [self.enrollmentFinishTitleLabel setText:[ResponseManager getMessage:@"VOICE_READY"]];
            [self.enrollmentFinishSubtitleLabel setText:[ResponseManager getMessage:@"VOICE_READY_SUBTITLE"]];
            break;
        default:
            break;
    }
}

#pragma mark - Action Methods

- (IBAction)doneButtonClicked:(id)sender {
    [[self navigationController] dismissViewControllerAnimated:YES completion:^{
//        [self.myNavController userEnrollmentsPassed](self.response);
    }];
    // TODO: Give Successful Enrollment Completion Notification/Callback Here
}

@end
