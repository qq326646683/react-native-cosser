//
//  NSString+ComputerRect.m
//  heartsquareapp
//
//  Created by Youssef on 16/4/18.
//  Copyright © 2016年 HeartSquare. All rights reserved.
//

#import "NSString+ComputerRect.h"

@implementation NSString (ComputerRect)

- (CGRect)boundingRectWithSize:(CGSize)size andFont:(UIFont *)font {
    CGRect rect = [self boundingRectWithSize:size
                                         options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                      attributes:@{NSFontAttributeName : font}
                                         context:nil];
    return rect;
}

- (CGRect)boundingRectWithSize:(CGSize)size andSystemFontOfSize:(CGFloat)systemFontSize {
    return [self boundingRectWithSize:size andFont:[UIFont systemFontOfSize:systemFontSize]];
}

- (CGFloat)boundingWidthWithSize:(CGSize)size andSystemFontOfSize:(CGFloat)systemFontSize {
    return ceilf(CGRectGetWidth([self boundingRectWithSize:size andSystemFontOfSize:systemFontSize]));
}

- (CGFloat)boundingHeightWithSize:(CGSize)size andSystemFontOfSize:(CGFloat)systemFontSize {
    return ceilf(CGRectGetHeight([self boundingRectWithSize:size andSystemFontOfSize:systemFontSize]));
}

- (CGRect)boundingRectWithSize:(CGSize)size andBoldSystemFontOfSize:(CGFloat)systemFontSize {
    return [self boundingRectWithSize:size andFont:[UIFont boldSystemFontOfSize:systemFontSize]];
}

- (CGFloat)boundingWidthWithSize:(CGSize)size andBoldSystemFontOfSize:(CGFloat)systemFontSize {
    return ceilf(CGRectGetWidth([self boundingRectWithSize:size andSystemFontOfSize:systemFontSize]));
}

- (CGFloat)boundingHeightWithSize:(CGSize)size andBoldSystemFontOfSize:(CGFloat)systemFontSize {
    return ceilf(CGRectGetHeight([self boundingRectWithSize:size andSystemFontOfSize:systemFontSize]));
}

@end
