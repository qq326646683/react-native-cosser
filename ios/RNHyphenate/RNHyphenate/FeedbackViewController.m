//
//  FeedbackViewController.m
//  heartsquareapp
//
//  Created by Youssef on 15/12/15.
//  Copyright © 2015年 HeartSquare. All rights reserved.
//

#import "FeedbackViewController.h"
#import "UIImage+Extras.h"
#import "NSString+ComputerRect.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "LargePhotoViewController.h"
#import "VideoTool.h"
#import "AppTool.h"
#import "SaveModel.h"
#import "MyHyphenate.h"

#import "FeedbackTextCell.h"
#import "FeedbackFileCell.h"
#import "FeedbackImageCell.h"
#import "FeedbackAssessCell.h"

#define BottomViewHeight 51
#define ScreenWidth             [UIScreen mainScreen].bounds.size.width
#define ScreenHeight            [UIScreen mainScreen].bounds.size.height
#define NavigationHeight        64
#define RefreshTimeInterval 3.0

//#define FirstMessage @"您好，欢迎使用小世界。使用时如果有问题反馈或建议，可通过文字或照片的方式告知我们并留下您的联系方式。虽然不能实时回复，但我们会尽快为您处理问题，谢谢。"

static FeedbackViewController * instance = nil;
static int messageLimitedCount = 150;

//两次提示的默认间隔
static const CGFloat kDefaultPlaySoundInterval = 3.0;
static NSString *kMessageType = @"MessageType";
static NSString *kConversationChatter = @"ConversationChatter";
static NSString *kGroupName = @"GroupName";

//系统铃声播放完成后的回调
void EMSystemSoundFinishedPlayingCallback(SystemSoundID sound_id, void* user_data){
    AudioServicesDisposeSystemSoundID(sound_id);
}

@interface FeedbackViewController ()<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate, EMChatManagerDelegate, FeedbackAssessCellDelegate, FeedbackImageCellDelegate, FeedbackCellDelegate>
@property (nonatomic, strong) UIView * bottomView;
@property (nonatomic, strong) UITextField * textField;

@property (nonatomic, strong) UIView * choiceView;

@property (nonatomic) BOOL shouldScrollTableView;

@property (nonatomic, copy) NSString * messageTo;
@property (nonatomic, copy) NSString * converationID;
@end

@implementation FeedbackViewController

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    _datas = [[NSMutableArray alloc] init];
    
    [self setNavigationtitle];
    [self createBottomView];
    [self createTableView];
    
    _shouldScrollTableView = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapScreen)];
    [self.view addGestureRecognizer:tap];
    
    _messageTo = [[SaveModel shared] getImUser];
    _converationID = [[SaveModel shared] getImUser];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"EMMessageLoginSuccess" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [self addFirstMessage];
    }];
    if ([[SaveModel shared] getEMLoginSuccess]) {
        [self addFirstMessage];
    }

//    [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(newMessage) userInfo:nil repeats:YES];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    _messageTo = [[SaveModel shared] getImUser];
    _converationID = [[SaveModel shared] getImUser];
    [[[EMClient sharedClient] chatManager] addDelegate:self delegateQueue:dispatch_get_main_queue()];
    self.navigationController.tabBarController.tabBar.hidden = YES;
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    if ([self.navigationController.navigationBar respondsToSelector:@selector(shadowImage)]){
        [self.navigationController.navigationBar setShadowImage:[[UIImage alloc] init]];
    }
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
    
    [[NSUserDefaults standardUserDefaults] setObject:@"0" forKey:UnreadFeedBackMessageCount];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self reloadDataAndScroll:YES];
    
    if (self.navigationController.viewControllers.count == 1) {
        UIButton * backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        backButton.frame = CGRectMake(0, 0, 15, 30);
        [backButton setImage:[AppTool getImageWithResource:@"barBack.png"] forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        negativeSpacer.width = -10;
        self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:negativeSpacer, [[UIBarButtonItem alloc] initWithCustomView:backButton], nil];
    }else {
        self.navigationItem.leftBarButtonItems = nil;
    }
}

- (void)back {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (_shouldScrollTableView) {
        [self scrollTableViewToBottom];
    }else {
        _shouldScrollTableView = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self tapScreen];
    [[[EMClient sharedClient] chatManager] removeDelegate:self];
    [[NSUserDefaults standardUserDefaults] setObject:@"0" forKey:UnreadFeedBackMessageCount];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self performSelectorOnMainThread:@selector(postNoti) withObject:nil waitUntilDone:YES];
}

- (void)postNoti {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MessagesDidReceive" object:nil];
}

- (void)didConnectionStateChanged:(EMConnectionState)aConnectionState{
    NSLog(@"didConnectionStateChanged: %u", aConnectionState);
    [self reloadDataAndScroll:YES];
}

- (void)tapScreen {
    if (_textField) {
        if ([_textField isFirstResponder]) {
            [_textField resignFirstResponder];
        }
    }
}

- (void)createTableView{
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, NavigationHeight, ScreenWidth, ScreenHeight-NavigationHeight-BottomViewHeight) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = [UIColor whiteColor];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:_tableView];
    
    [_tableView registerClass:[FeedbackTextCell class] forCellReuseIdentifier:@"FeedbackTextCellReuseIdentifier"];
    [_tableView registerClass:[FeedbackImageCell class] forCellReuseIdentifier:@"FeedbackImageCellReuseIdentifier"];
    [_tableView registerClass:[FeedbackFileCell class] forCellReuseIdentifier:@"FeedbackFileCellReuseIdentifier"];
    [_tableView registerClass:[FeedbackAssessCell class] forCellReuseIdentifier:@"FeedbackAssessCellReuseIdentifier"];
    
    UIView * headView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 16)];
    headView.backgroundColor = [UIColor whiteColor];
    _tableView.tableHeaderView = headView;
}

#pragma mark - tableView的代理方法
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _datas.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    EMMessage * message = [_datas objectAtIndex:indexPath.row];
    
    NSDictionary * weichat = [message.ext objectForKey:@"weichat"];
    NSString * ctrlType = [weichat objectForKey:@"ctrlType"];
    if (ctrlType != [NSNull null]) {
        if ([ctrlType isEqualToString:@"inviteEnquiry"]) {
            return 14+40;
        }
    }
    
    if (message.body.type == EMMessageBodyTypeText) {
        //计算文本应该占据的高度
        EMTextMessageBody * body = (EMTextMessageBody *)message.body;
        CGRect contentRect = [body.text boundingRectWithSize:CGSizeMake(170, 1000) andSystemFontOfSize:14];
        
        //改label得高度
        double labelHeight = contentRect.size.height;
        //改背景图高度
        double backHeight = 20 + labelHeight;
        
        //返回Cell的高度，数字是cell间距
        return backHeight+14;
    }
    
    if (message.body.type == EMMessageBodyTypeFile) {
        EMFileMessageBody * b = (EMFileMessageBody *)message.body;
        if (b.downloadStatus == EMDownloadStatusDownloading) {
            return 20+14+30;
        }
        return 20+14+20;
    }
    
    if (message.body.type == EMMessageBodyTypeImage) {
        EMImageMessageBody * body = (EMImageMessageBody *)message.body;
        if (body.localPath != nil) {
            UIImage * image = [[UIImage alloc] initWithContentsOfFile:body.localPath];
            if (image.size.width > image.size.height) {
                return 14 + 200*(image.size.height/image.size.width);
            }else {
                return 214;
            }
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UILongPressGestureRecognizer * deleteCell = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(deleteCell:)];
    deleteCell.delegate = self;
    deleteCell.minimumPressDuration = 1.0;
    
    if (_datas.count == 0 || indexPath.row > _datas.count) {
        return [[UITableViewCell alloc] init];
    }
    EMMessage * message = [_datas objectAtIndex:indexPath.row];
    EMMessageBody * body = message.body;
    if (body.type == EMMessageBodyTypeText) {
        FeedbackTextCell * cell = [tableView dequeueReusableCellWithIdentifier:@"FeedbackTextCellReuseIdentifier"];
        if (cell == nil) {
            cell = [[FeedbackTextCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"FeedbackTextCellReuseIdentifier"];
        }
        cell.message = message;
        cell.cellDelegate = self;
        [cell.cellBackImage addGestureRecognizer:deleteCell];
        return cell;
    }else if (body.type == EMMessageBodyTypeImage){
        FeedbackImageCell * cell = [tableView dequeueReusableCellWithIdentifier:@"FeedbackImageCellReuseIdentifier"];
        if (cell == nil) {
            cell = [[FeedbackImageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"FeedbackImageCellReuseIdentifier"];
        }
        cell.message = message;
        cell.delegate = self;
        cell.cellDelegate = self;
        [cell.cellBackImage addGestureRecognizer:deleteCell];
        return cell;
    }else if (body.type == EMMessageBodyTypeFile) {
        FeedbackFileCell * cell = [tableView dequeueReusableCellWithIdentifier:@"FeedbackFileCellReuseIdentifier"];
        if (cell == nil) {
            cell = [[FeedbackFileCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"FeedbackFileCellReuseIdentifier"];
        }
        cell.message = message;
        cell.cellDelegate = self;
        [cell.cellBackImage addGestureRecognizer:deleteCell];
        return cell;
    }else {
        FeedbackAssessCell * cell = [tableView dequeueReusableCellWithIdentifier:@"FeedbackAssessCellReuseIdentifier"];
        if (cell == nil) {
            cell = [[FeedbackAssessCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"FeedbackAssessCellReuseIdentifier"];
        }
        cell.message = message;
        cell.delegate = self;
        cell.cellDelegate = self;
        [cell.cellBackImage addGestureRecognizer:deleteCell];
        return cell;
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [_textField resignFirstResponder];
    _shouldScrollTableView = NO;
}

- (void)showLargePhoto:(NSString *)imagePath {
    UIImage * image = [[UIImage alloc] initWithContentsOfFile:imagePath];
    LargePhotoViewController *c = [[LargePhotoViewController alloc] init];
    c.imageArray = @[image];
    c.currentIndex = 0;
    self.hidesBottomBarWhenPushed = YES;
    _shouldScrollTableView = NO;
    [self.navigationController pushViewController:c animated:YES];
}

#pragma mark - 客服评价代理方法
- (void)evaluateTapped:(NSNumber *)inviteId andServiceSessionId:(NSString *)serviceSessionId andWhichButton:(UIButton *)button {
    if (![AppTool hasInternet]) {
        return ;
    }
    NSIndexPath * index;
    NSArray *cellArray = [_tableView indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in cellArray) {
        FeedbackCell *cell = (FeedbackCell *)[_tableView cellForRowAtIndexPath:indexPath];
        if (cell.contentView == button.superview.superview) {
             index = indexPath;
        }
    }
    if (index.row != 0) {
        EMMessage * message = _datas[index.row];
        EMConversation * conversation = [MyHyphenate getCurrentConversation: YES];
        EMError * error = [[EMError alloc] init];
        [conversation deleteMessageWithId:message.messageId error:&error];
        if (error != nil) {
            NSLog(@"EMSDeleteMessageError %u   %@", error.code, error.errorDescription);
        }
    }
    [_datas removeObjectAtIndex:index.row];
    [_tableView reloadData];
}

#pragma mark - 设置页面标题
- (void)setNavigationtitle{
    UIBarButtonItem * item = [[UIBarButtonItem alloc] init];
    item.title = @"";
    self.navigationItem.backBarButtonItem = item;
    self.navigationItem.title = [AppTool FBlocalizedString:@"title" AndComment:nil];
}

#pragma mark - FeedbackCell代理方法
- (void)resendMessage:(FeedbackCell *)cell {
    [cell isLoading:YES];
    __weak FeedbackViewController *weakSelf = self;
    NSIndexPath * index = [_tableView indexPathForCell:cell];
    EMMessage * mes = _datas[index.row];
    [[[EMClient sharedClient] chatManager] resendMessage:mes progress:^(int progress) {
        
    } completion:^(EMMessage *message, EMError *error) {
        if (error) {
            NSLog(@"EMResendMessageError: %u   %@", error.code, error.errorDescription);
        }
        [weakSelf reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationNone];
    }];
}

#pragma mark - 创建底部输入框
- (void)createBottomView{
    //注意屏幕尺寸
    _bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, ScreenHeight-BottomViewHeight, ScreenWidth, BottomViewHeight)];
    _bottomView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_bottomView];
    
    UILabel * line = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, _bottomView.frame.size.width, 0.5)];
    line.backgroundColor = [UIColor colorWithCSS:@"d9d9d9"];
    [_bottomView addSubview:line];
    
    _textField = [[UITextField alloc] initWithFrame:CGRectMake(12, 11, _bottomView.bounds.size.width - 11- 40 - 30, _bottomView.bounds.size.height - 2*11)];
    _textField.adjustsFontSizeToFitWidth = YES;
    _textField.delegate = self;
    _textField.borderStyle = UITextBorderStyleRoundedRect;
    _textField.keyboardType = UIKeyboardTypeDefault;
    _textField.returnKeyType = UIReturnKeySend;
    _textField.textAlignment = NSTextAlignmentLeft;
    _textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _textField.font = [UIFont systemFontOfSize:14];
    _textField.placeholder = [AppTool FBlocalizedString:@"placeholder" AndComment:nil];
    [_textField setValue:[UIColor colorWithCSS:@"#878787"] forKeyPath:@"_placeholderLabel.textColor"];
    [_bottomView addSubview:_textField];
    
    UIButton * imageSender = [UIButton buttonWithType:UIButtonTypeCustom];
    imageSender.frame = CGRectMake(_bottomView.bounds.size.width-20-30, 5, 40, 40);
    [imageSender setImage:[AppTool getImageWithResource:@"camera.png"] forState:UIControlStateNormal];
    [imageSender addTarget:self action:@selector(presentPhotoLibrary:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomView addSubview:imageSender];
}

#pragma mark - 处理键盘弹出事件
- (void) keyboardWillShow: (NSNotification *) notify {
    [self updateKeyboardStatus:notify show:YES];
}

- (void) keyboardWillHide: (NSNotification *) notify {
    [self updateKeyboardStatus:notify show:NO];
}

- (void) updateKeyboardStatus: (NSNotification * )notify show: (BOOL)isShow {
    NSDictionary *userInfo = [notify userInfo];
    
    NSTimeInterval animationDuration;
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    
    CGRect kbFrame;
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&kbFrame];
    
    CGFloat y = isShow ? CGRectGetHeight(kbFrame) : 0;
    
    [UIView animateWithDuration:animationDuration
                     animations:^{
                         _bottomView.frame = CGRectMake(0, ScreenHeight-y-BottomViewHeight+1, ScreenWidth, BottomViewHeight);
                         if (_tableView.contentSize.height < _tableView.frame.size.height) {
                             _shouldScrollTableView = YES;
                             _tableView.frame = CGRectMake(0, NavigationHeight, ScreenWidth, ScreenHeight-NavigationHeight-BottomViewHeight-y);
                         }else {
                             _tableView.frame = CGRectMake(0, NavigationHeight-y, ScreenWidth, ScreenHeight-NavigationHeight-BottomViewHeight);
                         }
                         [self.view setNeedsLayout];
                         [self.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         [self scrollTableViewToBottom];
                     }];
}

#pragma mark - 键盘回车事件
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    //判断是否全是空白字符
    NSString * text = [_textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (_textField.text.length == 0 || text.length == 0) {
        _textField.text = @"";
        return NO;
    }
    
    NSString * hsVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString * osVersion = [UIDevice currentDevice].systemVersion;
    
    NSMutableDictionary * info = [[NSMutableDictionary alloc] init];
    [info setObject:@"iOS客户端" forKey:@"companyName"];
    [info setObject:[NSString stringWithFormat:@"系统版本:%@ 客户端版本:%@", osVersion, hsVersion] forKey:@"description"];
    NSDictionary * visitor = @{@"visitor":info};
    NSDictionary * weichat = @{@"weichat":visitor};
    
    __weak FeedbackViewController *weakSelf = self;
    EMTextMessageBody * body = [[EMTextMessageBody alloc] initWithText:text];
    NSString * from = [EMClient sharedClient].currentUsername;
    EMMessage * message = [[EMMessage alloc] initWithConversationID:_converationID from:from to:_messageTo body:body ext:weichat];
    message.chatType = EMChatTypeChat;
    [_datas addObject:message];
    NSIndexPath * index = [NSIndexPath indexPathForRow:_datas.count-1 inSection:0];
    [self insertCellAtIndexes:@[index] Animation:UITableViewRowAnimationRight];
    FeedbackCell * cell = [_tableView cellForRowAtIndexPath:index];
    [cell isLoading:YES];
    [[[EMClient sharedClient] chatManager] sendMessage:message progress:^(int progress) {
        
    } completion:^(EMMessage *message, EMError *error) {
        if (error != nil) {
            NSLog(@"EMSendTextMessageError: %u   %@", error.code, error.errorDescription);
        }
        [weakSelf reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationNone];
    }];
    
    //清空输入框
    _textField.text = @"";
    
    return NO;
}

#pragma mark - 选择要发送的图片
- (void)presentPhotoLibrary:(UIButton *)button {
    [self tapScreen];
    if (![AppTool hasInternet]) {
        return ;
    }
    UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                        delegate:self
                                               cancelButtonTitle:[AppTool FBlocalizedString:@"cancel" AndComment:nil]
                                          destructiveButtonTitle:nil
                                               otherButtonTitles:[AppTool FBlocalizedString:@"canmerPhoto" AndComment:nil], [AppTool FBlocalizedString:@"choosePhoto" AndComment:nil], nil];
    [sheet showInView:self.view];
}

#pragma mark - 选择照相机还是相册
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (0 == buttonIndex) {
        [self showCamera];
    }else if (1 == buttonIndex){
        [self showPhotoLibrary];
    }else {
        return;
    }
}

#pragma mark - 显示相机
- (void)showCamera {
    @try {
        NSString * mediaType = AVMediaTypeVideo;
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
        if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[AppTool FBlocalizedString:@"banner" AndComment:nil]
                                                            message:[AppTool FBlocalizedString:@"UnAuthorizedCanmer" AndComment:nil]
                                                           delegate:self
                                                  cancelButtonTitle:[AppTool FBlocalizedString:@"enter" AndComment:nil]
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            UIImagePickerController *cameraVC = [[UIImagePickerController alloc] init];
            [cameraVC setSourceType:UIImagePickerControllerSourceTypeCamera];
            [cameraVC.navigationBar setBarStyle:UIBarStyleBlack];
            [cameraVC setDelegate:self];
            [cameraVC setAllowsEditing:NO];
            //显示Camera VC
            [self presentViewController:cameraVC animated:YES completion:nil];
        }else {
            NSLog(@"Camera is not available.");
            return;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Camera is not available.");
    }
}

#pragma mark - 显示相册
- (void)showPhotoLibrary {
    @try {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
            UIImagePickerController *imgPickerVC = [[UIImagePickerController alloc] init];
            [imgPickerVC setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
            [imgPickerVC.navigationBar setBarStyle:UIBarStyleBlack];
            [imgPickerVC setDelegate:self];
            [imgPickerVC setAllowsEditing:YES];
            //显示Image Picker
            [self presentViewController:imgPickerVC animated:YES completion:nil];
        }else {
            NSLog(@"Album is not available.");
            return;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Album is not available.");
    }
}

#pragma mark - 选择本地视频
- (void)chooseVideo {
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    ipc.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;//sourcetype有三种分别是camera，photoLibrary和photoAlbum
    NSArray *availableMedia = [UIImagePickerController availableMediaTypesForSourceType: UIImagePickerControllerSourceTypeCamera];//Camera所支持的Media格式都有哪些,共有两个分别是@"public.image",@"public.movie"
    ipc.mediaTypes = [NSArray arrayWithObject:availableMedia[1]];//设置媒体类型为public.movie
    ipc.delegate = self;//设置委托
    [self presentViewController:ipc animated:YES completion:nil];
}

#pragma mark - 录制视频
- (void)startVideo {
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    ipc.sourceType = UIImagePickerControllerSourceTypeCamera;//sourcetype有三种分别是camera，photoLibrary和photoAlbum
    NSArray *availableMedia = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];//Camera所支持的Media格式都有哪些,共有两个分别是@"public.image",@"public.movie"
    ipc.mediaTypes = [NSArray arrayWithObject:availableMedia[1]];//设置媒体类型为public.movie
    ipc.videoMaximumDuration = 60.0f;//30秒
    ipc.delegate = self;//设置委托
    ipc.videoQuality = UIImagePickerControllerQualityTypeMedium;
    [self presentViewController:ipc animated:YES completion:nil];
}

#pragma mark - ImagePicker代理方法
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (![AppTool hasInternet]) {
        return ;
    }
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    if (image) {
        [self sendImage:image PickerController:picker];
        return ;
    }
    
    NSURL *sourceURL = [info objectForKey:UIImagePickerControllerMediaURL];
    if (sourceURL) {
        [self sendVideo:sourceURL PickerController:picker];
        return ;
    }
}

- (void)sendVideo:(NSURL *)sourceURL PickerController:(UIImagePickerController *)picker {
    NSURL *newVideoUrl ; //一般.mp4
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];//用时间给文件全名，以免重复，在测试的时候其实可以判断文件是否存在若存在，则删除，重新生成文件即可
    [formater setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
    NSString * fileName = [NSString stringWithFormat:@"%@.mp4", [formater stringFromDate:[NSDate date]]];
    newVideoUrl = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingFormat:@"/Documents/%@", fileName]];//这个是保存在app自己的沙盒路径里，在上传后删除掉，免得占空间。
    [picker dismissViewControllerAnimated:YES completion:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [VideoTool convertVideoQuailtyWithInputURL:sourceURL outputURL:newVideoUrl completeHandler:^(AVAssetExportSession *session) {
            [VideoTool canUploadVideo:session.outputURL completeHandler:^(NSURL *url) {
                EMFileMessageBody * body = [[EMFileMessageBody alloc] initWithLocalPath:[url path] displayName:fileName];
                NSString * from = [EMClient sharedClient].currentUsername;
                EMMessage * message = [[EMMessage alloc] initWithConversationID:_converationID from:from to:_messageTo body:body ext:nil];
                message.chatType = EMChatTypeChat;
                __weak FeedbackViewController *weakSelf = self;
                [[[EMClient sharedClient] chatManager] sendMessage:message progress:^(int progress) {
                    
                } completion:^(EMMessage *message, EMError *error) {
                    if (error != nil) {
                        NSLog(@"EMSendLogError: %u   %@", error.code, error.errorDescription);
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf reloadDataAndScroll:YES];
                        [[NSFileManager defaultManager] removeItemAtPath:[url path] error:nil];//在上传后删除掉，免得占空间。
                    });
                }];
            }];
        }];
    });
}

- (void)sendImage:(UIImage *)picture PickerController:(UIImagePickerController *)picker {
    UIImage * image = [picture fixOrientation];
    if (image.size.width > 0 && image.size.width <= 4160 && image.size.height <= 4160) {
        if (image.size.width/image.size.height >= 4.0 && image.size.width > 4000) {
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:[AppTool FBlocalizedString:@"tooLong" AndComment:nil] message:@"" delegate:self cancelButtonTitle:[AppTool FBlocalizedString:@"enter" AndComment:nil] otherButtonTitles:nil];
            [alert show];
            [picker dismissViewControllerAnimated:YES completion:nil];
            return ;
        }else {
            if (image.size.width > 400) {
                image = [image imageByScalingAndCroppingForSize:CGSizeMake(400, 400*(image.size.height/image.size.width))];
            }
        }
    }else {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:[AppTool FBlocalizedString:@"tooBig" AndComment:nil] message:@"" delegate:self cancelButtonTitle:[AppTool FBlocalizedString:@"enter" AndComment:nil] otherButtonTitles:nil];
        [alert show];
        [picker dismissViewControllerAnimated:YES completion:nil];
        return ;
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    EMImageMessageBody * body = [[EMImageMessageBody alloc] initWithData:UIImageJPEGRepresentation(image, 1) displayName:@"image.jpg"];
    NSString * from = [[EMClient sharedClient] currentUsername];
    EMMessage * message = [[EMMessage alloc] initWithConversationID:_converationID from:from to:_messageTo body:body ext:nil];
    message.chatType = EMChatTypeChat;
    [[[EMClient sharedClient] chatManager] sendMessage:message progress:^(int progress) {
        NSLog(@"EMSendImageMessage %d/n", progress);
    } completion:^(EMMessage *message, EMError *error) {
        if (error != nil) {
            NSLog(@"EMSendImageMessage %u   %@", error.code, error.errorDescription);
        }
        [self reloadDataAndScroll:YES];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 删除单元格
- (void)deleteCell:(UIGestureRecognizer *)gesture{
    _choiceView = gesture.view;
    if (gesture.state == UIGestureRecognizerStateEnded) {
        return;
    } else if (gesture.state == UIGestureRecognizerStateBegan) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:[AppTool FBlocalizedString:@"prompt" AndComment:nil] message:[AppTool FBlocalizedString:@"deleteMessage" AndComment:nil] delegate:self cancelButtonTitle:[AppTool FBlocalizedString:@"cancel" AndComment:nil] otherButtonTitles:[AppTool FBlocalizedString:@"enter" AndComment:nil], nil];
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (1 == buttonIndex) {
        NSIndexPath * indexPath = [self findView:_choiceView];
        if (indexPath.row != 0) {
            EMMessage * message = _datas[indexPath.row];
            EMConversation * conversation = [MyHyphenate getCurrentConversation: YES];
            EMError * error = [[EMError alloc] init];
            [conversation deleteMessageWithId:message.messageId error:&error];
            if (error != nil) {
                NSLog(@"EMSDeleteMessageError %u   %@", error.code, error.errorDescription);
            }
        }
        [_datas removeObjectAtIndex:indexPath.row];
        [_tableView reloadData];
    }else{
        return;
    }
}

#pragma mark - 查找该视图在哪个单元格
- (NSIndexPath *)findView:(UIView *)view{
    NSArray *cellArray = [_tableView indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in cellArray) {
        FeedbackCell *cell = (FeedbackCell *)[_tableView cellForRowAtIndexPath:indexPath];
        if (cell.contentView == view.superview) {
            return indexPath;
        }
    }
    return nil;
}

- (void)reloadRowsAtIndexPaths:(NSArray<NSIndexPath *> *)index withRowAnimation:(UITableViewRowAnimation)animation {
    [_tableView reloadRowsAtIndexPaths:index withRowAnimation:UITableViewRowAnimationNone];
    [_tableView scrollToRowAtIndexPath:index.lastObject atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)insertCellAtIndexes:(NSArray<NSIndexPath *> *)index Animation:(UITableViewRowAnimation)animation {
    [_tableView insertRowsAtIndexPaths:index withRowAnimation:animation];
    [_tableView scrollToRowAtIndexPath:index.lastObject atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)reloadDataAndScroll:(BOOL)shouleScroll {
    [_datas removeAllObjects];
    _shouldScrollTableView = shouleScroll;
    EMConversation * conversation = [MyHyphenate getCurrentConversation: YES];
    for (EMMessage * message in [conversation loadMoreMessagesFromId:@"" limit:messageLimitedCount direction:EMMessageSearchDirectionUp]) {
        [_datas addObject:message];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_tableView reloadData];
        if (shouleScroll) {
            [self scrollTableViewToBottom];
        }
    });
}

#pragma mark - 让表格视图显示最后一行
- (void)scrollTableViewToBottom {
    if (!_shouldScrollTableView) {
        return ;
    }
    NSInteger count = _datas.count - 1;
    if (count > 0) {
        NSInteger row = [_tableView numberOfRowsInSection:0]-1;
        if (row < 0) {
            row = 0;
        }
        NSIndexPath * indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        [_tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        NSLog(@"ScrollTableViewToBottom Finish");
    }
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    if ([navigationController isKindOfClass:[UIImagePickerController class]] && ((UIImagePickerController *)navigationController).sourceType == UIImagePickerControllerSourceTypePhotoLibrary) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    }
}

//如果收到新消息就刷新页面，EMChatManagerDelegate的代理方法
- (void)didReceiveMessages:(NSArray *)aMessages {
    [self reloadDataAndScroll:YES];
}

+ (void)didReceiveLocalNotification {
    if ([[AppTool getCurrentViewController] isMemberOfClass:[self class]]) {
        return ;
    }
}

+ (void)showNotificationWithMessage:(EMMessage *)message {
    EMPushOptions *options = [[EMClient sharedClient] pushOptions];
    
    //发送本地推送
    UILocalNotification * notification = [[UILocalNotification alloc] init];
    notification.fireDate = [NSDate date]; //触发通知的时间
    
    if (options.displayStyle == EMPushDisplayStyleMessageSummary) {
        EMMessageBody *messageBody = message.body;
        NSString *messageStr = nil;
        switch (messageBody.type) {
            case EMMessageBodyTypeText:
            {
                messageStr = ((EMTextMessageBody *)messageBody).text;
            }
                break;
            case EMMessageBodyTypeImage:
            {
                messageStr = NSLocalizedString(@"message.image", @"Image");
            }
                break;
            case EMMessageBodyTypeLocation:
            {
                messageStr = NSLocalizedString(@"message.location", @"Location");
            }
                break;
            case EMMessageBodyTypeVoice:
            {
                messageStr = NSLocalizedString(@"message.voice", @"Voice");
            }
                break;
            case EMMessageBodyTypeVideo:{
                messageStr = NSLocalizedString(@"message.video", @"Video");
            }
                break;
            default:
                break;
        }
        notification.alertBody = [NSString stringWithFormat:@"【%@】:%@", [AppTool FBlocalizedString:@"serviceMessage" AndComment:nil], messageStr];
    }
    else{
        notification.alertBody = [NSString stringWithFormat:[AppTool FBlocalizedString:@"hasNewMessage" AndComment:nil]];
    }
    
    //去掉注释会显示[本地]开头, 方便在开发中区分是否为本地推送
    //notification.alertBody = [[NSString alloc] initWithFormat:@"[本地]%@", notification.alertBody];
    notification.alertAction = NSLocalizedString(@"open", @"Open");
    notification.timeZone = [NSTimeZone defaultTimeZone];
    
    NSDate * last = [[SaveModel shared] getLastPlaySoundDate];
    
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:last];
    if (timeInterval < kDefaultPlaySoundInterval) {
        NSLog(@"skip ringing & vibration %@, %@", [NSDate date], last);
    } else {
        notification.soundName = UILocalNotificationDefaultSoundName;
        [[SaveModel shared] setLastPlaySoundDate:[NSDate date]];
    }
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:message.chatType] forKey:kMessageType];
    [userInfo setObject:message.conversationId forKey:kConversationChatter];
    notification.userInfo = userInfo;

    //发送通知
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
//    UIApplication *application = [UIApplication sharedApplication];
//    application.applicationIconBadgeNumber += 1;
}

+ (void)playSoundAndVibration {
    NSDate * last = [[SaveModel shared] getLastPlaySoundDate];
    NSTimeInterval timeInterval = [[NSDate date]
                                   timeIntervalSinceDate:last];
    if (timeInterval < kDefaultPlaySoundInterval) {
        //如果距离上次响铃和震动时间太短, 则跳过响铃
        NSLog(@"skip ringing & vibration %@, %@", [NSDate date], last);
        return;
    }
    
    //保存最后一次响铃时间
    [[SaveModel shared] setLastPlaySoundDate:[NSDate date]];
    
    // 收到消息时，播放音频
    [self playNewMessageSound];
    // 收到消息时，震动
    [self playVibration];
}

// 播放接收到新消息时的声音
+ (void)playNewMessageSound {
    /*
    // 要播放的音频文件地址
    NSURL *bundlePath = [[NSBundle mainBundle] URLForResource:@"EaseUIResource" withExtension:@"bundle"];
    NSURL *audioPath = [[NSBundle bundleWithURL:bundlePath] URLForResource:@"in" withExtension:@"caf"];
    // 创建系统声音，同时返回一个ID
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)(audioPath), &soundID);
    */
    // 若要播放自定义声音只需要将1302改成soundID即可，bundlePath要写对
    AudioServicesAddSystemSoundCompletion(1302,
                                          NULL, // uses the main run loop
                                          NULL, // uses kCFRunLoopDefaultMode
                                          EMSystemSoundFinishedPlayingCallback, // the name of our custom callback function
                                          NULL // for user data, but we don't need to do that in this case, so we just pass NULL
                                          );
    
    AudioServicesPlaySystemSound(1302);
}

// 震动
+ (void)playVibration {
    // Register the sound completion callback.
    AudioServicesAddSystemSoundCompletion(kSystemSoundID_Vibrate,
                                          NULL, // uses the main run loop
                                          NULL, // uses kCFRunLoopDefaultMode
                                          EMSystemSoundFinishedPlayingCallback, // the name of our custom callback function
                                          NULL // for user data, but we don't need to do that in this case, so we just pass NULL
                                          );
    
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

- (void)addFirstMessage {
    NSString * first = [[NSUserDefaults standardUserDefaults] objectForKey:WelcomeWords];
    if ([first isEqualToString:@""] || first == nil) {
        first = [AppTool FBlocalizedString:@"firstMessage" AndComment:nil];
    }
    
    EMConversation * conversation = [MyHyphenate getCurrentConversation: YES];
    for (EMMessage * message in [conversation loadMoreMessagesFromId:@"" limit:messageLimitedCount direction:EMMessageSearchDirectionUp]) {
        if (message.body.type == EMMessageBodyTypeText) {
            EMTextMessageBody * body = (EMTextMessageBody *)message.body;
            if ([body.text isEqualToString:first]) {
                return ;
            }
        }
    }
    
    EMTextMessageBody * firstbody = [[EMTextMessageBody alloc] initWithText:first];
    EMMessage * firstMessage = [[EMMessage alloc] initWithConversationID:_converationID from:[[EMClient sharedClient] currentUsername] to:_messageTo body:firstbody ext:nil];
    firstMessage.direction = EMMessageDirectionReceive;
    EMError * error = nil;
    [conversation insertMessage:firstMessage error: &error];
    if (error != nil) {
        NSLog(@"EMSInsertMessageError %u   %@", error.code, error.errorDescription);
    }
    [_datas addObject:firstMessage];
    
    [_tableView reloadData];
    return ;
}

//测试接受消息
- (void)newMessage {
    EMTextMessageBody * firstbody = [[EMTextMessageBody alloc] initWithText: @"您好，红倍心很高兴为您服务"];//NSLocalizedString(@"feedback_content", nil)
    EMMessage * firstMessage = [[EMMessage alloc] initWithConversationID:_converationID from:[[EMClient sharedClient] currentUsername] to:_messageTo body:firstbody ext:nil];
    firstMessage.direction = EMMessageDirectionReceive;
    EMConversation * conversation = [MyHyphenate getCurrentConversation: YES];
    EMError * error = [[EMError alloc] init];
    [conversation insertMessage:firstMessage error: &error];
    if (error != nil) {
        NSLog(@"EMSInsertMessageError %u   %@", error.code, error.errorDescription);
    }
    [_datas addObject:firstMessage];
    [[NSUserDefaults standardUserDefaults] setObject:@"10" forKey:UnreadFeedBackMessageCount];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [FeedbackViewController showNotificationWithMessage: firstMessage];
    [self reloadDataAndScroll:YES];
}

@end
