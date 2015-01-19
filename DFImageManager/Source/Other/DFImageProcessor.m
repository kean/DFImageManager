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

#import "DFImageAssetProtocol.h"
#import "DFImageProcessor.h"
#import "DFImageRequest.h"
#import "DFImageUtilities.h"

NSString *DFImageProcessingClipsToBoundsKey = @"DFImageProcessingClipsToBoundsKey";
NSString *DFImageProcessingCornerRadiusKey = @"DFImageProcessingCornerRadiusKey";


@implementation DFImageProcessor

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithCache:(NSCache *)cache {
    if (self = [super init]) {
        _cache = cache;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (instancetype)init {
    NSCache *cache = [NSCache new];
    cache.totalCostLimit = [NSCache df_recommendedTotalCostLimit];
    return [self initWithCache:cache];
}

- (void)_didReceiveMemoryWarning:(NSNotification *__unused)notification {
    [self.cache removeAllObjects];
}

#pragma mark - <DFImageProcessing>

- (BOOL)isProcessingForRequestEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    if (request1 == request2) {
        return YES;
    }
    return (CGSizeEqualToSize(request1.targetSize, request2.targetSize) &&
            request1.contentMode == request2.contentMode);
}

- (UIImage *)processedImage:(UIImage *)image forRequest:(DFImageRequest *)request {
    UIImage *processedImage = image;
    switch (request.contentMode) {
        case DFImageContentModeAspectFit:
            processedImage = [DFImageUtilities decompressedImageWithImage:image aspectFitPixelSize:request.targetSize];
            break;
        case DFImageContentModeAspectFill: {
            BOOL clipsToBounds = [request.userInfo[DFImageProcessingClipsToBoundsKey] boolValue];
            if (clipsToBounds) {
                processedImage = [DFImageUtilities croppedImageWithImage:processedImage aspectFillPixelSize:request.targetSize];
            }
            processedImage = [DFImageUtilities decompressedImageWithImage:image aspectFillPixelSize:request.targetSize];
        }
            break;
        default:
            break;
    }
    NSNumber *normalizedCornerRadius = request.userInfo[DFImageProcessingCornerRadiusKey];
    if (normalizedCornerRadius != nil) {
        CGFloat cornerRadius = [normalizedCornerRadius floatValue] * MIN(processedImage.size.width, processedImage.size.height);
        processedImage = [DFImageUtilities imageWithImage:processedImage cornerRadius:cornerRadius];
    }
    return processedImage;
}

#pragma mark - <DFImageCache>

- (UIImage *)cachedImageForRequest:(DFImageRequest *)request {
    NSString *assetID = [request.asset assetID];
    if (assetID != nil) {
        NSString *cacheKey = [self _cacheKeyForAssetID:assetID request:request];
        return [_cache objectForKey:cacheKey];
    }
    return nil;
}

- (void)storeImage:(UIImage *)image forRequest:(DFImageRequest *)request {
    if (image != nil) {
        NSString *assetID = [request.asset assetID];
        if (assetID != nil) {
            NSString *cacheKey = [self _cacheKeyForAssetID:assetID request:request];
            NSUInteger cost = [self _costForImage:image];
            [_cache setObject:image forKey:cacheKey cost:cost];
        }
    }
}

#pragma mark -

- (NSString *)_cacheKeyForAssetID:(NSString *)assetID request:(DFImageRequest *)request {
    return [NSString stringWithFormat:@"%@,%@,%i,%@,%@", assetID, NSStringFromCGSize(request.targetSize), (int)request.contentMode, request.userInfo[DFImageProcessingClipsToBoundsKey], request.userInfo[DFImageProcessingCornerRadiusKey]];
}

- (NSUInteger)_costForImage:(UIImage *)image {
    CGImageRef imageRef = image.CGImage;
    NSUInteger bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
    return (CGImageGetWidth(imageRef) * CGImageGetHeight(imageRef) * bitsPerPixel) / 8; // Return number of bytes in image bitmap.
}

@end


@implementation NSCache (DFImageProcessingManager)

+ (NSCache *)df_sharedImageCache {
    static NSCache *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [NSCache new];
        cache.totalCostLimit = [self df_recommendedTotalCostLimit];
    });
    return cache;
}

+ (NSUInteger)df_recommendedTotalCostLimit {
    static NSUInteger recommendedSize;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSProcessInfo *info = [NSProcessInfo processInfo];
        CGFloat ratio = info.physicalMemory <= (1024 * 1024 * 512 /* 512 Mb */) ? 0.12f : 0.20f;
        recommendedSize = (NSUInteger)MAX(1024 * 1024 * 50 /* 50 Mb */, info.physicalMemory * ratio);
    });
    return recommendedSize;
}

@end
