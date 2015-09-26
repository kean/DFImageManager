// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageDecoder.h"
#import "DFImageManagerDefines.h"
#import <libkern/OSAtomic.h>

#if __has_include("DFImageManagerKit+GIF.h")
#import "DFImageManagerKit+GIF.h"
#endif

#if __has_include("DFImageManagerKit+WebP.h")
#import "DFImageManagerKit+WebP.h"
#endif

#if TARGET_OS_WATCH
#import <WatchKit/WatchKit.h>
#endif

@implementation DFImageDecoder

- (nullable UIImage *)imageWithData:(nonnull NSData *)data partial:(BOOL)partial {
#if __IPHONE_OS_VERSION_MIN_REQUIRED && !__WATCH_OS_VERSION_MIN_REQUIRED
    return [UIImage imageWithData:data scale:[UIScreen mainScreen].scale];
#else
    return [UIImage imageWithData:data scale:[WKInterfaceDevice currentDevice].screenScale];
#endif
}

#pragma mark Dependency Injector

static id<DFImageDecoding> _sharedDecoder;
static OSSpinLock _lock = OS_SPINLOCK_INIT;

+ (void)initialize {
    NSMutableArray *decoders = [NSMutableArray new];
#if __has_include("DFImageManagerKit+GIF.h")
    [decoders addObject:[DFAnimatedImageDecoder new]];
#endif
#if __has_include("DFImageManagerKit+WebP.h")
    [decoders addObject:[DFWebPImageDecoder new]];
#endif
    [decoders addObject:[DFImageDecoder new]];
    [self setSharedDecoder:[[DFCompositeImageDecoder alloc] initWithDecoders:decoders]];
}

+ (nullable id<DFImageDecoding>)sharedDecoder {
    id<DFImageDecoding> decoder;
    OSSpinLockLock(&_lock);
    decoder = _sharedDecoder;
    OSSpinLockUnlock(&_lock);
    return decoder;
}

+ (void)setSharedDecoder:(nullable id<DFImageDecoding>)sharedDecoder {
    OSSpinLockLock(&_lock);
    _sharedDecoder = sharedDecoder;
    OSSpinLockUnlock(&_lock);
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
