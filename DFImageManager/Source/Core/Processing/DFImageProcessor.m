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

#import "DFImageProcessor.h"
#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"

NSString *DFImageProcessingCornerRadiusKey = @"DFImageProcessingCornerRadiusKey";

@implementation DFImageProcessor

#pragma mark <DFImageProcessing>

- (BOOL)isProcessingForRequestEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    if (request1 == request2) {
        return YES;
    }
    if (!(CGSizeEqualToSize(request1.targetSize, request2.targetSize) &&
          request1.contentMode == request2.contentMode &&
          request1.options.allowsClipping == request2.options.allowsClipping)) {
        return NO;
    }
    NSNumber *cornerRadius1 = request1.options.userInfo[DFImageProcessingCornerRadiusKey];
    NSNumber *cornerRadius2 = request2.options.userInfo[DFImageProcessingCornerRadiusKey];
    return (!cornerRadius1 && !cornerRadius2) || ((!!cornerRadius1 && !!cornerRadius2) && [cornerRadius1 isEqualToNumber:cornerRadius2]);
}

- (UIImage *)processedImage:(UIImage *)image forRequest:(DFImageRequest *)request {
    if (request.contentMode == DFImageContentModeAspectFill && request.options.allowsClipping) {
        image = [DFImageProcessor croppedImageWithImage:image aspectFillPixelSize:request.targetSize];
    }
    image = [DFImageProcessor decompressedImageWithImage:image targetSize:request.targetSize contentMode:request.contentMode];
    NSNumber *normalizedCornerRadius = request.options.userInfo[DFImageProcessingCornerRadiusKey];
    if (normalizedCornerRadius) {
        CGFloat cornerRadius = [normalizedCornerRadius floatValue] * MIN(image.size.width, image.size.height);
        image = [DFImageProcessor imageWithImage:image cornerRadius:cornerRadius];
    }
    return image;
}

#pragma mark Utilities

+ (UIImage *)decompressedWithImage:(UIImage *)image {
    return [self decompressedWithImage:image scale:1.f];
}

+ (UIImage *)decompressedImageWithImage:(UIImage *)image targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode {
    CGSize bitmapSize = CGSizeMake(CGImageGetWidth(image.CGImage), CGImageGetHeight(image.CGImage));
    CGFloat scaleWidth = targetSize.width / bitmapSize.width;
    CGFloat scaleHeight = targetSize.height / bitmapSize.height;
    CGFloat scale = contentMode == DFImageContentModeAspectFill ? MAX(scaleWidth, scaleHeight) : MIN(scaleWidth, scaleHeight);
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
    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    
    UIImage *decompressedImage = [UIImage imageWithCGImage:decompressedImageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(decompressedImageRef);
    return decompressedImage;
}

+ (UIImage *)croppedImageWithImage:(UIImage *)image aspectFillPixelSize:(CGSize)targetSize {
    CGSize imageSize = CGSizeMake(CGImageGetWidth(image.CGImage), CGImageGetHeight(image.CGImage));
    CGFloat scale = ({
        CGFloat scaleWidth = targetSize.width / imageSize.width;
        CGFloat scaleHeight = targetSize.height / imageSize.height;
        MAX(scaleWidth, scaleHeight);
    });
    CGSize sizeScaled = CGSizeMake(imageSize.width * scale, imageSize.height * scale);
    CGRect cropRect = CGRectMake((sizeScaled.width - targetSize.width) / 2.f, (sizeScaled.height - targetSize.height) / 2.f, targetSize.width, targetSize.height);
    CGRect normalizedCropRect = CGRectMake(cropRect.origin.x / sizeScaled.width, cropRect.origin.y / sizeScaled.height, cropRect.size.width / sizeScaled.width, cropRect.size.height / sizeScaled.height);
    return [self croppedImageWithImage:image normalizedCropRect:normalizedCropRect];
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

+ (UIImage *)imageWithImage:(UIImage *)image cornerRadius:(CGFloat)cornerRadius {
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0);
    [[UIBezierPath bezierPathWithRoundedRect:(CGRect){CGPointZero, image.size} cornerRadius:cornerRadius] addClip];
    [image drawInRect:(CGRect){CGPointZero, image.size}];
    UIImage *processedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return processedImage;
}

@end
