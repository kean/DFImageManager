//
//  DFValueTransformerFactory.h
//  DFCache
//
//  Created by Alexander Grebenyuk on 12/17/14.
//  Copyright (c) 2014 com.github.kean. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DFValueTransformer.h"


@protocol DFValueTransformerFactory <NSObject>

- (id<DFValueTransforming>)valueTransformerForValue:(id)value;

@end


@interface DFValueTransformerFactory : NSObject <DFValueTransformerFactory>

/*! Dependency injector.
 */
+ (id<DFValueTransformerFactory>)defaultFactory;

/*! Dependency injector.
 */
+ (void)setDefaultFactory:(id<DFValueTransformerFactory>)factory;

@end
