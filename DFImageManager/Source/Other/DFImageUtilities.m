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
    CGSize roundedSize = CGSizeMake((CGFloat)floor(boundsSize.width), (CGFloat)floor(boundsSize.height));
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
    
    CGSize imagePixelSize = DFImageBitmapPixelSize(image);
    CGRect imageCropRect = CGRectMake((CGFloat)floor(cropRect.origin.x * imagePixelSize.width),
                                      (CGFloat)floor(cropRect.origin.y * imagePixelSize.height),
                                      (CGFloat)floor(cropRect.size.width * imagePixelSize.width),
                                      (CGFloat)floor(cropRect.size.height * imagePixelSize.height));
    
    CGImageRef croppedImageRef = CGImageCreateWithImageInRect(image.CGImage, imageCropRect);
    UIImage *croppedImage = [UIImage imageWithCGImage:croppedImageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(croppedImageRef);
    return croppedImage;
}

+ (UIImage *)croppedImageWithImage:(UIImage *)image aspectFillPixelSize:(CGSize)targetSize {
    CGSize imageSize = DFImageBitmapPixelSize(image);
    CGFloat scale = DFAspectFillScale(imageSize, targetSize);
    CGSize sizeScaled = DFSizeScaled(imageSize, scale);
    CGRect cropRect = CGRectMake((sizeScaled.width - targetSize.width) / 2.f, (sizeScaled.height - targetSize.height) / 2.f, targetSize.width, targetSize.height);
    CGRect normalizedCropRect = CGRectMake(cropRect.origin.x / sizeScaled.width, cropRect.origin.y / sizeScaled.height, cropRect.size.width / sizeScaled.width, cropRect.size.height / sizeScaled.height);
    return [self croppedImageWithImage:image normalizedCropRect:normalizedCropRect];
}

#pragma mark - Decompressing

+ (UIImage *)decompressedWithImage:(UIImage *)image {
    return [self decompressedWithImage:image scale:1.f];
}

+ (UIImage *)decompressedImageWithImage:(UIImage *)image aspectFitPixelSize:(CGSize)targetSize {
    CGSize imageSize = DFImageBitmapPixelSize(image);
    CGFloat scale = DFAspectFitScale(imageSize, targetSize);
    return [self decompressedWithImage:image scale:scale];
}

+ (UIImage *)decompressedImageWithImage:(UIImage *)image aspectFillPixelSize:(CGSize)targetSize {
    CGSize imageSize = DFImageBitmapPixelSize(image);
    CGFloat scale = DFAspectFillScale(imageSize, targetSize);
    return [self decompressedWithImage:image scale:scale];
}

+ (UIImage *)decompressedWithImage:(UIImage *)image scale:(CGFloat)scale {
    if (!image) {
        return nil;
    }
    if (image.images) {
        return image;
    }
    CGImageRef imageRef = image.CGImage;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    if (scale < 1.f) {
        imageSize = DFSizeScaled(imageSize, scale);
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
    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    
    UIImage *decompressedImage = [UIImage imageWithCGImage:decompressedImageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(decompressedImageRef);
    return decompressedImage;
}

#pragma mark - Corners

+ (UIImage *)imageWithImage:(UIImage *)image cornerRadius:(CGFloat)cornerRadius {
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0);
    [[UIBezierPath bezierPathWithRoundedRect:(CGRect){CGPointZero, image.size} cornerRadius:cornerRadius] addClip];
    [image drawInRect:(CGRect){CGPointZero, image.size}];
    UIImage *processedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return processedImage;
}

@end
