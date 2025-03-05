//
//  UIImage+ImageWithColor.h
//  AliveECG
//
//  Created by Ned Fox on 6/9/14.
//  Copyright (c) 2014 AliveCor Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ImageWithColor)

+ (UIImage *)imageWithColor:(UIColor *)color;
+ (UIImage *)imageWithColor:(UIColor *)color frame:(CGRect)rect;

@end
