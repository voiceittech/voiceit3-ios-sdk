//
//  SimpleCamera+Helper.h
//  SimpleCameraExample
//
//  Created by Armaan Bindra on 3/16/17.
//  Copyright © 2017 Armaan Bindra. All rights reserved.

#import "SimpleCamera.h"

@interface SimpleCamera (Helper)

- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates
                                          previewLayer:(AVCaptureVideoPreviewLayer *)previewLayer
                                                 ports:(NSArray<AVCaptureInputPort *> *)ports;

- (UIImage *)cropImage:(UIImage *)image usingPreviewLayer:(AVCaptureVideoPreviewLayer *)previewLayer;

@end
