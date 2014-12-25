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
#import "DFImageManagerBlockValueTransformer.h"
#import "DFImageRequestID.h"


#define _DF_TRANSFORMED_ASSET(asset) _transformer ? [_transformer transformedAsset:asset] : asset

@implementation DFCompositeImageManager {
    NSMutableArray *_managers;
    NSMutableDictionary *_managersForRequests;
}

@synthesize valueTransformer = _transformer;

- (instancetype)initWithImageManagers:(NSArray *)imageManagers {
    if (self = [super init]) {
        _managersForRequests = [NSMutableDictionary new];
        _managers = [NSMutableArray arrayWithArray:imageManagers];
    }
    return self;
}

- (void)addImageManager:(id<DFImageManager>)imageManager {
    [self addImageManagers:@[imageManager]];
}

- (void)addImageManagers:(NSArray *)imageManagers {
    [_managers addObjectsFromArray:imageManagers];
}

- (void)removeImageManager:(id<DFImageManager>)imageManager {
    [self removeImageManagers:@[imageManager]];
}

- (void)removeImageManagers:(NSArray *)imageManagers {
    [_managers removeObjectsInArray:imageManagers];
}

- (id<DFImageManager>)_managerForAsset:(id)asset {
    for (id<DFImageManager> manager in _managers) {
        if ([manager canHandleAsset:asset]) {
            return manager;
        }
    }
    return nil;
}

#pragma mark - <DFImageManager>

- (BOOL)canHandleAsset:(id)asset {
    asset = _DF_TRANSFORMED_ASSET(asset);
    return [[self _managerForAsset:asset] canHandleAsset:asset];
}

- (DFImageRequestID *)requestImageForAsset:(id)asset targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options completion:(void (^)(UIImage *, NSDictionary *))completion {
    asset = _DF_TRANSFORMED_ASSET(asset);
    id<DFImageManager> imageManager = [self _managerForAsset:asset];
    DFImageRequestID *requestID = [imageManager requestImageForAsset:asset targetSize:targetSize contentMode:contentMode options:options completion:completion];
    if (imageManager != nil && requestID != nil) {
        _managersForRequests[requestID] = imageManager;
    }
    return requestID;
}

- (void)cancelRequestWithID:(DFImageRequestID *)requestID {
    [((id<DFImageManager>)_managersForRequests[requestID]) cancelRequestWithID:requestID];
}

- (void)setPriority:(DFImageRequestPriority)priority forRequestWithID:(DFImageRequestID *)requestID {
    [((id<DFImageManager>)_managersForRequests[requestID]) setPriority:priority forRequestWithID:requestID];
}

- (DFImageRequestOptions *)requestOptionsForAsset:(id)asset {
    return [[self _managerForAsset:asset] requestOptionsForAsset:_DF_TRANSFORMED_ASSET(asset)];
}

- (void)startPreheatingImageForAssets:(NSArray *)assets targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    for (id asset in assets) {
        id transformedAsset = _DF_TRANSFORMED_ASSET(asset);
        id<DFImageManager> imageManager = [self _managerForAsset:transformedAsset];
        if (transformedAsset != nil) {
            [imageManager startPreheatingImageForAssets:@[transformedAsset] targetSize:targetSize contentMode:contentMode options:options];
        }
    }
}

- (void)stopPreheatingImagesForAssets:(NSArray *)assets targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    for (id asset in assets) {
        id transformedAsset = _DF_TRANSFORMED_ASSET(asset);
        id<DFImageManager> imageManager = [self _managerForAsset:transformedAsset];
        if (transformedAsset != nil) {
            [imageManager stopPreheatingImagesForAssets:@[transformedAsset] targetSize:targetSize contentMode:contentMode options:options];
        }
    }
}

- (void)stopPreheatingImageForAllAssets {
    [_managersForRequests enumerateKeysAndObjectsUsingBlock:^(id key, id<DFImageManager> imageManager, BOOL *stop) {
        [imageManager stopPreheatingImageForAllAssets];
    }];
}

#pragma mark -

- (void)setValueTransformerWithBlock:(id (^)(id))block {
    self.valueTransformer = [[DFImageManagerBlockValueTransformer alloc] initWithBlock:block];
}

@end
