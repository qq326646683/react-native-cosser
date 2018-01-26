//
//  GetMemoryAndCPU.m
//  GraphicsContext
//
//  Created by Youssef on 2017/10/23.
//  Copyright © 2017年 Youssef. All rights reserved.
//

#import "GetMemoryAndCPU.h"

#include <sys/sysctl.h>
#include <mach/task_info.h>
#include <mach/mach.h>

@implementation GetMemoryAndCPU

static GetMemoryAndCPU *shared = nil;

+ (instancetype)shared {
    return [[self alloc] init];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    if (!shared) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            shared = [super allocWithZone:zone];
        });
    }
    return shared;
}

- (id)copyWithZone:(NSZone *)zone {
    return shared;
}

- (void)start {
    [GetMemoryAndCPU shared].label = [[UILabel alloc] initWithFrame:CGRectMake(0, 200, 50, 50)];
    [GetMemoryAndCPU shared].label.adjustsFontSizeToFitWidth = YES;
    [GetMemoryAndCPU shared].label.font = [UIFont systemFontOfSize:13];
    [GetMemoryAndCPU shared].label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    [GetMemoryAndCPU shared].label.textColor = [UIColor whiteColor];
    [GetMemoryAndCPU shared].label.numberOfLines = 2;
    [GetMemoryAndCPU shared].label.text = [NSString stringWithFormat:@"%.1lfMB\nCPU:%.1lf", [GetMemoryAndCPU memoryUsage], [GetMemoryAndCPU cpuUsage]];
    [[UIApplication sharedApplication].keyWindow addSubview:[GetMemoryAndCPU shared].label];
    NSTimer * timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(changeText) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)changeText {
    dispatch_async(dispatch_get_main_queue(), ^{
        [GetMemoryAndCPU shared].label.text = [NSString stringWithFormat:@"%.1lfMB\nCPU:%.1lf", [GetMemoryAndCPU memoryUsage], [GetMemoryAndCPU cpuUsage]];
    });
}

+ (double)memoryUsage {
    struct mach_task_basic_info info;
    mach_msg_type_number_t count = MACH_TASK_BASIC_INFO_COUNT;
    
    int r = task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t)& info, & count);
    if (r == KERN_SUCCESS) {
        return info.resident_size/1048576.0;
    }else {
        return -1;
    }
}

+ (void)logMemoryInfo {
    
    int mib[6];
    mib[0] = CTL_HW;
    mib[1] = HW_PAGESIZE;
    
    int pagesize;
    size_t length;
    length = sizeof (pagesize);
    if (sysctl (mib, 2, &pagesize, &length, NULL, 0) < 0)
    {
        fprintf (stderr, "getting page size");
    }
    
    mach_msg_type_number_t count = HOST_VM_INFO_COUNT;
    
    vm_statistics_data_t vmstat;
    if (host_statistics (mach_host_self (), HOST_VM_INFO, (host_info_t) &vmstat, &count) != KERN_SUCCESS)
    {
        fprintf (stderr, "Failed to get VM statistics.");
    }
    task_basic_info_64_data_t info;
    unsigned size = sizeof (info);
    task_info (mach_task_self (), TASK_BASIC_INFO_64, (task_info_t) &info, &size);
    
    double unit = 1024 * 1024;
    double total = (vmstat.wire_count + vmstat.active_count + vmstat.inactive_count + vmstat.free_count) * pagesize / unit;
    double wired = vmstat.wire_count * pagesize / unit;
    double active = vmstat.active_count * pagesize / unit;
    double inactive = vmstat.inactive_count * pagesize / unit;
    double free = vmstat.free_count * pagesize / unit;
    double resident = info.resident_size / unit;
    NSLog(@"===================================================");
    NSLog(@"Total:%.2lfMb", total);
    NSLog(@"Wired:%.2lfMb", wired);
    NSLog(@"Active:%.2lfMb", active);
    NSLog(@"Inactive:%.2lfMb", inactive);
    NSLog(@"Free:%.2lfMb", free);
    NSLog(@"Resident:%.2lfMb", resident);
}

+ (double)cpuUsage {
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;
    
    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return -1.0;;
    }
    
    task_basic_info_t      basic_info;
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;
    
    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;
    
    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0; // Mach threads
    
    basic_info = (task_basic_info_t)tinfo;
    
    // get threads in the task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1.0;;
    }
    if (thread_count > 0)
        stat_thread += thread_count;
    
    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;
    
    for (j = 0; j < thread_count; j++)
    {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return -1.0;
        }
        
        basic_info_th = (thread_basic_info_t)thinfo;
        
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->system_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }
        
    } // for each thread
    
    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    assert(kr == KERN_SUCCESS);
    
    return tot_cpu;
}
@end
