//
//  AppTool.m
//  HyphenatePluginDemo
//
//  Created by Youssef on 2017/1/6.
//  Copyright © 2017年 yunio. All rights reserved.
//

#import "AppTool.h"
#import "Reachability.h"

@implementation AppTool
+ (UIImage *)circleImage:(UIImage *)image Radius:(CGFloat)radius Size:(CGSize)size {
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIBezierPath * path = [[UIBezierPath alloc] init];
    if (size.height == size.width) {
        if (radius == size.width/2) {
            path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(size.width/2, size.height/2) radius:radius startAngle:0 endAngle:2.0*M_PI clockwise:YES];
        }else {
            path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius];
        }
    }else {
        path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius];
    }
    CGContextAddPath(context, path.CGPath);
    CGContextClip(context);
    [image drawInRect:rect];
    
    UIImage * uncompressedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    if (uncompressedImage) {
        return uncompressedImage;
    }else {
        return nil;
    }
}

+ (UIViewController *)getCurrentViewController {
    UIViewController * result = [[UIViewController alloc] init];
    
    UIWindow * window = [UIApplication sharedApplication].keyWindow;
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray * windows = [UIApplication sharedApplication].windows;
        for (UIWindow * temp in windows) {
            if (temp.windowLevel == UIWindowLevelNormal) {
                window = temp;
                break;
            }
        }
    }
    
    UIViewController * appRootVC = window.rootViewController;
    if (appRootVC) {
        UIView * frontView = window.subviews.firstObject;
        if (frontView) {
            id nextResponder = frontView.nextResponder;
            if ([appRootVC presentedViewController]) {
                nextResponder = appRootVC.presentedViewController;
            }
            if ([nextResponder isKindOfClass:[UITabBarController class]]) {
                UITabBarController * tabbar = (UITabBarController *)nextResponder;
                UINavigationController * nav = (UINavigationController *)tabbar.viewControllers[tabbar.selectedIndex];
                result = nav.childViewControllers.lastObject;
            }else if ([nextResponder isKindOfClass:[UINavigationController class]]) {
                UINavigationController * nav = (UINavigationController *)nextResponder;
                result = nav.childViewControllers.lastObject;
            }else {
                if (![nextResponder isKindOfClass:[UIView class]]) {
                    result = nextResponder;
                }
            }
        }
    }
    
    return result;
}

+ (int)getSystemVersion {
    NSArray * numbers = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    NSString * version = [NSString stringWithFormat:@"%@", numbers.firstObject];
    return version.intValue;
}

//判断网络状态
+ (BOOL)hasInternet {
    if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"您的网络连接已断开" message:nil delegate:self cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alert show];
        return NO;
    }else {
        return YES;
    }
}

+ (NSString *)FBlocalizedString:(NSString *)key AndComment:(NSString *)comment {
    
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Root" ofType:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    return [bundle localizedStringForKey:key value:nil table:@"Root"];
//    return NSLocalizedStringWithDefaultValue(key, @"FeedbackPlist", [NSBundle mainBundle], @"", comment);
}

+ (UIImage *)getImageWithResource:(NSString *)resource
{
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Root" ofType:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    NSString *path = [bundle pathForResource:resource ofType:@""];
    
    return [UIImage imageWithContentsOfFile:path];
}

@end
