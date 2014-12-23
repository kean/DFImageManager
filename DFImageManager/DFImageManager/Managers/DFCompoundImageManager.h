//
//  DFCompoundImageManager.h
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 12/22/14.
//  Copyright (c) 2014 Alexander Grebenyuk. All rights reserved.
//

#import "DFImageManagerFactoryProtocol.h"
#import "DFImageManagerProtocol.h"
#import <Foundation/Foundation.h>

@interface DFCompoundImageManager : NSObject <DFImageManager>

- (instancetype)initWithImageManagerFactory:(id<DFImageManagerFactory>)imageManagerFactory;

@property (nonatomic, readonly) id<DFImageManagerFactory> imageManagerFactory;

@end
