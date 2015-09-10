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

#import "NSCache+DFImageManager.h"
#import <UIKit/UIKit.h>

@implementation NSCache (DFImageManager)

+ (nonnull NSCache *)df_sharedImageCache {
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
        CGFloat ratio = info.physicalMemory <= (1024 * 1024 * 512 /* 512 Mb */) ? 0.1f : 0.2f;
        recommendedSize = (NSUInteger)MAX(1024 * 1024 * 50 /* 50 Mb */, info.physicalMemory * ratio);
    });
    return recommendedSize;
}

@end
