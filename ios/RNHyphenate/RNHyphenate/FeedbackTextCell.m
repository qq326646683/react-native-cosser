//
//  FeedbackTextCell.m
//  heartsquareapp
//
//  Created by Youssef on 2017/1/5.
//  Copyright © 2017年 HeartSquare. All rights reserved.
//

#import "FeedbackTextCell.h"

@implementation FeedbackTextCell

- (void)adjustHeightWithMessage:(EMMessage *)message {
    EMTextMessageBody * body = (EMTextMessageBody *)message.body;
    if (body.text.length > 0 || [body.text isEqual:@" "]) {
        [self fecthRectWithText:body.text andMessage:message];
    }
}

@end
