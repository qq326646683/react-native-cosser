//
//  FeedbackAssessCell.h
//  heartsquareapp
//
//  Created by Youssef on 2017/1/5.
//  Copyright © 2017年 HeartSquare. All rights reserved.
//

#import "FeedbackCell.h"

@protocol FeedbackAssessCellDelegate <NSObject>
- (void)evaluateTapped:(NSNumber *)inviteId andServiceSessionId:(NSString *)serviceSessionId andWhichButton:(UIButton *)button;
@end

@interface FeedbackAssessCell : FeedbackCell
@property (nonatomic, weak) id<FeedbackAssessCellDelegate> delegate;
@end
