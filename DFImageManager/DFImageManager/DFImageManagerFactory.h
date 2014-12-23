//
//  DFImageManagerFactory.h
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 12/22/14.
//  Copyright (c) 2014 Alexander Grebenyuk. All rights reserved.
//

#import "DFImageManagerFactoryProtocol.h"
#import <Foundation/Foundation.h>


@interface DFImageManagerFactory : NSObject <DFImageManagerFactory>

- (void)registerImageManager:(id<DFImageManager>)imageManager forAssetClass:(Class)assetClass;
- (id<DFImageManager>)imageManagerForAssetClass:(Class)assetClass;

@end
