// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageManagerDefines.h"
#import <UIKit/UIKit.h>

/*! Image utilities.
 */
@interface UIImage (DFImageUtilities)

/*! Returns scale that is required to fill/fit image in a target size, maintaining aspect ratio.
 */
+ (CGFloat)df_scaleForImage:(nullable UIImage *)image targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode;

/*! Returns scaled decompressed image with a given image. Image decompression and scaling is made in a single step.
 */
+ (nullable UIImage *)df_decompressedImage:(nullable UIImage *)image scale:(CGFloat)scale;

/*! Returns image cropped to a given normalized crop rect.
 */
+ (nullable UIImage *)df_croppedImage:(nullable UIImage *)image normalizedCropRect:(CGRect)cropRect;

/*! Returns image by drawing rounded corners.
 @param cornerRadius corner radius in points.
 */
+ (nullable UIImage *)df_imageWithImage:(nullable UIImage *)image cornerRadius:(CGFloat)cornerRadius;

@end
