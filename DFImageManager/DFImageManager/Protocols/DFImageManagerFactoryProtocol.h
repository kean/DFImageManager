//
//  DFImageManagerFactoryProtocol.h
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 12/22/14.
//  Copyright (c) 2014 Alexander Grebenyuk. All rights reserved.
//

#import "DFImageManagerProtocol.h"
#import <Foundation/Foundation.h>


@protocol DFImageManagerFactory <NSObject>

- (id<DFImageManager>)imageManagerForAsset:(id)asset;

@end
