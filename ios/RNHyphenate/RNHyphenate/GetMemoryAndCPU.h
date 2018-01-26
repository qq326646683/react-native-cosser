//
//  GetMemoryAndCPU.h
//  GraphicsContext
//
//  Created by Youssef on 2017/10/23.
//  Copyright © 2017年 Youssef. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface GetMemoryAndCPU : NSObject
@property (nonatomic, strong) UILabel * label;

+ (instancetype)shared;
- (void)start;
+ (double)memoryUsage;
+ (double)cpuUsage;
+ (void)logMemoryInfo;
@end
