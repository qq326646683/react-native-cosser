//
//  YNShappedImageView.m
//  heartsquareapp
//
//  Created by Youssef on 15/12/18.
//  Copyright © 2015年 HeartSquare. All rights reserved.
//

#import "YNShappedImageView.h"

@interface YNShappedImageView()
{
    CALayer * _contentLayer;
    CAShapeLayer * _maskLayer;
}
@end

@implementation YNShappedImageView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame andShappImageName:(NSString *)name{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupWithImageName:name];
    }
    return self;
}

- (void)setup
{
    _maskLayer = [CAShapeLayer layer];
    _maskLayer.fillColor = [UIColor blackColor].CGColor;
    _maskLayer.strokeColor = [UIColor clearColor].CGColor;
    _maskLayer.frame = self.bounds;
    _maskLayer.contentsCenter = CGRectMake(0.5, 0.5, 0.1, 0.1);
    _maskLayer.contentsScale = [UIScreen mainScreen].scale;                 //非常关键设置自动拉伸的效果且不变形
    _maskLayer.contents = (id)[UIImage imageNamed:@"message_bubble_send"].CGImage;
    
    _contentLayer = [CALayer layer];
    _contentLayer.mask = _maskLayer;
    _contentLayer.frame = self.bounds;
    [self.layer addSublayer:_contentLayer];
    
}

- (void)setupWithImageName:(NSString *)name
{
    _maskLayer = [CAShapeLayer layer];
    _maskLayer.fillColor = [UIColor blackColor].CGColor;
    _maskLayer.strokeColor = [UIColor clearColor].CGColor;
    _maskLayer.frame = self.bounds;
    _maskLayer.contentsCenter = CGRectMake(0.5, 0.5, 0.1, 0.1);
    _maskLayer.contentsScale = [UIScreen mainScreen].scale;                 //非常关键设置自动拉伸的效果且不变形
    _maskLayer.contents = (id)[UIImage imageNamed:name].CGImage;
    
    _contentLayer = [CALayer layer];
    _contentLayer.mask = _maskLayer;
    _contentLayer.frame = self.bounds;
    [self.layer addSublayer:_contentLayer];
    
}

- (void)setImage:(UIImage *)image
{
    _contentLayer.contents = (id)image.CGImage;
}

@end
