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

#import "DFImageCacheStoreOperation.h"
#import "DFImageRequestOptions.h"
#import "DFImageResponse.h"
#import <DFCache/DFCache.h>


@interface DFImageCacheStoreOperation ()

@property (nonatomic, getter = isExecuting) BOOL executing;
@property (nonatomic, getter = isFinished) BOOL finished;

@end

@implementation DFImageCacheStoreOperation {
    id _asset;
    DFImageRequestOptions *_options;
    DFImageResponse *_response;
    DFCache *_cache;
}

@synthesize executing = _executing;
@synthesize finished = _finished;

- (instancetype)initWithAsset:(id)asset options:(DFImageRequestOptions *)options response:(id)response cache:(DFCache *)cache {
    if (self = [super init]) {
        _asset = asset;
        _response = response;
        _options = options;
        _cache = cache;
        [self setCacheKeyForAsset:^NSString *(id asset, DFImageRequestOptions *options) {
            if ([asset isKindOfClass:[NSString class]]) {
                return asset;
            } else {
                return nil;
            }
        }];
    }
    return self;
}

- (void)start {
    @synchronized(self) {
        if ([self isCancelled]) {
            [self finish];
            return;
        }
        self.executing = YES;
    }
    
    if (_response) {
        [self storeImageForResponse:_response asset:_asset options:_options];
    }
    [self finish];
}

- (void)storeImageForResponse:(DFImageResponse *)response asset:(id)asset options:(DFImageRequestOptions *)options {
    NSURLResponse *URLResponse = response.userInfo[@"url_response"];
    if (URLResponse && URLResponse.expectedContentLength != response.data.length) {
        return;
    }
    NSString *cacheKey = self.cacheKeyForAsset ? self.cacheKeyForAsset(_asset, _options) : nil;
    switch (options.cacheStoragePolicy) {
        case DFImageCacheStorageAllowed:
            [_cache storeObject:response.image forKey:cacheKey data:response.data];
            break;
        case DFImageCacheStorageAllowedInMemoryOnly:
            [_cache setObject:response.image forKey:cacheKey];
            break;
        default:
            break;
    }
}

#pragma mark - Operation

- (void)finish {
    @synchronized(self) {
        if (_executing) {
            self.executing = NO;
        }
        self.finished = YES;
    }
}

- (void)cancel {
    @synchronized(self) {
        if (self.isCancelled) {
            return;
        }
        [super cancel];
    }
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

@end
