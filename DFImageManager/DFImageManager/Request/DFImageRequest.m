//
//  DFImageRequest.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 12/23/14.
//  Copyright (c) 2014 Alexander Grebenyuk. All rights reserved.
//

#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"

@implementation DFImageRequest

- (instancetype)initWithAsset:(id)asset targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    if (self = [super init]) {
        _asset = asset;
        _targetSize = targetSize;
        _contentMode = contentMode;
        _options = [options copy];
    }
    return self;
}

// TODO: Add description

@end
