//
//  VideoTool.h
//  heartsquareapp
//
//  Created by Youssef on 2017/1/5.
//  Copyright © 2017年 HeartSquare. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface VideoTool : NSObject
+ (CGFloat)getFileSize:(NSString *)path;
+ (CGFloat)getVideoLength:(NSURL *)URL;
+ (NSString *)getFileSizeWithByte:(unsigned long long)byte;

+ (void)convertVideoQuailtyWithInputURL:(NSURL*)inputURL outputURL:(NSURL*)outputURL completeHandler:(void (^)(AVAssetExportSession * session))handler;
+ (void) canUploadVideo:(NSURL*)URL completeHandler:(void (^)(NSURL * url))handle;
@end
