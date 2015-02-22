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

#import "DFCompositeImageManager.h"
#import "DFImageRequest.h"
#import "DFImageRequestID.h"


#define DFManagerForRequest(request) \
({ \
    id<DFImageManagingCore> outManager; \
    for (id<DFImageManagingCore> manager in _managers) { \
        if ([manager canHandleRequest:request]) { \
            outManager = manager; \
            break; \
        } \
    } \
    outManager; \
})

@implementation DFCompositeImageManager {
    NSMutableArray /* id<DFImageManagingCore> */ *_managers;
}

- (instancetype)initWithImageManagers:(NSArray *)imageManagers {
    if (self = [super init]) {
        _managers = [NSMutableArray arrayWithArray:imageManagers];
    }
    return self;
}

- (void)addImageManager:(id<DFImageManagingCore>)imageManager {
    [self addImageManagers:@[imageManager]];
}

- (void)addImageManagers:(NSArray *)imageManagers {
    [_managers addObjectsFromArray:imageManagers];
}

- (void)removeImageManager:(id<DFImageManagingCore>)imageManager {
    [self removeImageManagers:@[imageManager]];
}

- (void)removeImageManagers:(NSArray *)imageManagers {
    [_managers removeObjectsInArray:imageManagers];
}

#pragma mark - <DFImageManagingCore>

- (BOOL)canHandleRequest:(DFImageRequest *)request {
    return DFManagerForRequest(request) != nil;
}

- (DFImageRequestID *)requestImageForRequest:(DFImageRequest *)request completion:(void (^)(UIImage *, NSDictionary *))completion {
    return [DFManagerForRequest(request) requestImageForRequest:request completion:completion];
}

- (void)cancelRequestWithID:(DFImageRequestID *)requestID {
    [requestID cancel];
}

- (void)setPriority:(DFImageRequestPriority)priority forRequestWithID:(DFImageRequestID *)requestID {
    [requestID setPriority:priority];
}

- (void)startPreheatingImagesForRequests:(NSArray *)requests {
    for (DFImageRequest *request in requests) {
        [DFManagerForRequest(request) startPreheatingImagesForRequests:@[request]];
    }
}

- (void)stopPreheatingImagesForRequests:(NSArray *)requests {
    for (DFImageRequest *request in requests) {
        [DFManagerForRequest(request) stopPreheatingImagesForRequests:@[request]];
    }
}

- (void)stopPreheatingImagesForAllRequests {
    for (id<DFImageManagingCore> manager in _managers) {
        [manager stopPreheatingImagesForAllRequests];
    }
}

#pragma mark - <DFImageManaging>

- (DFImageRequestID *)requestImageForResource:(id)resource targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options completion:(void (^)(UIImage *, NSDictionary *))completion {
    return [self requestImageForRequest:[[DFImageRequest alloc] initWithResource:resource targetSize:targetSize contentMode:contentMode options:options] completion:completion];
}

- (DFImageRequestID *)requestImageForResource:(id)resource completion:(void (^)(UIImage *, NSDictionary *))completion {
    return [self requestImageForResource:resource targetSize:DFImageMaximumSize contentMode:DFImageContentModeAspectFill options:nil completion:completion];
}

- (void)startPreheatingImageForResources:(NSArray *)resource targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    [self startPreheatingImagesForRequests:[self _requestsForResources:resource targetSize:targetSize contentMode:contentMode options:options]];
}

- (void)stopPreheatingImagesForResources:(NSArray *)resource targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    [self stopPreheatingImagesForRequests:[self _requestsForResources:resource targetSize:targetSize contentMode:contentMode options:options]];
}

- (NSArray *)_requestsForResources:(NSArray *)resources targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    NSMutableArray *requests = [NSMutableArray new];
    for (id resource in resources) {
        [requests addObject:[[DFImageRequest alloc] initWithResource:resource targetSize:targetSize contentMode:contentMode options:options]];
    }
    return [requests copy];
}

@end
