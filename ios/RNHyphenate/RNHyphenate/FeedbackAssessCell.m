//
//  FeedbackAssessCell.m
//  heartsquareapp
//
//  Created by Youssef on 2017/1/5.
//  Copyright © 2017年 HeartSquare. All rights reserved.
//

#import "FeedbackAssessCell.h"

@interface FeedbackAssessCell ()
@property (nonatomic, copy) NSString * serviceSessionId;
@property (nonatomic, copy) NSNumber * inviteId;
@end

@implementation FeedbackAssessCell

- (void)adjustHeightWithMessage:(EMMessage *)message {
    EMMessageBody * body = message.body;
    if (message.ext != nil && message.direction == EMMessageDirectionReceive) {
        NSDictionary * weichat = [message.ext objectForKey:@"weichat"];
        NSString * ctrlType = [weichat objectForKey:@"ctrlType"];
        if (ctrlType != [NSNull null]) {//不要问我为什么用NSNull，环信的SB后台传过来就是这个
            NSDictionary * ctrlArgs = [weichat objectForKey:@"ctrlArgs"];
            self.serviceSessionId = [ctrlArgs objectForKey:@"serviceSessionId"];
            self.inviteId = [ctrlArgs objectForKey:@"inviteId"];
            
            CGRect contentRect = CGRectMake(12,10,170,20);
            
            //改label得高度
            UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.frame = contentRect;
            button.titleLabel.font = [UIFont boldSystemFontOfSize:15];
            [button setTitle:@"请您对本次服务进行评价" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(onButtonTap:) forControlEvents:UIControlEventTouchUpInside];
            [self.cellBackImage addSubview:button];
            
            //改背景图高度
            CGRect backFrame = self.cellBackImage.frame;
            backFrame.size.height = contentRect.size.height + 20;
            
            //改背景图宽度，需要先判断是谁回复的
            backFrame.size.width = contentRect.size.width + 25;
            self.cellBackImage.frame = backFrame;
            
            //改头像位置，放在消息底部
            CGRect head = self.headImage.frame;
            head.origin.y = 5;
            
            self.headImage.frame = head;
            return ;
        }
    }
}

- (void)onButtonTap:(UIButton *)button {
    button.enabled = NO;
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.delegate evaluateTapped:self.inviteId andServiceSessionId:self.serviceSessionId andWhichButton:button];
}

@end
