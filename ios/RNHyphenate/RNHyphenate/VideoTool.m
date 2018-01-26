//
//  VideoTool.m
//  heartsquareapp
//
//  Created by Youssef on 2017/1/5.
//  Copyright © 2017年 HeartSquare. All rights reserved.
//

#import "VideoTool.h"
#import "AppTool.h"

@implementation VideoTool

+ (void)convertVideoQuailtyWithInputURL:(NSURL*)inputURL outputURL:(NSURL*)outputURL completeHandler:(void (^)(AVAssetExportSession * session))handler {
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse= YES;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
        switch (exportSession.status) {
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"AVAssetExportSessionStatusCancelled");
                break;
            case AVAssetExportSessionStatusUnknown:
                NSLog(@"AVAssetExportSessionStatusUnknown");
                break;
            case AVAssetExportSessionStatusWaiting:
                NSLog(@"AVAssetExportSessionStatusWaiting");
                break;
            case AVAssetExportSessionStatusExporting:
                NSLog(@"AVAssetExportSessionStatusExporting");
                break;
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"AVAssetExportSessionStatusCompleted");
                handler(exportSession);
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog(@"AVAssetExportSessionStatusFailed");
                break;
        }
    }];
}

+ (void) canUploadVideo:(NSURL *)URL completeHandler:(void (^)(NSURL * url))handle {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        CGFloat size = [VideoTool getFileSize:[URL path]];
        NSLog(@"%@", [NSString stringWithFormat:@"%f s", [VideoTool getVideoLength:URL]]);
        NSLog(@"%@", [NSString stringWithFormat:@"%.2f kb", size]);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *message;
            NSString *sizeString;
            CGFloat sizemb= size/1024;
            if(size <= 1024){
                sizeString = [NSString stringWithFormat:@"%.2fKB",size];
            }else{
                sizeString = [NSString stringWithFormat:@"%.2fMB",sizemb];
            }

            if (sizemb < 5){
                handle(URL);
            }else if (sizemb >= 5 && sizemb <= 10.0){
                message = [NSString stringWithFormat:@"当前视频%@，大于5MB会有点慢，确定上传吗？", sizeString];
                UIAlertController * alertController = [UIAlertController alertControllerWithTitle: nil
                                                                                          message: message
                                                                                   preferredStyle:UIAlertControllerStyleAlert];
                
                [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [[NSFileManager defaultManager] removeItemAtPath:[URL path] error:nil];//取消之后就删除，以免占用手机硬盘空间（沙盒）
                }]];
                [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    handle(URL);
                }]];
                [[AppTool getCurrentViewController] presentViewController:alertController animated:YES completion:nil];
            }else if (sizemb > 10.0){
                message = [NSString stringWithFormat:@"当前视频%@，超过10MB，不能上传，抱歉。", sizeString];
                UIAlertController * alertController = [UIAlertController alertControllerWithTitle: nil
                                                                                          message: message
                                                                                   preferredStyle:UIAlertControllerStyleAlert];
                
                [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [[NSFileManager defaultManager] removeItemAtPath:[URL path] error:nil];//取消之后就删除，以免占用手机硬盘空间
                }]];
                [[AppTool getCurrentViewController] presentViewController:alertController animated:YES completion:nil];
            }
        });
    });
}

//此方法可以获取文件的大小，返回的是单位是KB。
+ (CGFloat)getFileSize:(NSString *)path {
    NSLog(@"%@",path);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    float filesize = -1.0;
    if ([fileManager fileExistsAtPath:path]) {
        NSDictionary *fileDic = [fileManager attributesOfItemAtPath:path error:nil];//获取文件的属性
        unsigned long long size = [[fileDic objectForKey:NSFileSize] longLongValue];
        filesize = 1.0*size/1024;
    }else{
        NSLog(@"找不到文件");
    }
    return filesize;
}

+ (NSString *)getFileSizeWithByte:(unsigned long long)byte {
    CGFloat size = (byte/1024)*1.0;
    CGFloat sizemb= size/1024;
    if(size <= 1024){
        return [NSString stringWithFormat:@"%.2fKB",size];
    }else{
        return [NSString stringWithFormat:@"%.2fMB",sizemb];
    }
}

//此方法可以获取视频文件的时长。
+ (CGFloat)getVideoLength:(NSURL *)URL {
    AVURLAsset *avUrl = [AVURLAsset assetWithURL:URL];
    CMTime time = [avUrl duration];
    int second = ceil(time.value/time.timescale);
    return second;
}

@end
