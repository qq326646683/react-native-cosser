//
//  SaveModel.h
//  HyphenatePluginDemo
//
//  Created by Youssef on 2017/1/9.
//  Copyright © 2017年 yunio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SaveModel : NSObject
+ (instancetype)shared;

- (void)saveModelWithImUser:(NSString *)imUser userName:(NSString *)userName Password:(NSString *)password;

- (NSString *)getImUser;
- (NSString *)getUserName;
- (NSString *)getPassword;
- (NSDate *)getLastPlaySoundDate;
- (void)setLastPlaySoundDate:(NSDate *)date;

- (NSString *)getEMLoginSuccess;
- (void)setEMLoginSuccess;
- (void)deleteEMLoginSuccess;
@end
