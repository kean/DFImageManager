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

@interface _DFProxyRequestTransformer : NSObject <DFProxyRequestTransforming>
@end

@implementation _DFProxyRequestTransformer {
    DFImageRequest *(^_block)(DFImageRequest *);
}

- (instancetype)initWithBlock:(DFImageRequest * __nonnull (^ __nonnull)(DFImageRequest * __nonnull))block {
    if (self = [super init]) {
        _block = [block copy];
    }
    return self;
}

- (nonnull DFImageRequest *)transformedRequest:(nonnull DFImageRequest *)request {
    return _block(request);
}

@end


#define _DF_TRANSFORMED_REQUEST(request) (_transformer ? [_transformer transformedRequest:request] : (request))

@implementation DFProxyImageManager

- (nonnull instancetype)initWithImageManager:(nonnull id<DFImageManaging>)imageManager {
    _imageManager = imageManager;
    return self;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    [anInvocation invokeWithTarget:_imageManager];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return [(NSObject *)_imageManager methodSignatureForSelector:aSelector];
}

- (void)setRequestTransformerWithBlock:(DFImageRequest * __nonnull (^ __nullable)(DFImageRequest * __nonnull))block {
    self.transformer = [[_DFProxyRequestTransformer alloc] initWithBlock:block];
}

#pragma mark <DFImageManaging>

- (BOOL)canHandleRequest:(nonnull DFImageRequest *)request {
    return [_imageManager canHandleRequest:_DF_TRANSFORMED_REQUEST(request)];
}

- (nonnull DFImageTask *)imageTaskForResource:(nonnull id)resource completion:(nullable DFImageTaskCompletion)completion {
    return [self imageTaskForRequest:[DFImageRequest requestWithResource:resource] completion:completion];
}

- (nonnull DFImageTask *)imageTaskForRequest:(nonnull DFImageRequest *)request completion:(nullable DFImageTaskCompletion)completion {
    return [_imageManager imageTaskForRequest:_DF_TRANSFORMED_REQUEST(request) completion:completion];
}

- (void)startPreheatingImagesForRequests:(nonnull NSArray *)requests {
    [_imageManager startPreheatingImagesForRequests:[self _transformedRequests:requests]];
}

- (void)stopPreheatingImagesForRequests:(nonnull NSArray *)requests {
    [_imageManager stopPreheatingImagesForRequests:[self _transformedRequests:requests]];
}

- (nonnull NSArray *)_transformedRequests:(nonnull NSArray *)requests {
    NSMutableArray *transformedRequests = [NSMutableArray new];
    for (DFImageRequest *request in requests) {
        [transformedRequests addObject:_DF_TRANSFORMED_REQUEST(request)];
    }
    return [transformedRequests copy];
}

@end
