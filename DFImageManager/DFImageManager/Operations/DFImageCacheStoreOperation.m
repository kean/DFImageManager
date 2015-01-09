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

#import "DFImageCacheStoreOperation.h"
#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"
#import "DFImageResponse.h"
#import <DFCache/DFCache.h>


@interface DFImageCacheStoreOperation ()

@property (nonatomic, getter = isExecuting) BOOL executing;
@property (nonatomic, getter = isFinished) BOOL finished;

@end

@implementation DFImageCacheStoreOperation {
    DFCache *_cache;
}

@synthesize executing = _executing;
@synthesize finished = _finished;

- (instancetype)initWithAssetID:(NSString *)assetID request:(DFImageRequest *)request response:(DFImageResponse *)response cache:(DFCache *)cache {
    if (self = [super init]) {
        _assetID = assetID;
        _request = request;
        _response = response;
        _cache = cache;
    }
    return self;
}

- (void)start {
    if ([self isCancelled]) {
        [self finish];
        return;
    }
    self.executing = YES;
    [self _storeImage];
    [self finish];
}

- (void)_storeImage {
    // TODO: Remove need to test url_response!!
    NSURLResponse *URLResponse = self.response.userInfo[@"url_response"];
    if (URLResponse != nil && URLResponse.expectedContentLength != self.response.data.length) {
        return;
    }
    NSString *cacheKey = self.assetID;
    DFImageRequestOptions *options = self.request.options;
    
    switch (options.cacheStoragePolicy) {
        case DFImageCacheStorageAllowed:
            [_cache storeObject:self.response.image forKey:cacheKey data:self.response.data];
            break;
        case DFImageCacheStorageAllowedInMemoryOnly:
            [_cache setObject:self.response.image forKey:cacheKey];
            break;
        default:
            break;
    }
}

#pragma mark - Operation

- (void)finish {
    if (_executing) {
        self.executing = NO;
    }
    self.finished = YES;
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
