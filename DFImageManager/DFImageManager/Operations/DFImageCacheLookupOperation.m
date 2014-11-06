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

#import "DFImageCacheLookupOperation.h"
#import "DFImageManagerDefines.h"
#import "DFImageRequestOptions.h"
#import "DFImageResponse.h"
#import <DFCache+DFImage.h>


@interface DFImageCacheLookupOperation ()

@property (nonatomic, getter = isExecuting) BOOL executing;
@property (nonatomic, getter = isFinished) BOOL finished;

@end

@implementation DFImageCacheLookupOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

- (instancetype)initWithAsset:(id)asset options:(DFImageRequestOptions *)options cache:(DFCache *)cache {
   if (self = [super init]) {
      _asset = asset;
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
   
   NSString *cacheKey = self.cacheKeyForAsset ? self.cacheKeyForAsset(_asset, _options) : nil;
   
   DFImageCacheStoragePolicy policy = _options.cacheStoragePolicy;
   
   // Memory cache lookup.
   if (policy == DFImageCacheStorageAllowed ||
       policy == DFImageCacheStorageAllowedInMemoryOnly) {
      UIImage *image = [self.cache.memoryCache objectForKey:cacheKey];
      if (image) {
         _response = [[DFImageResponse alloc] initWithImage:image error:nil source:DFImageSourceMemoryCache];
         [self finish];
         return;
      }
   }
   
   // Disk cache lookup.
   if (policy == DFImageCacheStorageAllowed) {
      UIImage *image = [self.cache cachedImageForKey:cacheKey];
      if (image) {
         _response = [[DFImageResponse alloc] initWithImage:image error:nil source:DFImageSourceDiskCache];
         [self finish];
         return;
      }
   }
   
   [self finish];
}

#pragma mark - <DFImageManagerOperation>

- (DFImageResponse *)imageFetchResponse {
   return _response;
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
