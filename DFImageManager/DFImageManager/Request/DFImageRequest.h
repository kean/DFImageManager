//
//  DFImageRequest.h
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 12/23/14.
//  Copyright (c) 2014 Alexander Grebenyuk. All rights reserved.
//

#import "DFImageManagerDefines.h"
#import <Foundation/Foundation.h>

@class DFImageRequestOptions;


@interface DFImageRequest : NSObject

@property (nonatomic, readonly) id asset;
@property (nonatomic, readonly) CGSize targetSize;
@property (nonatomic, readonly) DFImageContentMode contentMode;
@property (nonatomic, readonly) DFImageRequestOptions *options;

- (instancetype)initWithAsset:(id)asset targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options;

@end
