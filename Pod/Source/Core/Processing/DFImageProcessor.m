// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageProcessor.h"
#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"
#import "UIImage+DFImageUtilities.h"

NSString *DFImageProcessingCornerRadiusKey = @"DFImageProcessingCornerRadiusKey";

@implementation DFImageProcessor

- (instancetype)init {
    if (self = [super init]) {
        _shouldDecompressImages = YES;
    }
    return self;
}

#pragma mark <DFImageProcessing>

- (BOOL)isProcessingForRequestEquivalent:(nonnull DFImageRequest *)request1 toRequest:(nonnull DFImageRequest *)request2 {
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

- (nullable UIImage *)processedImage:(nonnull UIImage *)image forRequest:(nonnull DFImageRequest *)request partial:(BOOL)partial {
    if (request.contentMode == DFImageContentModeAspectFill && request.options.allowsClipping) {
        image = [DFImageProcessor _croppedImage:image aspectFillPixelSize:request.targetSize];
    }
    CGFloat scale = [UIImage df_scaleForImage:image targetSize:request.targetSize contentMode:request.contentMode];
    if (scale < 1.f || self.shouldDecompressImages) {
        image = [UIImage df_decompressedImage:image scale:scale];
    }
    NSNumber *normalizedCornerRadius = request.options.userInfo[DFImageProcessingCornerRadiusKey];
    if (normalizedCornerRadius) {
        CGFloat cornerRadius = normalizedCornerRadius.floatValue * MIN(image.size.width, image.size.height);
        image = [UIImage df_imageWithImage:image cornerRadius:cornerRadius];
    }
    return image;
}

+ (nullable UIImage *)_croppedImage:(nonnull UIImage *)image aspectFillPixelSize:(CGSize)targetSize {
    CGSize scaledSize = ({
        CGFloat scale = [UIImage df_scaleForImage:image targetSize:targetSize contentMode:DFImageContentModeAspectFill];
        CGSizeMake(CGImageGetWidth(image.CGImage) * scale, CGImageGetHeight(image.CGImage) * scale);
    });
    CGRect cropRect = CGRectMake((scaledSize.width - targetSize.width) / 2.f, (scaledSize.height - targetSize.height) / 2.f, targetSize.width, targetSize.height);
    CGRect normalizedCropRect = CGRectMake(cropRect.origin.x / scaledSize.width, cropRect.origin.y / scaledSize.height, cropRect.size.width / scaledSize.width, cropRect.size.height / scaledSize.height);
    return [UIImage df_croppedImage:image normalizedCropRect:normalizedCropRect];
}

@end
