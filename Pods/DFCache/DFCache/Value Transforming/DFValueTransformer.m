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

#import "DFValueTransformer.h"
#import "DFCacheImageDecoder.h"


NSString *const DFValueTransformerNSCodingName = @"DFValueTransformerNSCodingName";
NSString *const DFValueTransformerJSONName = @"DFValueTransformerJSONName";

#if (__IPHONE_OS_VERSION_MIN_REQUIRED)
NSString *const DFValueTransformerUIImageName = @"DFValueTransformerUIImageName";
#endif


@implementation DFValueTransformer

- (NSData *)transformedValue:(id __unused)value {
    [NSException raise:NSInternalInconsistencyException format:@"Abstract method called %@", NSStringFromSelector(_cmd)];
    return nil;
}

- (id)reverseTransfomedValue:(NSData *__unused)data {
    [NSException raise:NSInternalInconsistencyException format:@"Abstract method called %@", NSStringFromSelector(_cmd)];
    return nil;
}

@end


@implementation DFValueTransformerNSCoding

- (NSData *)transformedValue:(id)value {
    return value ? [NSKeyedArchiver archivedDataWithRootObject:value] : nil;
}

- (id)reverseTransfomedValue:(NSData *)data {
    return data ? [NSKeyedUnarchiver unarchiveObjectWithData:data] : nil;
}

@end


@implementation DFValueTransformerJSON

- (NSData *)transformedValue:(id)value {
    return value ? [NSJSONSerialization dataWithJSONObject:value options:kNilOptions error:nil] : nil;
}

- (id)reverseTransfomedValue:(NSData *)data {
    return data ? [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil] : nil;
}

@end


#if (__IPHONE_OS_VERSION_MIN_REQUIRED)

@implementation DFValueTransformerUIImage

- (instancetype)init {
    if (self = [super init]) {
        _compressionQuality = 0.75f;
        _allowsImageDecompression = YES;
    }
    return self;
}

- (NSData *)transformedValue:(id)value {
    BOOL isOpaque = [self _isImageOpaque:value];
    return isOpaque ? UIImageJPEGRepresentation(value, self.compressionQuality) : UIImagePNGRepresentation(value);
}

- (BOOL)_isImageOpaque:(UIImage *)image {
    CGImageAlphaInfo info = CGImageGetAlphaInfo(image.CGImage);
    return !(info == kCGImageAlphaFirst ||
             info == kCGImageAlphaLast ||
             info == kCGImageAlphaPremultipliedFirst ||
             info == kCGImageAlphaPremultipliedLast);
}

- (id)reverseTransfomedValue:(NSData *)data {
    if (self.allowsImageDecompression) {
        return [DFCacheImageDecoder decompressedImageWithData:data];
    } else {
        return [[UIImage alloc] initWithData:data scale:[UIScreen mainScreen].scale];
    }
}

- (NSUInteger)costForValue:(id)value {
    CGImageRef image = ((UIImage *)value).CGImage;
    NSUInteger bitsPerPixel = CGImageGetBitsPerPixel(image);
    return (CGImageGetWidth(image) * CGImageGetHeight(image) * bitsPerPixel) / 8; // Return number of bytes in image bitmap.
}

@end

#endif
