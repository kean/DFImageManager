// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageDecoder.h"

#if TARGET_OS_WATCH
#import <WatchKit/WatchKit.h>
#endif

@implementation DFImageDecoder

- (nullable UIImage *)imageWithData:(nonnull NSData *)data partial:(BOOL)partial {
#if TARGET_OS_IOS && !TARGET_OS_WATCH
    return [UIImage imageWithData:data scale:[UIScreen mainScreen].scale];
#else
    return [UIImage imageWithData:data scale:[WKInterfaceDevice currentDevice].screenScale];
#endif
}

@end


@implementation DFCompositeImageDecoder {
    NSArray <id<DFImageDecoding>> *_decoders;
}

- (instancetype)initWithDecoders:(NSArray<id<DFImageDecoding>> *)decoders {
    if (self = [super init]) {
        _decoders = [NSArray arrayWithArray:decoders];
    }
    return self;
}

- (UIImage *)imageWithData:(NSData *)data partial:(BOOL)partial {
    for (id<DFImageDecoding> decoder in _decoders) {
        UIImage *image = [decoder imageWithData:data partial:partial];
        if (image) {
            return image;
        }
    }
    return nil;
}

@end
