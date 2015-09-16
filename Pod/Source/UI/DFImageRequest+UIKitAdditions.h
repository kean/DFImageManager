// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageRequest.h"

@interface DFImageRequest (UIKitAdditions)

/*! Returns image target size (in pixels) for a given view.
 */
+ (CGSize)targetSizeForView:(nonnull UIView *)view;

@end
