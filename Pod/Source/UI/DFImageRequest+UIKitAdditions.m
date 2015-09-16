// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageRequest+UIKitAdditions.h"

@implementation DFImageRequest (UIKitAdditions)

+ (CGSize)targetSizeForView:(nonnull UIView *)view {
    CGSize size = view.bounds.size;
    CGFloat scale = [UIScreen mainScreen].scale;
    return CGSizeMake(size.width * scale, size.height * scale);
}

@end
