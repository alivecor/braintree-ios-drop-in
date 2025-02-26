//
//  UIColor+Hex.m
//  AliveECG
//
//  Created by Ned Fox on 10/15/13.
//  Copyright (c) 2013 AliveCor Inc. All rights reserved.
//

#import "UIColor+Hex.h"

@implementation UIColor (Hex)

static NSMutableDictionary<NSString *, UIColor *> *colors = nil;

+ (UIColor *)colorWithHex:(NSString *)hexString alpha:(CGFloat)alpha {
    // Initialize static dictionary with some basic translations
    if (!colors) {
        colors = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                 @"FFFFFF" : [UIColor whiteColor],
                                                                 @"000000" : [UIColor blackColor]
                                                                 }];
    }

    NSCharacterSet *poundSet = [NSCharacterSet characterSetWithCharactersInString:@"#"];
    
    NSString* trimmedHexString = [hexString stringByTrimmingCharactersInSet:poundSet];
    
    UIColor *color = colors[hexString];
    
    if (!color) {
        unsigned int hexInt = 0;
        NSScanner *scanner = [NSScanner scannerWithString:trimmedHexString];
        [scanner scanHexInt:&hexInt];
        
        // Create color object, specifying alpha as well
        color = [UIColor colorWithRed:((CGFloat) ((hexInt & 0xFF0000) >> 16))/255
                                green:((CGFloat) ((hexInt & 0xFF00) >> 8))/255
                                 blue:((CGFloat) (hexInt & 0xFF))/255
                                alpha:alpha];
        colors[trimmedHexString] = color;
    }
    
    return color;
}

@end
