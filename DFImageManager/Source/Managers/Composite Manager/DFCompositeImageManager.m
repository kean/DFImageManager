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

- (id<DFImageManagingCore>)_managerForRequest:(DFImageRequest *)request {
    for (id<DFImageManagingCore> manager in _managers) {
        if ([manager canHandleRequest:request]) {
            return manager;
        }
    }
    return nil;
}

#pragma mark - <DFImageManagingCore>

- (BOOL)canHandleRequest:(DFImageRequest *)request {
    return [self _managerForRequest:request] != nil;
}

- (DFImageRequestID *)requestImageForRequest:(DFImageRequest *)request completion:(void (^)(UIImage *, NSDictionary *))completion {
    return [[self _managerForRequest:request] requestImageForRequest:request completion:completion];
}

- (void)cancelRequestWithID:(DFImageRequestID *)requestID {
    [requestID cancel];
}

- (void)setPriority:(DFImageRequestPriority)priority forRequestWithID:(DFImageRequestID *)requestID {
    [requestID setPriority:priority];
}

- (void)startPreheatingImagesForRequests:(NSArray *)requests {
    for (DFImageRequest *request in requests) {
        [[self _managerForRequest:request] startPreheatingImagesForRequests:@[request]];
    }
}

- (void)stopPreheatingImagesForRequests:(NSArray *)requests {
    for (DFImageRequest *request in requests) {
        [[self _managerForRequest:request] stopPreheatingImagesForRequests:@[request]];
    }
}

- (void)stopPreheatingImagesForAllRequests {
    for (id<DFImageManagingCore> manager in _managers) {
        [manager stopPreheatingImagesForAllRequests];
    }
}

#pragma mark - <DFImageManaging>

- (DFImageRequestID *)requestImageForAsset:(id)asset targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options completion:(void (^)(UIImage *, NSDictionary *))completion {
    return [self requestImageForRequest:[[DFImageRequest alloc] initWithAsset:asset targetSize:targetSize contentMode:contentMode options:options] completion:completion];
}

- (DFImageRequestID *)requestImageForAsset:(id)asset completion:(void (^)(UIImage *, NSDictionary *))completion {
    return [self requestImageForAsset:asset targetSize:DFImageMaximumSize contentMode:DFImageContentModeAspectFill options:nil completion:completion];
}

- (void)startPreheatingImageForAssets:(NSArray *)assets targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    [self startPreheatingImagesForRequests:[self _requestsForAssets:assets targetSize:targetSize contentMode:contentMode options:options]];
}

- (void)stopPreheatingImagesForAssets:(NSArray *)assets targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    [self stopPreheatingImagesForRequests:[self _requestsForAssets:assets targetSize:targetSize contentMode:contentMode options:options]];
}

- (NSArray *)_requestsForAssets:(NSArray *)assets targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    NSMutableArray *requests = [NSMutableArray new];
    for (id asset in assets) {
        [requests addObject:[[DFImageRequest alloc] initWithAsset:asset targetSize:targetSize contentMode:contentMode options:options]];
    }
    return [requests copy];
}

@end
