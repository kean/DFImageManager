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

#import "DFCache.h"
#import "DFCacheBlocks.h"
#import "DFCacheImageDecoder.h"

#if (__IPHONE_OS_VERSION_MIN_REQUIRED)

static const DFCacheEncodeBlock DFCacheEncodeUIImage = ^NSData *(UIImage *image){
    return UIImageJPEGRepresentation(image, 1.0);
};

static const DFCacheDecodeBlock DFCacheDecodeUIImage = ^UIImage *(NSData *data) {
    return [DFCacheImageDecoder decompressedImageWithData:data];
};

static const DFCacheCostBlock DFCacheCostUIImage = ^NSUInteger(id object){
    if (![object isKindOfClass:[UIImage class]]) {
        return 0;
    }
    CGImageRef image = ((UIImage *)object).CGImage;
    NSUInteger bitsPerPixel = CGImageGetBitsPerPixel(image);
    return (CGImageGetWidth(image) * CGImageGetHeight(image) * bitsPerPixel) / 8; // Return number of bytes in image bitmap.
};

#endif

@interface DFCache (DFImage)

#if (__IPHONE_OS_VERSION_MIN_REQUIRED)

/*! Stores image into memory cache. Stores image data into disk cache. If image data is nil DFCacheEncodeUIImage block is used.
 */
- (void)storeImage:(UIImage *)image imageData:(NSData *)data forKey:(NSString *)key;

/*! Retrieves object from disk asynchronously using DFCacheDecodeUIImage and DFCacheCostUIImage.
 */
- (void)cachedImageForKey:(NSString *)key completion:(void (^)(UIImage *image))completion;

/*! Retrieves object from disk synchronously using DFCacheDecodeUIImage and DFCacheCostUIImage.
 */
- (UIImage *)cachedImageForKey:(NSString *)key;

#endif

@end
