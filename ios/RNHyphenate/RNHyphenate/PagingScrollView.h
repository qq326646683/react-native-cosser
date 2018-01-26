//
//  PagingScrollView.h
//  heartsquareapp
//
//  Created by 李月的 "Mac" on 15/4/10.
//  Copyright (c) 2015年 HeartSquare. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PagingScrollViewDelegate;

@interface PagingScrollView : UIScrollView

@property (assign, nonatomic) id<PagingScrollViewDelegate>pagingViewDelegate;
@property (readonly) UIView *visiblePageView;
@property (assign) BOOL suspendTiling;
@property (nonatomic) int pageIndex;

- (void)displayPagingViewAtIndex:(NSUInteger)index;
- (void)resetDisplay;

@end

@protocol PagingScrollViewDelegate <NSObject>

@required

- (Class)pagingScrollView:(PagingScrollView *)pagingScrollView classForIndex:(NSUInteger)index;
- (NSUInteger)pagingScrollViewPagingViewCount:(PagingScrollView *)pagingScrollView;
- (UIView *)pagingScrollView:(PagingScrollView *)pagingScrollView pageViewForIndex:(NSUInteger)index;
- (void)pagingScrollView:(PagingScrollView *)pagingScrollView preparePageViewForDisplay:(UIView *)pageView forIndex:(NSUInteger)index;
- (void)showCurrentIndex:(NSInteger)index;

@end
