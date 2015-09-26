// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFWebPImageDecoder.h"
#import <libwebp/webp/decode.h>

@implementation DFWebPImageDecoder

static void FreeImageData(void *info, const void *data, size_t size) {
    free((void *)data);
}

- (UIImage *)imageWithData:(NSData *)data partial:(BOOL)partial {
    if (partial) {
        return nil;
    }
    if (![self _isWebPData:data]) {
        return nil;
    }
    WebPDecoderConfig config;
    if (!WebPInitDecoderConfig(&config)) {
        return nil;
    }
    if (WebPGetFeatures(data.bytes, data.length, &config.input) != VP8_STATUS_OK) {
        return nil;
    }
    config.output.colorspace = config.input.has_alpha ? MODE_rgbA : MODE_RGB;
    if (WebPDecode(data.bytes, data.length, &config) != VP8_STATUS_OK) {
        return nil;
    }
    size_t width = (size_t)(config.options.use_scaling ? config.options.scaled_width : config.input.width);
    size_t height = (size_t)(config.options.use_scaling ? config.options.scaled_height : config.input.height);
    
    CGDataProviderRef providerRef = CGDataProviderCreateWithData(NULL, config.output.u.RGBA.rgba, config.output.u.RGBA.size, FreeImageData);
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = config.input.has_alpha ? kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast : 0;
    size_t components = config.input.has_alpha ? 4 : 3;
    CGImageRef imageRef = CGImageCreate(width, height, 8, components * 8, components * width, colorSpaceRef, bitmapInfo, providerRef, NULL, NO, kCGRenderingIntentDefault);
    if (colorSpaceRef) {
        CGColorSpaceRelease(colorSpaceRef);
    }
    if (providerRef) {
        CGDataProviderRelease(providerRef);
    }
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
    if (imageRef) {
        CGImageRelease(imageRef);
    }
    return image;
}

- (BOOL)_isWebPData:(NSData *)data {
    const NSInteger sigLength = 12;
    if (data.length < sigLength) {
        return NO;
    }
    uint8_t sig[sigLength];
    [data getBytes:&sig length:sigLength];
    // RIFF----WEBP
    return (sig[0] == 0x52 && sig[1] == 0x49 && sig[2] == 0x46 && sig[3] == 0x46 && sig[8] == 0x57 && sig[9] == 0x45 && sig[10] == 0x42 && sig[11] == 0x50);
}

@end
