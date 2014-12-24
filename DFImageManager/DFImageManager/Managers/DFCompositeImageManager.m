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

#import "DFCompositeImageManager.h"
#import "DFImageRequestID.h"

@implementation DFCompositeImageManager {
    NSMutableDictionary *_imageManagers;
}

- (instancetype)initWithImageManagerFactory:(id<DFImageManagerFactory>)imageManagerFactory {
    if (self = [super init]) {
        _imageManagers = [NSMutableDictionary new];
        _imageManagerFactory = imageManagerFactory;
    }
    return self;
}

- (DFImageRequestID *)requestImageForAsset:(id)asset targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options completion:(void (^)(UIImage *, NSDictionary *))completion {
    id<DFImageManager> imageManager = [self.imageManagerFactory imageManagerForAsset:asset];
    DFImageRequestID *requestID = [imageManager requestImageForAsset:asset targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:options completion:completion];
    if (imageManager != nil && requestID != nil) {
        _imageManagers[requestID] = imageManager;
    }
    return requestID;
}

- (void)cancelRequestWithID:(DFImageRequestID *)requestID {
    [[self _imageManagerForRequestID:requestID] cancelRequestWithID:requestID];
}

- (void)setPriority:(DFImageRequestPriority)priority forRequestWithID:(DFImageRequestID *)requestID {
    [[self _imageManagerForRequestID:requestID] setPriority:priority forRequestWithID:requestID];
}

- (DFImageRequestOptions *)requestOptionsForAsset:(id)asset {
    id<DFImageManager> imageManager = [self.imageManagerFactory imageManagerForAsset:asset];
    return [imageManager requestOptionsForAsset:asset];
}

- (void)startPreheatingImageForAssets:(NSArray *)assets targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    for (id asset in assets) {
        // TODO: Optimize this code.
        id<DFImageManager> imageManager = [self.imageManagerFactory imageManagerForAsset:asset];
        [imageManager startPreheatingImageForAssets:assets targetSize:targetSize contentMode:contentMode options:options];
    }
}

- (void)stopPreheatingImagesForAssets:(NSArray *)assets targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    for (id asset in assets) {
        // TODO: Optimize this code.
        id<DFImageManager> imageManager = [self.imageManagerFactory imageManagerForAsset:asset];
        [imageManager stopPreheatingImagesForAssets:assets targetSize:targetSize contentMode:contentMode options:options];
    }
}

- (void)stopPreheatingImageForAllAssets {
    [_imageManagers enumerateKeysAndObjectsUsingBlock:^(id key, id<DFImageManager> imageManager, BOOL *stop) {
        [imageManager stopPreheatingImageForAllAssets];
    }];
}

#pragma mark -

- (id<DFImageManager>)_imageManagerForRequestID:(DFImageRequestID *)requestID {
    return requestID != nil ? _imageManagers[requestID] : nil;
}

@end
