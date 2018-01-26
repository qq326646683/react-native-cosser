//
//  UIImage+Extras.h
//  YUNIO
//
//  Created by Rain Qian on 4/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Extras)

- (UIImage *)imageByScalingAndCroppingForSize:(CGSize)targetSize;
- (UIImage *)fixOrientation;
- (UIImage *)imageByApplyingAlpha:(CGFloat)alpha;

@end
