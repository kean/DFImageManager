//
//  DFPHAssetlocalIdentifier.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 12/23/14.
//  Copyright (c) 2014 Alexander Grebenyuk. All rights reserved.
//

#import "DFPHAssetlocalIdentifier.h"
#import <Photos/Photos.h>


@implementation DFPHAssetlocalIdentifier

- (instancetype)initWithIdentifier:(NSString *)identifier {
    if (self = [super init]) {
        _identifier = identifier;
    }
    return self;
}

+ (instancetype)localIdentifierForAsset:(PHAsset *)asset {
    return [[DFPHAssetlocalIdentifier alloc] initWithIdentifier:asset.localIdentifier];
}

@end
