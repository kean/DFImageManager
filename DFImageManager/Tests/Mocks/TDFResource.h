//
//  TDFResource.h
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 2/28/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDFResource : NSObject

@property (nonatomic, readonly) NSString *ID;

- (instancetype)initWithID:(NSString *)ID NS_DESIGNATED_INITIALIZER;

+ (instancetype)resourceWithID:(NSString *)ID;

@end
