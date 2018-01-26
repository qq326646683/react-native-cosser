//
//  AppTool.h
//  HyphenatePluginDemo
//
//  Created by Youssef on 2017/1/6.
//  Copyright © 2017年 yunio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppTool : NSObject
+ (UIImage *)circleImage:(UIImage *)image Radius:(CGFloat)radius Size:(CGSize)size;

+ (UIViewController *)getCurrentViewController;

+ (int)getSystemVersion;

+ (BOOL)hasInternet;

+ (NSString *)FBlocalizedString:(NSString *)key AndComment:(NSString *)comment;

+ (UIImage *)getImageWithResource:(NSString *)resource;
@end
