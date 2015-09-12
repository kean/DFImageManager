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

#pragma mark <DFImageDecoding>

- (nullable UIImage *)imageWithData:(nonnull NSData *)data partial:(BOOL)partial {
    if (!data.length) {
        return nil;
    }
#if __has_include("DFImageManagerKit+GIF.h")
    if ([DFAnimatedImage isAnimatedGIFData:data]) {
        UIImage *image = [DFAnimatedImage animatedImageWithGIFData:data];
        if (image) {
            return image;
        }
    }
#endif
    
#if __has_include("DFImageManagerKit+WebP.h")
    if ([UIImage df_isWebPData:data] && !partial) {
        UIImage *image = [UIImage df_imageWithWebPData:data];
        if (image) {
            return image;
        }
    }
#endif

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
    [self setSharedDecoder:[DFImageDecoder new]];
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
