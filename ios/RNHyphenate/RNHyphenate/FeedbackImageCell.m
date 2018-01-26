//
//  FeedbackImageCell.m
//  heartsquareapp
//
//  Created by Youssef on 2017/1/5.
//  Copyright © 2017年 HeartSquare. All rights reserved.
//

#import "FeedbackImageCell.h"
#import "YNShappedImageView.h"

@interface FeedbackImageCell ()
@property (nonatomic, copy) NSString * imagePath;
@end

@implementation FeedbackImageCell

- (void)adjustHeightWithMessage:(EMMessage *)message {
    EMImageMessageBody * body = (EMImageMessageBody *)message.body;
    if (body.localPath) {
        _imagePath = body.localPath;
        UIImage * image = [UIImage imageWithContentsOfFile:body.localPath];
        if (image) {
            [self fecthRectWithImage:image andMessage:message];
            return ;
        }else {
            [self downloadImageWith:message];
            return ;
        }
    }else {
        [self downloadImageWith:message];
    }
}

- (void)downloadImageWith:(EMMessage *)message {
    __weak FeedbackImageCell * wself = self;
    [[[EMClient sharedClient] chatManager] downloadMessageAttachment:message progress:^(int progress) {
        
    } completion:^(EMMessage *message, EMError *error) {
        if (error == nil) {
            EMImageMessageBody * body = (EMImageMessageBody *)message.body;
            UIImage * image = [[UIImage alloc] initWithContentsOfFile:body.thumbnailLocalPath];
            [wself fecthRectWithImage:image andMessage:message];
        }else {
            NSLog(@"EMDownloadMessageAttachmentsError :%u %@", error.code, error.errorDescription);
        }
    }];
}

- (void)fecthRectWithImage:(UIImage *)image andMessage:(EMMessage *)message {
    [super fecthRectWithImage:image andMessage:message];
    if (message.direction == EMMessageDirectionSend) {
        YNShappedImageView * imageV = [[YNShappedImageView alloc] initWithFrame:CGRectMake(0, 0, self.cellBackImage.frame.size.width, self.cellBackImage.frame.size.height)];
        imageV.image = image;
        [imageV addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImageCell)]];
        [self.cellBackImage addSubview:imageV];
    }else {
        YNShappedImageView * imageV = [[YNShappedImageView alloc] initWithFrame:CGRectMake(0, 0, self.cellBackImage.frame.size.width, self.cellBackImage.frame.size.height) andShappImageName:@"message_bubble_white.png"];
        imageV.image = image;
        [imageV addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImageCell)]];
        [self.cellBackImage addSubview:imageV];
    }
}

- (void)tapImageCell {
    [self.delegate showLargePhoto:self.imagePath];
}

@end
