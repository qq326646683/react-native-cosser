//
//  NSString+ComputerRect.h
//  heartsquareapp
//
//  Created by Youssef on 16/4/18.
//  Copyright © 2016年 HeartSquare. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSString (ComputerRect)

- (CGRect)boundingRectWithSize:(CGSize)size andFont:(UIFont *)font;

//systemFontOfSize
- (CGRect)boundingRectWithSize:(CGSize)size andSystemFontOfSize:(CGFloat)systemFontSize;
- (CGFloat)boundingWidthWithSize:(CGSize)size andSystemFontOfSize:(CGFloat)systemFontSize;
- (CGFloat)boundingHeightWithSize:(CGSize)size andSystemFontOfSize:(CGFloat)systemFontSize;

//boldSystemFontOfSize
- (CGRect)boundingRectWithSize:(CGSize)size andBoldSystemFontOfSize:(CGFloat)systemFontSize;
- (CGFloat)boundingWidthWithSize:(CGSize)size andBoldSystemFontOfSize:(CGFloat)systemFontSize;
- (CGFloat)boundingHeightWithSize:(CGSize)size andBoldSystemFontOfSize:(CGFloat)systemFontSize;

@end
