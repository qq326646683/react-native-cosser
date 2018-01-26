//
//  FeedbackCell.m
//  heartsquareapp
//
//  Created by Youssef on 2017/1/5.
//  Copyright © 2017年 HeartSquare. All rights reserved.
//

#import "FeedbackCell.h"
#import "AppTool.h"
#import "MyHyphenate.h"
#import "NSString+ComputerRect.h"
#import "ConvertToCommonEmoticonsHelper.h"

#define ScreenWidth             [UIScreen mainScreen].bounds.size.width
#define ScreenHeight            [UIScreen mainScreen].bounds.size.height
#define NavigationHeight        64

#define LeftHeadImageViewFrame CGRectMake(16,5,34,34)
#define LeftMessageBackgroundImageViewFrame CGRectMake(60,0,200,16)

//右侧暂时不提提供头像,若要添加头像，MessageBackground的位置需要随着头像的添加而变动，修改宏定义即可
#define RightHeadImageViewFrame CGRectMake(ScreenWidth-16-34,5,34,34)
#define RightMessageBackgroundImageViewFrame CGRectMake(ScreenWidth-200-16,0,200,16)

#define MessageLabelFrame CGRectMake(12,10,170,30)

@interface FeedbackCell() <EMChatManagerDelegate>
@property (nonatomic, copy) NSString * serviceSessionId;
@property (nonatomic, copy) NSNumber * inviteId;
@property (nonatomic, copy) NSString * imagePath;

@property (nonatomic, strong) UIButton * resendButton;
@property (nonatomic, strong) UIActivityIndicatorView * loadingView;
@end

@implementation FeedbackCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor whiteColor];
        [[[EMClient sharedClient] chatManager] addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return self;
}

- (void)createUI{
    _headImage = [[UIImageView alloc] init];
    _headImage.backgroundColor = [UIColor whiteColor];
    [self.contentView addSubview:_headImage];
    
    _cellBackImage = [[UIImageView alloc] init];
    _cellBackImage.backgroundColor = [UIColor whiteColor];
    _cellBackImage.userInteractionEnabled = YES;
    [self.contentView addSubview:_cellBackImage];
    
    _contentLabel = [[UILabel alloc] init];
    _contentLabel.numberOfLines = 0;
    _contentLabel.font = [UIFont systemFontOfSize:14];
    [_cellBackImage addSubview:_contentLabel];
    
    _resendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _resendButton.frame = CGRectMake(0, 0, 24, 24);
    _resendButton.backgroundColor = [UIColor clearColor];
    [_resendButton setBackgroundImage:[AppTool getImageWithResource:@"sendFailed.png"] forState:UIControlStateNormal];
    _resendButton.clipsToBounds = YES;
    _resendButton.hidden = YES;
    [_resendButton addTarget:self action:@selector(onResendButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_resendButton];
    
    _loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _loadingView.hidesWhenStopped = YES;
    [self.contentView addSubview:_loadingView];
}

#pragma mark - 判断消息是客服的还是用户的
- (void)setMessage:(EMMessage *)message{
    for (UIView * v in self.contentView.subviews) {
        [v removeFromSuperview];
    }
    [self createUI];
    
    if (message.direction == EMMessageDirectionReceive) {
        //NSLog(@"客服回复");
        _headImage.frame = LeftHeadImageViewFrame;
        NSString * param = [[NSUserDefaults standardUserDefaults] objectForKey:HeadImagePath];
        NSString * s = [[NSBundle mainBundle] pathForResource:param.lastPathComponent ofType:@"" inDirectory:param.stringByDeletingLastPathComponent];
        UIImage * image = [UIImage imageWithContentsOfFile:s];
        if (image == nil) {
            image = [AppTool getImageWithResource:@"icon.png"];
        }
        _headImage.image = [AppTool circleImage:image Radius:17 Size:CGSizeMake(34, 34)];
        
        _cellBackImage.frame = LeftMessageBackgroundImageViewFrame;
        _cellBackImage.image = [[AppTool getImageWithResource:@"message_bubble_recive.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:15];
        
        _contentLabel.textColor = [UIColor blackColor];
    }
    
    if (message.direction == EMMessageDirectionSend) {
        //NSLog(@"用户回复");
        _cellBackImage.frame = RightMessageBackgroundImageViewFrame;
        _cellBackImage.image = [[AppTool getImageWithResource:@"message_bubble_send.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:15];
        
        _contentLabel.textColor = [UIColor whiteColor];
        
        if (message.status == EMMessageStatusSuccessed) {
            [self isLoading:NO];
            [self showResendButton:NO];
        }else if (message.status == EMMessageStatusFailed) {
            [self isLoading:NO];
            [self showResendButton:YES];
        }else {
            [self isLoading:YES];
            [self showResendButton:NO];
        }
    }
    [self adjustHeightWithMessage:message];
}

- (void)isLoading:(BOOL)isloading {
    if (isloading) {
        [_loadingView startAnimating];
    }else {
        [_loadingView stopAnimating];
    }
}

- (void)showResendButton:(BOOL)showed {
    _resendButton.hidden = !showed;
    if (showed) {
        [_loadingView stopAnimating];
    }
}

- (void)onResendButtonTap:(UIButton *)button {
    if (self.cellDelegate) {
        [self.cellDelegate resendMessage:self];
        _resendButton.hidden = YES;
    }
}

#pragma mark - 根据文本大小或图片大小算出Cell高度
- (void)adjustHeightWithMessage:(EMMessage *)message{
    //this func must override in subClass
}

- (void)fecthRectWithText:(NSString *)text andMessage:(EMMessage *)message {
    CGRect contentRect = [[ConvertToCommonEmoticonsHelper convertToSystemEmoticons:text] boundingRectWithSize:CGSizeMake(170, 1000) andSystemFontOfSize:14];
    if (contentRect.size.width < 35) {
        contentRect.size.width = 35;
    }
    
    //改label得高度
    CGRect labelFrame = MessageLabelFrame;
    labelFrame.size.height = contentRect.size.height;
    labelFrame.size.width = contentRect.size.width;
    _contentLabel.text = [ConvertToCommonEmoticonsHelper convertToSystemEmoticons:text];
    _contentLabel.frame = labelFrame;
    
    //改背景图高度
    CGRect backFrame = _cellBackImage.frame;
    backFrame.size.height = contentRect.size.height + 20;
    
    //改背景图宽度，需要先判断是谁回复的
    if (message.direction == EMMessageDirectionSend) {
        backFrame.origin.x = backFrame.origin.x + (170 - contentRect.size.width);
    }
    backFrame.size.width = contentRect.size.width + 25;
    _cellBackImage.frame = backFrame;
    
    //改头像位置，放在消息底部
    CGRect head = _headImage.frame;
    if (contentRect.size.height < 50) {
        head.origin.y = contentRect.size.height/2 + contentRect.origin.y;
    }else{
        head.origin.y = backFrame.size.height + backFrame.origin.y - _headImage.bounds.size.height;
    }
    _headImage.frame = head;
    [self changeLoadFrame];
}

- (void)fecthRectWithImage:(UIImage *)image andMessage:(EMMessage *)message{
    float rule = 0;
    CGRect rect = _cellBackImage.frame;
    if (image.size.width > image.size.height) {
        rule = image.size.height/image.size.width;
        rect.size.width = 200;
        rect.size.height = 200*rule;
    }else {
        rule = image.size.width/image.size.height;
        rect.size.width = 200*rule;
        rect.size.height = 200;
    }
    
    if (rect.size.width > [UIScreen mainScreen].bounds.size.width-70) {
        rect.size.width = [UIScreen mainScreen].bounds.size.width-70;
    }
    
    //改背景图宽度，需要先判断是谁回复的
    if (message.direction == EMMessageDirectionSend) {
        if (image.size.width > image.size.height) {
            _cellBackImage.frame = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
        }else {
            _cellBackImage.frame = CGRectMake(rect.origin.x+200-(200*rule), rect.origin.y, rect.size.width, rect.size.height);
        }
    }else {
        _cellBackImage.frame = CGRectMake(60, 0, rect.size.width, rect.size.height);
        
        //改头像位置，放在消息底部
        CGRect head = _headImage.frame;
        if (_cellBackImage.frame.size.height < 50) {
            head.origin.y = _cellBackImage.frame.size.height/2 + _cellBackImage.frame.origin.y;
        }else{
            head.origin.y = _cellBackImage.frame.size.height + _cellBackImage.frame.origin.y - _headImage.bounds.size.height;
        }
        _headImage.frame = head;
    }
    [self changeLoadFrame];
}

- (void)changeLoadFrame {
    if (self.message.direction == EMMessageDirectionSend) {
        _resendButton.center = CGPointMake(_cellBackImage.frame.origin.x-20, _cellBackImage.center.y);
        _loadingView.center = _resendButton.center;
    } else {
        _resendButton.center = CGPointMake(CGRectGetMaxX(_cellBackImage.frame)+20, _cellBackImage.center.y);
        _loadingView.center = _resendButton.center;
    }
}

@end
