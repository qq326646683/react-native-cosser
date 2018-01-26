//
//  PagingScrollView.m
//  heartsquareapp
//
//  Created by 李月的 "Mac" on 15/4/10.
//  Copyright (c) 2015年 HeartSquare. All rights reserved.
//

#import "PagingScrollView.h"

#pragma mark -  Class Extension
#pragma mark -

@interface PagingScrollView () <UIScrollViewDelegate>

@property (strong, nonatomic) NSMutableSet *recycledPages;
@property (strong, nonatomic) NSMutableSet *visiblePages;

@end

@implementation PagingScrollView {
    NSUInteger _currentPagingIndex;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupView];
}

- (void)setupView {
    self.pagingEnabled = YES;
    self.backgroundColor = [UIColor blackColor];
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.delegate = self;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.recycledPages = [[NSMutableSet alloc] init];
    self.visiblePages  = [[NSMutableSet alloc] init];
}

- (void)didReceiveMemoryWarning {
    [self didReceiveMemoryWarning];
    
    @synchronized (self) {
        // in case views start to pile up, make it possible to clear them out when memory gets low
        if (self.recycledPages.count > 3) {
            [self.recycledPages removeAllObjects];
        }
    }
}

#pragma mark - Calculations for Size and Positioning
#pragma mark -

#define PADDING 10

//- (CGRect)frameForPagingScrollView {
//    CGRect frame = [[UIScreen mainScreen] bounds];
//    frame.origin.x -= PADDING;
//    frame.size.width += (2 * PADDING);
//    return frame;
//}

- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    CGRect pageFrame = self.bounds;
    pageFrame.size.width -= (2 * PADDING);
    pageFrame.origin.x = (self.bounds.size.width * index);
    return pageFrame;
}

- (CGSize)contentSizeForPagingScrollView {
    NSUInteger count = [self.pagingViewDelegate pagingScrollViewPagingViewCount:self];
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    
    if (UIDeviceOrientationIsLandscape(deviceOrientation)) {
        return CGSizeMake(self.bounds.size.width*count, self.bounds.size.height-64);
    } else {
        return CGSizeMake(self.bounds.size.width*count, self.bounds.size.height-64);
    }
    
}

- (CGPoint)scrollPositionForIndex:(NSUInteger)index {
    CGFloat x = self.bounds.size.width * index;
    return CGPointMake(x, 0);
}

- (NSUInteger)currentPagingIndex {
    NSUInteger index = (NSUInteger)(ceil(self.contentOffset.x / self.bounds.size.width));
    return index;
}

- (void)configurePage:(UIView *)page forIndex:(NSUInteger)index {
    if (self.pagingViewDelegate != nil) {
        [self.pagingViewDelegate pagingScrollView:self preparePageViewForDisplay:page forIndex:index];
    }
    
    page.frame = [self frameForPageAtIndex:index];
    page.tag = index;
}

- (void)tilePages {
    if (self.suspendTiling) {
        // tiling during rotation causes odd behavior so it is best to suspend it
        return;
    }
    
    NSUInteger count = [self.pagingViewDelegate pagingScrollViewPagingViewCount:self]?:0;
    
    // Calculate which pages are visible
    CGRect visibleBounds = self.bounds;
    NSInteger firstNeededPageIndex = floorf(CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds));
    NSInteger lastNeededPageIndex  = floorf((CGRectGetMaxX(visibleBounds)-1) / CGRectGetWidth(visibleBounds));
    firstNeededPageIndex = MAX(firstNeededPageIndex, 0);
    lastNeededPageIndex  = MIN(lastNeededPageIndex, count - 1);
    
    // Recycle no-longer-visible pages
    for (UIView *page in self.visiblePages) {
        NSUInteger index = page.tag;
        if (index < firstNeededPageIndex || index > lastNeededPageIndex) {
            [self.recycledPages addObject:page];
            [page removeFromSuperview];
        }
    }
    [self.visiblePages minusSet:self.recycledPages];
    
    // add missing pages
    for (NSInteger index = firstNeededPageIndex; index <= lastNeededPageIndex; index++) {
        if (![self isDisplayingPageForIndex:index]) {
            UIView *page = [self dequeueRecycledPage:index];
            [self configurePage:page forIndex:index];
            [self addSubview:page];
            [self.visiblePages addObject:page];
        }
    }
}

#pragma mark - Reuse Queue
#pragma mark -

- (UIView *)dequeueRecycledPage:(NSUInteger)index {
    UIView *page = nil;
    if (self.pagingViewDelegate != nil) {
        for (UIView *recycledPage in self.recycledPages) {
            if ([recycledPage isKindOfClass:[self.pagingViewDelegate pagingScrollView:self classForIndex:index]]) {
                page = recycledPage;
                break;
            }
        }
        if (page != nil) {
            if ([page respondsToSelector:@selector(prepareForReuse)]) {
                [page performSelector:@selector(prepareForReuse)];
            }
            [self.recycledPages removeObject:page];
        }
        else {
            page = [self.pagingViewDelegate pagingScrollView:self pageViewForIndex:index];
        }
    }
    
    return page;
}

- (BOOL)isDisplayingPageForIndex:(NSUInteger)index {
    BOOL foundPage = NO;
    for (UIView *page in self.visiblePages) {
        NSUInteger pageIndex = page.tag;
        if (pageIndex == index) {
            foundPage = YES;
            break;
        }
    }
    return foundPage;
}

#pragma mark - Public Implementation
#pragma mark -

- (UIView *)visiblePageView {
    NSUInteger index = [self currentPagingIndex];
    for (UIView *pageView in self.visiblePages) {
        NSUInteger pageIndex = pageView.tag;
        if (pageIndex == index) {
            return pageView;
        }
    }
    
    return nil;
}

- (void)displayPagingViewAtIndex:(NSUInteger)index {
    _currentPagingIndex = index;
    
    self.contentSize = [self contentSizeForPagingScrollView];
    [self setContentOffset:[self scrollPositionForIndex:index] animated:FALSE];
    
    [self tilePages];
}

- (void)resetDisplay {
    self.contentSize = [self contentSizeForPagingScrollView];
    [self setContentOffset:[self scrollPositionForIndex:_currentPagingIndex] animated:FALSE];
    
    for (UIView *pageView in self.visiblePages) {
        NSUInteger index = pageView.tag;
        pageView.frame = [self frameForPageAtIndex:index];
    }
}

#pragma mark - UIScrollViewDelegate
#pragma mark -

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self tilePages];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    _currentPagingIndex = [self currentPagingIndex];
    [self.pagingViewDelegate showCurrentIndex:_currentPagingIndex];
}

@end

