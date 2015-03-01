//
//  TDFImageFetcher.h
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 2/28/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "DFImageManagerKit.h"
#import <Foundation/Foundation.h>

/*! The mock implementation of DFImageFetching protocol.
 @note Supports resources of TDFResource class.
 */
@interface TDFMockImageFetcher : NSObject <DFImageFetching>

@property (nonatomic) NSOperationQueue *queue;

@property (nonatomic) DFImageResponse *response;

// For assertions
@property (nonatomic, readonly) NSInteger createdOperationCount;

+ (DFMutableImageResponse *)successfullResponse;

@end
