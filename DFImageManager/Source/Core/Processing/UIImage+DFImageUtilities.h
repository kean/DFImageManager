// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "DFImageManagerDefines.h"
#import <UIKit/UIKit.h>

/*! Image utilities.
 */
@interface UIImage (DFImageUtilities)

/*! Returns decompressed image with a given image.
 */
+ (nullable UIImage *)df_decompressedImage:(nullable UIImage *)image;

/*! Returns scale that is required to fill/fit image in a target size, maintaining aspect ratio.
 */
+ (CGFloat)df_scaleForImage:(nullable UIImage *)image targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode;

/*! Returns decompressed image with a given image.
 @param targetSize Image target size in pixels.
 */
+ (nullable UIImage *)df_decompressedImage:(nullable UIImage *)image targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode;

/*! Returns scaled decompressed image with a given image.
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
