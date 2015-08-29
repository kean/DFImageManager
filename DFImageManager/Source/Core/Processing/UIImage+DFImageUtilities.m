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

#import "UIImage+DFImageUtilities.h"

@implementation UIImage (DFImageUtilities)

+ (UIImage *)df_decompressedImage:(UIImage *)image {
    return [self df_decompressedImage:image scale:1.f];
}

+ (CGFloat)df_scaleForImage:(nullable UIImage *)image targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode {
    CGSize bitmapSize = CGSizeMake(CGImageGetWidth(image.CGImage), CGImageGetHeight(image.CGImage));
    CGFloat scaleWidth = targetSize.width / bitmapSize.width;
    CGFloat scaleHeight = targetSize.height / bitmapSize.height;
    return contentMode == DFImageContentModeAspectFill ? MAX(scaleWidth, scaleHeight) : MIN(scaleWidth, scaleHeight);
}

+ (UIImage *)df_decompressedImage:(UIImage *)image targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode {
    CGFloat scale = [self df_scaleForImage:image targetSize:targetSize contentMode:contentMode];
    return [self df_decompressedImage:image scale:scale];
}

+ (UIImage *)df_decompressedImage:(UIImage *)image scale:(CGFloat)scale {
    if (!image) {
        return nil;
    }
    if (image.images) {
        return image;
    }
    CGImageRef imageRef = image.CGImage;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    if (scale < 1.f) {
        imageSize = CGSizeMake(imageSize.width * scale, imageSize.height * scale);
    }
    
    CGRect imageRect = (CGRect){.origin = CGPointZero, .size = imageSize};
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    
    int infoMask = (bitmapInfo & kCGBitmapAlphaInfoMask);
    BOOL anyNonAlpha = (infoMask == kCGImageAlphaNone ||
                        infoMask == kCGImageAlphaNoneSkipFirst ||
                        infoMask == kCGImageAlphaNoneSkipLast);
    
    // CGBitmapContextCreate doesn't support kCGImageAlphaNone with RGB.
    // https://developer.apple.com/library/mac/#qa/qa1037/_index.html
    if (infoMask == kCGImageAlphaNone && CGColorSpaceGetNumberOfComponents(colorSpace) > 1) {
        // Unset the old alpha info.
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
        
        // Set noneSkipFirst.
        bitmapInfo |= kCGImageAlphaNoneSkipFirst;
    }
    // Some PNGs tell us they have alpha but only 3 components. Odd.
    else if (!anyNonAlpha && CGColorSpaceGetNumberOfComponents(colorSpace) == 3) {
        // Unset the old alpha info.
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
        bitmapInfo |= kCGImageAlphaPremultipliedFirst;
    }
    
    // It calculates the bytes-per-row based on the bitsPerComponent and width arguments.
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 (size_t)imageSize.width,
                                                 (size_t)imageSize.height,
                                                 CGImageGetBitsPerComponent(imageRef),
                                                 0,
                                                 colorSpace,
                                                 bitmapInfo);
    CGColorSpaceRelease(colorSpace);
    
    // If failed, return original image
    if (!context) {
        return image;
    }
    
    CGContextDrawImage(context, imageRect, imageRef);
    CGImageRef df_decompressedImageRef = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    
    UIImage *df_decompressedImage = [UIImage imageWithCGImage:df_decompressedImageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(df_decompressedImageRef);
    return df_decompressedImage;
}

+ (UIImage *)df_croppedImage:(UIImage *)image normalizedCropRect:(CGRect)inputCropRect {
    CGRect cropRect = inputCropRect;
    
    switch (image.imageOrientation) {
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            // do nothing
            break;
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            cropRect.origin.y = inputCropRect.origin.x;
            cropRect.origin.x = 1.f - inputCropRect.origin.y - inputCropRect.size.height;
            cropRect.size.width = inputCropRect.size.height;
            cropRect.size.height = inputCropRect.size.width;
            break;
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            cropRect.origin.x = 1.f - inputCropRect.origin.x - inputCropRect.size.width;
            cropRect.origin.y = 1.f - inputCropRect.origin.y - inputCropRect.size.height;
            break;
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            cropRect.origin.x = inputCropRect.origin.y;
            cropRect.origin.y = 1.f - inputCropRect.origin.x - inputCropRect.size.width;
            cropRect.size.width = inputCropRect.size.height;
            cropRect.size.height = inputCropRect.size.width;
            break;
        default:
            break;
    }
    
    CGSize imagePixelSize = CGSizeMake(CGImageGetWidth(image.CGImage), CGImageGetHeight(image.CGImage));
    CGRect imageCropRect = CGRectMake((CGFloat)floor(cropRect.origin.x * imagePixelSize.width),
                                      (CGFloat)floor(cropRect.origin.y * imagePixelSize.height),
                                      (CGFloat)floor(cropRect.size.width * imagePixelSize.width),
                                      (CGFloat)floor(cropRect.size.height * imagePixelSize.height));
    
    CGImageRef croppedImageRef = CGImageCreateWithImageInRect(image.CGImage, imageCropRect);
    UIImage *croppedImage = [UIImage imageWithCGImage:croppedImageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(croppedImageRef);
    return croppedImage;
}

+ (UIImage *)df_imageWithImage:(UIImage *)image cornerRadius:(CGFloat)cornerRadius {
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0);
    [[UIBezierPath bezierPathWithRoundedRect:(CGRect){CGPointZero, image.size} cornerRadius:cornerRadius] addClip];
    [image drawInRect:(CGRect){CGPointZero, image.size}];
    UIImage *processedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return processedImage;
}

@end
