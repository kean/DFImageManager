// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <UIKit/UIKit.h>

@interface UIImage (DFImageManagerWebP)

/*! Returns YES if the data is identified as a WebP image.
 */
+ (BOOL)df_isWebPData:(nullable NSData *)data;

/*! Returns image represenation of the given data.
 */
+ (nullable UIImage *)df_imageWithWebPData:(nullable NSData *)data;

@end
