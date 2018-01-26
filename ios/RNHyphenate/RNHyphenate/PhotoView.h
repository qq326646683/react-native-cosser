//
//  PhotoView.h
//  heartsquareapp
//
//  Created by 李月的 "Mac" on 15/4/10.
//  Copyright (c) 2015年 HeartSquare. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PhotoViewDelegate;

@interface PhotoView : UIScrollView

@property (assign, nonatomic) id<PhotoViewDelegate> photoViewDelegate;

- (void)prepareForReuse;
- (void)displayImage:(UIImage *)image;

- (void)updateZoomScale:(CGFloat)newScale;
- (void)updateZoomScale:(CGFloat)newScale withCenter:(CGPoint)center;

@end

@protocol PhotoViewDelegate <NSObject>

@optional

- (void)photoViewDidSingleTap:(PhotoView *)photoView;
- (void)photoViewDidDoubleTap:(PhotoView *)photoView;
- (void)photoViewDidTwoFingerTap:(PhotoView *)photoView;
- (void)photoViewDidDoubleTwoFingerTap:(PhotoView *)photoView;

@end
