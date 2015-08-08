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

#import "DFProxyImageManager.h"
#import "DFImageRequest.h"
#import "DFImageTask.h"

/*! The implementation of request transforming that uses a block.
 */
@interface _DFProxyRequestTransformer : NSObject <DFProxyRequestTransforming>

/*! Returns an DFImageManagerBlockValueTransformer instance initialized with a given block.
 */
- (instancetype)initWithBlock:(DFImageRequest *(^)(DFImageRequest *))block NS_DESIGNATED_INITIALIZER;

@end

@implementation _DFProxyRequestTransformer {
    id (^_block)(id);
}

- (instancetype)initWithBlock:(DFImageRequest *(^)(DFImageRequest *))block {
    if (self = [super init]) {
        _block = [block copy];
    }
    return self;
}

#pragma mark - <DFProxyRequestTransforming>

- (DFImageRequest *)transformedRequest:(DFImageRequest *)request {
    return _block(request);
}

@end


#define _DF_TRANSFORMED_REQUEST(request) (_transformer ? [_transformer transformedRequest:[(request) copy]] : (request))

@implementation DFProxyImageManager

@synthesize imageManager = _manager;

- (instancetype)initWithImageManager:(id<DFImageManaging>)imageManager {
    self.imageManager = imageManager;
    return self;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    [anInvocation invokeWithTarget:_manager];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return [(NSObject *)_manager methodSignatureForSelector:aSelector];
}

- (void)setRequestTransformerWithBlock:(DFImageRequest *(^)(DFImageRequest *))block {
    self.transformer = [[_DFProxyRequestTransformer alloc] initWithBlock:block];
}

#pragma mark - <DFImageManaging>

- (BOOL)canHandleRequest:(nonnull DFImageRequest *)request {
    return [_manager canHandleRequest:_DF_TRANSFORMED_REQUEST(request)];
}

- (BOOL)hasCacheWithRequest:(nonnull DFImageRequest *)request {
    NSParameterAssert(request);
    return [_manager hasCacheWithRequest:request];
}

- (DFImageTask *)imageTaskForResource:(id)resource completion:(DFImageRequestCompletion)completion {
    return [self imageTaskForRequest:[DFImageRequest requestWithResource:resource] completion:completion];
}

- (DFImageTask *)imageTaskForRequest:(DFImageRequest *)request completion:(DFImageRequestCompletion)completion {
    return [_manager imageTaskForRequest:_DF_TRANSFORMED_REQUEST(request) completion:completion];
}

- (void)startPreheatingImagesForRequests:(NSArray *)requests {
    [_manager startPreheatingImagesForRequests:[self _transformedRequests:requests]];
}

- (void)stopPreheatingImagesForRequests:(NSArray *)requests {
    [_manager stopPreheatingImagesForRequests:[self _transformedRequests:requests]];
}

- (NSArray *)_transformedRequests:(NSArray *)requests {
    NSMutableArray *transformedRequests = [NSMutableArray new];
    for (DFImageRequest *request in requests) {
        [transformedRequests addObject:_DF_TRANSFORMED_REQUEST(request)];
    }
    return [transformedRequests copy];
}

#pragma mark - Deprecated

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (DFImageTask *)requestImageForResource:(id)resource completion:(DFImageRequestCompletion)completion {
    return [self requestImageForRequest:[DFImageRequest requestWithResource:resource] completion:completion];
}

- (DFImageTask *)requestImageForRequest:(DFImageRequest *)request completion:(DFImageRequestCompletion)completion {
    DFImageTask *task = [self imageTaskForRequest:request completion:completion];
    [task resume];
    return task;
}

#pragma clang diagnostic pop

@end
