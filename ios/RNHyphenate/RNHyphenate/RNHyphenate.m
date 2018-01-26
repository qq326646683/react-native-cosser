//
//  RNHyphenate.m
//  RNHyphenate
//
//  Created by Zoey on 2017/12/26.
//  Copyright © 2017年 Web. All rights reserved.
//

#import "RNHyphenate.h"
#import "FeedbackViewController.h"
#import "MyHyphenate.h"

@implementation RNHyphenate


RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(setInfo:(NSString *)info)
{
    NSLog(@"我传过来的信息 %@", info);
    
    [MyHyphenate setupWithAppKey:@"1145170711178803#smallworld" imUser:@"july" userName:@"D4AADD8199A3-458B-BB7B-1C2F13DAB986" Password:@"littleworld1213" ApnsCertName:@"dev"];
    [MyHyphenate present:[UIApplication sharedApplication].keyWindow.rootViewController];
}

@end
