//
//  MyHy.m
//  myPlugin
//
//  Created by Zoey on 2017/12/26.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "MyHyphenate.h"
#import "AppTool.h"
#import "FeedbackViewController.h"
#import "SaveModel.h"


@implementation MyHyphenate

+ (void)setupWithAppKey:(NSString *)appkey imUser:(NSString *)imUser userName:(NSString *)userName Password:(NSString *)password ApnsCertName:(NSString *)certName {
  NSLog(@"AppDelegate (Hyphenate) load");
  
  int systemVersion = [AppTool getSystemVersion];
  if (systemVersion >= 10) {
    //iOS10特有
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    // 必须写代理，不然无法监听通知的接收与点击
    center.delegate = [[UIApplication sharedApplication] delegate];
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound) completionHandler:^(BOOL granted, NSError * _Nullable error) {
      if (granted) {
        // 点击允许
        NSLog(@"注册成功");
        [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
          NSLog(@"%@", settings);
        }];
      } else {
        // 点击不允许
        NSLog(@"注册失败");
      }
    }];
  }else if (systemVersion >= 8){
    //iOS8 - iOS10
    [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeSound | UIUserNotificationTypeBadge categories:nil]];
    
  }else if (systemVersion < 8) {
    //iOS8系统以下
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound];
  }
  // 注册获得device Token
  [[UIApplication sharedApplication] registerForRemoteNotifications];
  
  [[SaveModel shared] saveModelWithImUser:imUser userName:userName Password:password];
  [self setupEMMessageWithAppKey:appkey imUser:imUser userName:userName Password:password ApnsCertName:certName];
}

+ (void)setupWithAppKey:(NSString *)appkey imUser:(NSString *)imUser userName:(NSString *)userName Password:(NSString *)password ApnsCertName:(NSString *)certName ServiceHeadImagePath:(NSString *)path andWelcomeWords:(NSString *)words {
  [self setupWithAppKey:appkey imUser:imUser userName:userName Password:password ApnsCertName:certName];
  [[NSUserDefaults standardUserDefaults] setObject:path forKey:HeadImagePath];
  [[NSUserDefaults standardUserDefaults] setObject:words forKey:WelcomeWords];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)present:(UIViewController *)vc {
  NSLog(@"AppDelegate (Hyphenate) present");
  UINavigationController * nv = [[UINavigationController alloc] initWithRootViewController:[[FeedbackViewController alloc] init]];
  [vc presentViewController:nv animated:YES completion:nil];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
  NSLog(@"AppDelegate (Hyphenate) applicationDidFinishLaunching");
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  NSLog(@"AppDelegate (Hyphenate) applicationDidBecomeActive");
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  NSLog(@"AppDelegate (Hyphenate) applicationWillEnterForeground");
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  NSLog(@"AppDelegate (Hyphenate) applicationDidEnterBackground");
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  NSLog(@"didRegisterForRemoteNotificationsWithDeviceToken  %@", deviceToken);
  [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:@"DeviceToken"];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)setupEMMessageWithAppKey:(NSString *)appkey imUser:(NSString *)imUser userName:(NSString *)userName Password:(NSString *)password ApnsCertName:(NSString *)certName {
  EMOptions *options = [EMOptions optionsWithAppkey:appkey];
  options.apnsCertName = certName;
  EMError * error = [[EMClient sharedClient] initializeSDKWithOptions:options];
  if (error) {
    NSLog(@"initializeSDKWithOptions Error  %@, %u", error.errorDescription, error.code);
  }
  
  [[EMClient sharedClient] addDelegate:[[UIApplication sharedApplication] delegate] delegateQueue:dispatch_get_main_queue()];
  [[[EMClient sharedClient] chatManager] addDelegate:[[UIApplication sharedApplication] delegate] delegateQueue:dispatch_get_main_queue()];
  
  [self registerUser:userName Password:password];
}

//环信注册User
+ (void)registerUser:(NSString *)name Password:(NSString *)word {
  NSString * userName = name;
  NSString * password = word;
  NSString * nickName = name;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    if (![EMClient sharedClient].currentUsername) {
      EMError * error = [[EMClient sharedClient] loginWithUsername:userName password:password];
      if (error) {
        NSLog(@"EMMessage First Login ErrorCode:%u  Description: %@", error.code, error.errorDescription);
        EMError * errors = [[EMClient sharedClient] registerWithUsername:userName password:password];
        if (errors) {
          NSLog(@"EMMessage Register ErrorCode:%u  Description: %@", errors.code, errors.errorDescription);
        }else {
          EMError * errorss = [[EMClient sharedClient] loginWithUsername:userName password:password];
          if (errorss) {
            NSLog(@"EMMessage Login ErrorCode:%u  Description: %@", errorss.code, errorss.errorDescription);
          }else {
            [self loginSuccess];
            //设置推送的APNS属性，需要在登陆成功之后设置
            [self setEMPushOptionsWithNickName:nickName];
          }
        }
      }else {
        [self loginSuccess];
        //设置推送的APNS属性，需要在登陆成功之后设置
        [self setEMPushOptionsWithNickName:nickName];
      }
    }else {
      NSLog(@"EMMessage CurrentUsername: %@", [EMClient sharedClient].currentUsername);
    }
  });
}

//获取当前会话
+ (EMConversation *)getCurrentConversation:(BOOL)markAllAsRead {
  EMConversation * conversation = [[[EMClient sharedClient] chatManager] getConversation:[[SaveModel shared] getImUser] type:EMConversationTypeChat createIfNotExist:YES];
  if (markAllAsRead) {
    EMError * error = [[EMError alloc] init];
    [conversation markAllMessagesAsRead:&error];
    if (error != nil) {
      NSLog(@"EMMarkAllMessagesAsReadError %u   %@", error.code, error.errorDescription);
    }
  }
  return conversation;
}
//登陆成功后绑定DeviceToken
+ (void)loginSuccess {
  NSLog(@"EMMessage LoginSuccess");
  [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%d", [self getCurrentConversation: NO].unreadMessagesCount] forKey:UnreadFeedBackMessageCount];
  [[NSUserDefaults standardUserDefaults] synchronize];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"EMMessageLoginSuccess" object:nil];
  [[SaveModel shared] setEMLoginSuccess];
  [[EMClient sharedClient] options].isAutoLogin = NO;
  NSData * deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"DeviceToken"];
  EMError * error = [[EMClient sharedClient] bindDeviceToken:deviceToken];
  if (error) {
    NSLog(@"EMMessage BindDeviceTokenError: %u %@", error.code, error.errorDescription);
  }else {
    NSLog(@"EMMessage BindDeviceToken Success");
  }
}
//上传推送设置
+ (void)setEMPushOptionsWithNickName:(NSString *)nickName {
  EMPushOptions *options = [[EMClient sharedClient] pushOptions];
  options.noDisturbStatus = EMPushNoDisturbStatusClose;
  options.displayName = nickName;
  options.displayStyle = EMPushDisplayStyleMessageSummary;
  [[EMClient sharedClient] updatePushNotificationOptionsToServerWithCompletion:^(EMError *aError) {
    if (aError) {
      NSLog(@"EMMessage UpdatePushOptionsToServer Error: %u %@", aError.code, aError.errorDescription);
    }else {
      NSLog(@"EMMessage UpdatePushOptionsToServer Success");
    }
  }];
}
//登出环信账号
+ (void)logoutUser {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    EMError * errors = [[EMClient sharedClient] logout:YES];
    if (errors) {
      NSLog(@"EMMessage Logout ErrorCode:%u  Description: %@", errors.code, errors.errorDescription);
    }else {
      [[SaveModel shared] deleteEMLoginSuccess];
      [[NSUserDefaults standardUserDefaults] setObject:@"0" forKey:UnreadFeedBackMessageCount];
      [[NSUserDefaults standardUserDefaults] synchronize];
      NSLog(@"EMMessage Logout Success");
    }
  });
}
//环信连接服务器的状态变化时会接收到该回调
- (void)connectionStateDidChange:(EMConnectionState)aConnectionState {
  if (aConnectionState == EMConnectionConnected) {
    NSLog(@"EMMessage ConnectionConnected");
  }else {
    NSLog(@"EMMessage ConnectionDisconnected");
  }
}
//环信自动登录完成回调
- (void)autoLoginDidCompleteWithError:(EMError *)aError {
  if (aError == nil) {
    NSLog(@"EMMessage AutoLogin Success");
    [MyHyphenate loginSuccess];
    //设置推送的APNS属性，需要在登陆成功之后设置
    [MyHyphenate setEMPushOptionsWithNickName:[EMClient sharedClient].currentUsername];
  }else {
    NSLog(@"EMMessage AutoLogin Error %@", aError.description);
    [MyHyphenate registerUser:[[SaveModel shared] getUserName] Password:[[SaveModel shared] getPassword]];
  }
}
//环信账号在其他设备登录
- (void)userAccountDidLoginFromOtherDevice {
  [[SaveModel shared] deleteEMLoginSuccess];
  NSLog(@"EMMessage AccountDidLoginFromOtherDevice");
}
//环信收到新消息时的回调,收到消息后更改未读消息数,并且发送通知
- (void)messagesDidReceive:(NSArray *)aMessages {
  EMConversation * conversation = [MyHyphenate getCurrentConversation: NO];
  [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%d", conversation.unreadMessagesCount] forKey:UnreadFeedBackMessageCount];
  [[NSUserDefaults standardUserDefaults] synchronize];
  [self performSelectorOnMainThread:@selector(postNoti) withObject:nil waitUntilDone:YES];
  
  for(EMMessage *message in aMessages){
    BOOL needShowNotification = (message.chatType == EMChatTypeChat) ?  YES: NO;
    if (needShowNotification) {
#if !TARGET_IPHONE_SIMULATOR
      UIApplicationState state = [[UIApplication sharedApplication] applicationState];
      switch (state) {
        case UIApplicationStateActive:
          [FeedbackViewController playSoundAndVibration];
          break;
        case UIApplicationStateInactive:
          [FeedbackViewController playSoundAndVibration];
          break;
        case UIApplicationStateBackground:
          [FeedbackViewController showNotificationWithMessage:message];
          break;
        default:
          break;
      }
#endif
    }
  }
}

- (void)postNoti {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"MessagesDidReceive" object:nil];
}

//获取环信未读消息数量
+ (int)getUnreadMessageCount {
  NSString * count = [[NSUserDefaults standardUserDefaults] objectForKey:UnreadFeedBackMessageCount];
  return count.intValue;
}

@end
