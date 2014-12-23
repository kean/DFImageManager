//
//  DFImageManagerFactory.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 12/22/14.
//  Copyright (c) 2014 Alexander Grebenyuk. All rights reserved.
//

#import "DFImageManagerFactory.h"

@implementation DFImageManagerFactory {
    NSMutableDictionary *_imageManagers;
}

- (instancetype)init {
    if (self = [super init]) {
        _imageManagers = [NSMutableDictionary new];
    }
    return self;
}

- (void)registerImageManager:(id<DFImageManager>)imageManager forAssetClass:(Class)assetClass {
    if (imageManager != nil && assetClass) {
        _imageManagers[NSStringFromClass(assetClass)] = imageManager;
    }
}

#pragma mark - <DFImageManagerFactory>

- (id<DFImageManager>)imageManagerForAsset:(id)asset {
    id<DFImageManager> __block imageManager;
    [_imageManagers enumerateKeysAndObjectsUsingBlock:^(NSString *key, id<DFImageManager> object, BOOL *stop) {
        if ([asset isKindOfClass:NSClassFromString(key)]) {
            imageManager = object;
            *stop = YES;
        }
    }];
    return imageManager;
}

@end
