//
//  LargePhotoViewController.m
//  HeartSquare
//
//  Created by Rain Qian on 9/8/14.
//  Copyright (c) 2014 stoprain. All rights reserved.
//

#import "LargePhotoViewController.h"
#import "PagingScrollView.h"
#import "PhotoView.h"

@interface LargePhotoViewController () <PagingScrollViewDelegate, PhotoViewDelegate, UIScrollViewDelegate> {
    CGSize size;
    NSUInteger presentIndex;
    UIDeviceOrientation defaultOrentation;
    BOOL firstIn;
}

@property (weak, nonatomic) PagingScrollView *pagingScrollView;
@property (strong, nonatomic) NSArray *scrollArray;

@end

#define kScreenWidth ([[UIScreen mainScreen] applicationFrame].size.width)

@implementation LargePhotoViewController

#pragma mark - View Lifecycle
#pragma mark -

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    firstIn = YES;
    defaultOrentation = [UIDevice currentDevice].orientation;
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    PagingScrollView * pagingScrollView = [[PagingScrollView alloc] init];
    pagingScrollView.pagingViewDelegate = self;
    pagingScrollView.bounces = NO;
    [self.view addSubview:pagingScrollView];
    self.pagingScrollView = pagingScrollView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //self.navigationController.tabBarController.tabBar.hidden = YES;
    self.navigationController.navigationBar.translucent = TRUE;
    self.navigationItem.title = [NSString stringWithFormat:@"%zd/%zd", MIN(self.currentIndex+1, self.imageArray.count), self.imageArray.count];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    if (firstIn) {
        self.pagingScrollView.frame = CGRectMake(0, 0, self.view.frame.size.width+20, self.view.frame.size.height);
        [self.pagingScrollView displayPagingViewAtIndex:self.currentIndex];
        firstIn = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[UIApplication sharedApplication] setStatusBarHidden:FALSE withAnimation:UIStatusBarAnimationNone];
    self.navigationController.navigationBar.alpha = 1.0;
    self.navigationController.toolbar.alpha = 1.0;
}

- (void)toggleFullScreen {

    if (self.navigationController.navigationBar.alpha == 0.0) {
        // fade in navigation
        
        [UIView animateWithDuration:0.4 animations:^{
            [[UIApplication sharedApplication] setStatusBarHidden:FALSE withAnimation:UIStatusBarAnimationNone];
            self.navigationController.navigationBar.alpha = 1.0;
            self.navigationController.toolbar.alpha = 1.0;
        } completion:^(BOOL finished) {}];
    }
    else {
        // fade out navigation
        
        [UIView animateWithDuration:0.4 animations:^{
            [[UIApplication sharedApplication] setStatusBarHidden:TRUE withAnimation:UIStatusBarAnimationFade];
            self.navigationController.navigationBar.alpha = 0.0;
            self.navigationController.toolbar.alpha = 0.0;
        } completion:^(BOOL finished) {}];
    }
    
}
#pragma mark - PagingScrollViewDelegate
- (Class)pagingScrollView:(PagingScrollView *)pagingScrollView classForIndex:(NSUInteger)index {
    // all page views are photo views
    return [PhotoView class];
}

- (NSUInteger)pagingScrollViewPagingViewCount:(PagingScrollView *)pagingScrollView {
    return self.imageArray.count;
}

- (UIView *)pagingScrollView:(PagingScrollView *)pagingScrollView pageViewForIndex:(NSUInteger)index {
    if (index) {
        presentIndex = index;
    }
    PhotoView *photoView = [[PhotoView alloc] initWithFrame:self.pagingScrollView.bounds];
    photoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    photoView.photoViewDelegate = self;
    
    return photoView;
}

- (void)pagingScrollView:(PagingScrollView *)pagingScrollView preparePageViewForDisplay:(UIView *)pageView forIndex:(NSUInteger)index {
    if (index) {
        presentIndex = index;
    }
    PhotoView *photoView = (PhotoView *)pageView;
    UIImage *image = [self.imageArray objectAtIndex:index];
    [photoView displayImage:image];
}

- (void)showCurrentIndex:(NSInteger)index
{
    self.navigationItem.title = [NSString stringWithFormat:@"%zd/%zd", index+1, self.imageArray.count];
    presentIndex = index;
}



#pragma mark - Rotation

- (BOOL)shouldAutorotate {
    return NO;
}

- (void)orientationChanged:(NSNotification *)notification {
//        PagingScrollView * pagingScrollView = [[PagingScrollView alloc] initWithFrame:CGRectMake(-10, 0, self.view.frame.size.width+20, self.view.frame.size.height)];
    UIInterfaceOrientation o = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsLandscape(o)) {
        return;
    }
    
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsLandscape(deviceOrientation)) {
        if (deviceOrientation == UIDeviceOrientationLandscapeRight) {
            _pagingScrollView.transform = CGAffineTransformMakeRotation(-(90.0f * M_PI) / 180.0f);
        } else if (deviceOrientation == UIDeviceOrientationLandscapeLeft) {
            _pagingScrollView.transform = CGAffineTransformMakeRotation((90.0f * M_PI) / 180.0f);
        }
        _pagingScrollView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height+20);
        size = CGSizeMake(self.view.frame.size.height, self.view.frame.size.width);
        NSLog(@"UIDeviceOrientationLandscape---%@",NSStringFromCGRect(_pagingScrollView.frame));
    } else if (deviceOrientation == UIDeviceOrientationPortrait) {
        _pagingScrollView.transform = CGAffineTransformIdentity;
        _pagingScrollView.frame = CGRectMake(0, 0, self.view.frame.size.width+20, self.view.frame.size.height);
        size = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
        NSLog(@"UIDeviceOrientationLandscapeRight---%@",NSStringFromCGRect(_pagingScrollView.frame));
    }
    
    [_pagingScrollView resetDisplay];
    [_pagingScrollView displayPagingViewAtIndex:presentIndex];
    
}


#pragma mark - PhotoViewDelegate
- (void)photoViewDidSingleTap:(PhotoView *)photoView {
    [self toggleFullScreen];
}

- (void)photoViewDidDoubleTap:(PhotoView *)photoView{
}

- (void)photoViewDidDoubleTwoFingerTap:(PhotoView *)photoView{
}

-(void)photoViewDidTwoFingerTap:(PhotoView *)photoView{
}
@end
