//
//  YNShappedImageView.h
//  heartsquareapp
//
//  Created by Youseef on 15/12/18.
//  Copyright © 2015年 HeartSquare. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YNShappedImageView : UIView
@property (nonatomic, strong) UIImage * image;

- (instancetype)initWithFrame:(CGRect)frame andShappImageName:(NSString *)name;
@end
