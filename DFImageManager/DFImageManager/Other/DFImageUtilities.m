// The MIT License (MIT)
//
// Copyright (c) 2014 Alexander Grebenyuk (github.com/kean).
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

#import "DFImageUtilities.h"

@implementation DFImageUtilities

+ (UIImage *)imageWithImage:(UIImage *)image aspectFitSize:(CGSize)boundsSize {
    CGSize pixelSize = DFPixelSizeFromSize(boundsSize);
    return [self imageWithImage:image aspectFitPixelSize:pixelSize];
}

+ (UIImage *)imageWithImage:(UIImage *)image aspectFillSize:(CGSize)boundsSize {
    CGSize pixelSize = DFPixelSizeFromSize(boundsSize);
    return [self imageWithImage:image aspectFillPixelSize:pixelSize];
}

+ (UIImage *)imageWithImage:(UIImage *)image aspectFitPixelSize:(CGSize)boundsSize {
    CGSize imageSize = DFImageBitmapPixelSize(image);
    CGFloat scale = DFAspectFitScale(imageSize, boundsSize);
    if (scale < 1.0) {
        CGSize scaledSize = DFSizeScaled(imageSize, scale);
        CGSize pointSize = DFSizeFromPixelSize(scaledSize);
        return [self imageWithImage:image scaledToSize:pointSize];
    }
    return image;
}

+ (UIImage *)imageWithImage:(UIImage *)image aspectFillPixelSize:(CGSize)boundsSize {
    CGSize imageSize = DFImageBitmapPixelSize(image);
    CGFloat scale = DFAspectFillScale(imageSize, boundsSize);
    if (scale < 1.0) {
        CGSize scaledSize = DFSizeScaled(imageSize, scale);
        CGSize pointSize = DFSizeFromPixelSize(scaledSize);
        return [self imageWithImage:image scaledToSize:pointSize];
    }
    return image;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)boundsSize {
    CGSize roundedSize = CGSizeMake(floorf(boundsSize.width), floorf(boundsSize.height));
    UIGraphicsBeginImageContextWithOptions(roundedSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, roundedSize.width, roundedSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (UIImage *)croppedImageWithImage:(UIImage *)image normalizedCropRect:(CGRect)inputCropRect {
    CGRect cropRect = inputCropRect;
    
    switch (image.imageOrientation) {
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            // do nothing
            break;
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            cropRect.origin.y = inputCropRect.origin.x;
            cropRect.origin.x = 1.0 - inputCropRect.origin.y - inputCropRect.size.height;
            cropRect.size.width = inputCropRect.size.height;
            cropRect.size.height = inputCropRect.size.width;
            break;
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            cropRect.origin.x = 1.0 - inputCropRect.origin.x - inputCropRect.size.width;
            cropRect.origin.y = 1.0 - inputCropRect.origin.y - inputCropRect.size.height;
            break;
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            cropRect.origin.x = inputCropRect.origin.y;
            cropRect.origin.y = 1.0 - inputCropRect.origin.x - inputCropRect.size.width;
            cropRect.size.width = inputCropRect.size.height;
            cropRect.size.height = inputCropRect.size.width;
            break;
        default:
            break;
    }
    
    CGSize imagePixelSize = DFImageBitmapPixelSize(image);
    CGRect imageCropRect = CGRectMake(floorf(cropRect.origin.x * imagePixelSize.width),
                                      floorf(cropRect.origin.y * imagePixelSize.height),
                                      floorf(cropRect.size.width * imagePixelSize.width),
                                      floorf(cropRect.size.height * imagePixelSize.height));
    
    CGImageRef croppedImageRef = CGImageCreateWithImageInRect(image.CGImage, imageCropRect);
    UIImage *croppedImage = [UIImage imageWithCGImage:croppedImageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(croppedImageRef);
    return croppedImage;
}

@end
