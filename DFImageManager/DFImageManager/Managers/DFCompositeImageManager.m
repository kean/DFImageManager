//
//  DFCompoundImageManager.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 12/22/14.
//  Copyright (c) 2014 Alexander Grebenyuk. All rights reserved.
//

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

- (DFImageRequestID *)requestImageForAsset:(id)asset options:(DFImageRequestOptions *)options completion:(void (^)(UIImage *, NSDictionary *))completion {
    id<DFImageManager> imageManager = [self.imageManagerFactory imageManagerForAsset:asset];
    DFImageRequestID *requestID = [imageManager requestImageForAsset:asset options:options completion:completion];
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

- (void)startPreheatingImageForAssets:(NSArray *)assets options:(DFImageRequestOptions *)options {
    for (id asset in assets) {
        // TODO: Optimize this code.
        id<DFImageManager> imageManager = [self.imageManagerFactory imageManagerForAsset:asset];
        [imageManager startPreheatingImageForAssets:assets options:options];
    }
}

- (void)stopPreheatingImagesForAssets:(NSArray *)assets options:(DFImageRequestOptions *)options {
    for (id asset in assets) {
        // TODO: Optimize this code.
        id<DFImageManager> imageManager = [self.imageManagerFactory imageManagerForAsset:asset];
        [imageManager stopPreheatingImagesForAssets:assets options:options];
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
