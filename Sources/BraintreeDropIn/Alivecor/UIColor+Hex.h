//
//  UIColor+Hex.h
//  AliveECG
//
//  Created by Ned Fox on 10/15/13.
//  Copyright (c) 2013 AliveCor Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Hex)

+ (UIColor *)colorWithHex:(NSString *)hexString alpha:(CGFloat)alpha;

@end
