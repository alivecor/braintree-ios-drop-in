//
//  BTUIKVectorArtView+Utils.m
//  Pods
//
//  Created by rex hsu on 3/5/25.
//

#import "BTUIKVectorArtView+Utils.h"

@implementation BTUIKVectorArtView (Utils)

- (UIImage *)imageOfSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [self drawRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

@end
