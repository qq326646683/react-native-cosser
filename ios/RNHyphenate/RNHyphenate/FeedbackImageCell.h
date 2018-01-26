//
//  FeedbackImageCell.h
//  heartsquareapp
//
//  Created by Youssef on 2017/1/5.
//  Copyright © 2017年 HeartSquare. All rights reserved.
//

#import "FeedbackCell.h"

@protocol FeedbackImageCellDelegate <NSObject>
- (void)showLargePhoto:(NSString *)imagePath;
@end

@interface FeedbackImageCell : FeedbackCell
@property (nonatomic, weak) id<FeedbackImageCellDelegate> delegate;
@end
