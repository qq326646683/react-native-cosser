//
//  FeedbackFileCell.m
//  heartsquareapp
//
//  Created by Youssef on 2017/1/5.
//  Copyright © 2017年 HeartSquare. All rights reserved.
//

#import "FeedbackFileCell.h"
#import "VideoTool.h"
#import "AppTool.h"
#import <MediaPlayer/MediaPlayer.h>

@interface FeedbackFileCell ()
@property (nonatomic, copy) NSString * path;
@property (nonatomic, strong) EMMessage * fileMessage;
@end

@implementation FeedbackFileCell

- (void)adjustHeightWithMessage:(EMMessage *)message {
    EMFileMessageBody * body = (EMFileMessageBody *)message.body;
    _fileMessage = message;
    _path = body.localPath;
    [self judgeText:message];
}

- (void)downloadFile:(EMMessage *)message {
    __weak FeedbackFileCell * wself = self;
    [[[EMClient sharedClient] chatManager] downloadMessageAttachment:message progress:^(int progress) {
        NSLog(@"%d", progress);
    } completion:^(EMMessage *message, EMError *error) {
        if (error == nil) {
            [wself judgeText:message];
        }else {
            NSLog(@"EMDownloadMessageAttachments Error :%u %@ FilePath: %@", error.code, error.errorDescription, _path);
        }
    }];
}

- (void)downloadFileWithoutMessage {
    [self downloadFile:_fileMessage];
    dispatch_async(dispatch_get_main_queue(), ^{
        EMFileMessageBody * body = (EMFileMessageBody *)_fileMessage.body;
        [self fecthRectWithText:[NSString stringWithFormat:@"视频接收中，大小%@，请等待", [VideoTool getFileSizeWithByte: body.fileLength]] andMessage:_fileMessage];
    });
}


- (void)judgeText:(EMMessage *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        EMFileMessageBody * b = (EMFileMessageBody *)message.body;
        NSString * name = @"";
        if ([b.localPath containsString:@"LogArchive.zip"]) {
            name = @"日志";
        }else {
            name = @"视频";
            _path = b.localPath;
        }
        
        if (message.direction == EMMessageDirectionSend) {
            [self fecthRectWithText:[NSString stringWithFormat:@"%@发送成功", name] andMessage:message];
        }else {
            self.contentLabel.userInteractionEnabled = YES;
            for (UIGestureRecognizer * ge in self.contentLabel.gestureRecognizers) {
                if ([ge isKindOfClass:[UITapGestureRecognizer class]]) {
                    [self.contentLabel removeGestureRecognizer:ge];
                }
            }
            if (b.downloadStatus == EMDownloadStatusPending) {
                [self.contentLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(downloadFileWithoutMessage)]];
                [self fecthRectWithText:[NSString stringWithFormat:@"%@大小%@，点击接收", name, [VideoTool getFileSizeWithByte: b.fileLength]] andMessage:message];
            }else if (b.downloadStatus == EMDownloadStatusSuccessed){
                [self.contentLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onLabelTap)]];
                [self fecthRectWithText:[NSString stringWithFormat:@"%@接收成功，点击查看", name] andMessage:message];
            }else if (b.downloadStatus == EMDownloadStatusFailed) {
                [self.contentLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(downloadFileWithoutMessage)]];
                [self fecthRectWithText:[NSString stringWithFormat:@"%@接收失败，点击重试", name] andMessage:message];
            }else {
                [self fecthRectWithText:[NSString stringWithFormat:@"%@接收中，大小%@，请等待", name, [VideoTool getFileSizeWithByte: b.fileLength]] andMessage:message];
            }
            [self changeTextColor:b];
        }
    });
}

- (void)changeTextColor:(EMFileMessageBody *)body {
    if (body.downloadStatus == EMDownloadStatusDownloading) {
        return ;
    }
    NSMutableAttributedString * str = [[NSMutableAttributedString alloc] initWithAttributedString:self.contentLabel.attributedText];
    [str addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, str.length)];
    [str addAttribute:NSUnderlineStyleAttributeName value:@1 range:NSMakeRange(0, str.length)];
    self.contentLabel.text = @"";
    self.contentLabel.attributedText = str;
}

- (void)onLabelTap {
    @autoreleasepool {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSURL * url = [NSURL fileURLWithPath:_path];
            MPMoviePlayerViewController * vc = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
            [vc.moviePlayer prepareToPlay];
            [vc.moviePlayer setControlStyle:MPMovieControlStyleFullscreen];
            [vc.view setBackgroundColor:[UIColor blackColor]];
            [vc.view setFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
            [[AppTool getCurrentViewController] presentViewController:vc animated:YES completion:^{
                [[NSNotificationCenter defaultCenter] addObserverForName:MPMoviePlayerPlaybackDidFinishNotification object:vc.moviePlayer queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
                    if (note.object) {
                        MPMoviePlayerController * cc = (MPMoviePlayerController *)note.object;
                        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:cc];
                        [vc dismissViewControllerAnimated:YES completion:nil];
                    }
                }];
            }];
        });
    }
}

@end
