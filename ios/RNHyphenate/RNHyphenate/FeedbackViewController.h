//
//  FeedbackViewController.h
//  heartsquareapp
//
//  Created by Youssef on 15/12/15.
//  Copyright © 2015年 HeartSquare. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIColor+Hex.h"
#import "EMSDK.h"

@interface FeedbackViewController : UIViewController
@property (nonatomic, strong) UITableView * tableView;
@property (nonatomic, copy) NSMutableArray * datas;

//收到本地推送后的操作
+ (void)didReceiveLocalNotification;

//发送本地推送
+ (void)showNotificationWithMessage:(EMMessage *)message;

//震动以及提示音
+ (void)playSoundAndVibration;
@end
