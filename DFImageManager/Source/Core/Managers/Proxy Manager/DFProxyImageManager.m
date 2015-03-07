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

#import "DFImageManagerBlockValueTransformer.h"
#import "DFImageManagerValueTransforming.h"
#import "DFImageRequest.h"
#import "DFProxyImageManager.h"

#define _DF_TRANSFORMED_REQUEST(request) \
({ \
    DFImageRequest *transformedRequest = request; \
    if (_transformer != nil) { \
        transformedRequest = [request copy]; \
        transformedRequest.resource = [_transformer transformedResource:request.resource]; \
    } \
    transformedRequest; \
})


@implementation DFProxyImageManager

@synthesize valueTransformer = _transformer;
@synthesize imageManager = _manager;

- (instancetype)initWithImageManager:(id<DFImageManagingCore>)imageManager {
    self.imageManager = imageManager;
    return self;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    [anInvocation invokeWithTarget:_manager];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return [(NSObject *)_manager methodSignatureForSelector:aSelector];
}

- (void)setValueTransformerWithBlock:(id (^)(id))block {
    self.valueTransformer = [[DFImageManagerBlockValueTransformer alloc] initWithBlock:block];
}

#pragma mark - <DFImageManagingCore>

- (BOOL)canHandleRequest:(DFImageRequest *)request {
    return [_manager canHandleRequest:_DF_TRANSFORMED_REQUEST(request)];
}

- (DFImageRequestID *)requestImageForRequest:(DFImageRequest *)request completion:(void (^)(UIImage *, NSDictionary *))completion {
    return [_manager requestImageForRequest:_DF_TRANSFORMED_REQUEST(request) completion:completion];
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

#pragma mark - <DFImageManaging>

- (DFImageRequestID *)requestImageForResource:(id)resource targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options completion:(void (^)(UIImage *, NSDictionary *))completion {
    return [self requestImageForRequest:[[DFImageRequest alloc] initWithResource:resource targetSize:targetSize contentMode:contentMode options:options] completion:completion];
}

- (DFImageRequestID *)requestImageForResource:(id)resource completion:(void (^)(UIImage *, NSDictionary *))completion {
    return [self requestImageForResource:resource targetSize:DFImageMaximumSize contentMode:DFImageContentModeAspectFill options:nil completion:completion];
}

- (void)startPreheatingImageForResources:(NSArray *)resources targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    [self startPreheatingImagesForRequests:[self _requestsForResources:resources targetSize:targetSize contentMode:contentMode options:options]];
}

- (void)stopPreheatingImagesForResources:(NSArray *)resources targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    [self stopPreheatingImagesForRequests:[self _requestsForResources:resources targetSize:targetSize contentMode:contentMode options:options]];
}

- (NSArray *)_requestsForResources:(NSArray *)resources targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    NSMutableArray *requests = [NSMutableArray new];
    for (id resource in resources) {
        [requests addObject:[[DFImageRequest alloc] initWithResource:resource targetSize:targetSize contentMode:contentMode options:options]];
    }
    return [requests copy];
}

@end
