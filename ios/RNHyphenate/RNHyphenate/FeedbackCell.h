//
//  FeedbackCell.h
//  heartsquareapp
//
//  Created by Youssef on 2017/1/5.
//  Copyright © 2017年 HeartSquare. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EMSDK.h"

@class FeedbackCell;

@protocol FeedbackCellDelegate <NSObject>
- (void)resendMessage:(FeedbackCell *)cell;
@end

@interface FeedbackCell : UITableViewCell
@property (nonatomic, strong) UIImageView * headImage;
@property (nonatomic, strong) UIImageView * cellBackImage;
@property (nonatomic, strong) UILabel * contentLabel;

@property (nonatomic, weak) id<FeedbackCellDelegate> cellDelegate;
@property (nonatomic, strong) EMMessage * message;

- (void)adjustHeightWithMessage:(EMMessage *)message;

- (void)showResendButton:(BOOL)showed;

- (void)isLoading:(BOOL)isloading;

- (void)fecthRectWithText:(NSString *)text andMessage:(EMMessage *)message;
- (void)fecthRectWithImage:(UIImage *)image andMessage:(EMMessage *)message;
@end
