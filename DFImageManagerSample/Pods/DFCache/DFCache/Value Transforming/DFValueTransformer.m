//
//  DFValueTransformer.m
//  DFCache
//
//  Created by Alexander Grebenyuk on 12/17/14.
//  Copyright (c) 2014 com.github.kean. All rights reserved.
//

#import "DFValueTransformer.h"
#import "DFCacheImageDecoder.h"


@implementation DFValueTransformer

- (id)initWithCoder:(NSCoder *__unused)decoder {
    if (self = [super init]) {
        // do nothing
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *__unused)coder {
    // do nothing
}

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
    return [DFCacheImageDecoder decompressedImageWithData:data];
}

- (NSUInteger)costForValue:(id)value {
    CGImageRef image = ((UIImage *)value).CGImage;
    NSUInteger bitsPerPixel = CGImageGetBitsPerPixel(image);
    return (CGImageGetWidth(image) * CGImageGetHeight(image) * bitsPerPixel) / 8; // Return number of bytes in image bitmap.
}

@end

#endif
