//
//  DFPHAssetlocalIdentifier.h
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 12/23/14.
//  Copyright (c) 2014 Alexander Grebenyuk. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PHAsset;


@interface DFPHAssetlocalIdentifier : NSObject

@property (nonatomic, readonly) NSString *identifier;

- (instancetype)initWithIdentifier:(NSString *)identifier;
+ (instancetype)localIdentifierForAsset:(PHAsset *)asset;

@end
