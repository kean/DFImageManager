//
//  TDFMockResourceImageFetcher.h
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 11/07/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "DFImageManagerKit.h"
#import <Foundation/Foundation.h>

@class DFImageResponse;

NS_ASSUME_NONNULL_BEGIN

extern NSString *TDFMockFetcherDidStartOperationNotification;

@interface TDFMockResponse : NSObject

@property (nonatomic) NSTimeInterval elapsedTime;
@property (nonatomic) DFImageResponse *response;

+ (instancetype)mockWithResponse:(DFImageResponse *)response;
+ (instancetype)mockWithResponse:(DFImageResponse *)response elapsedTime:(NSTimeInterval)elapsedTime;

@end

/*! Mock used for composite image task tests.
 */
@interface TDFMockFetcher : NSObject <DFImageFetching>

@property (nonatomic, readonly) NSOperationQueue *queue;

- (void)setResponse:(TDFMockResponse *)response forResource:(NSString *)resource;

@end

NS_ASSUME_NONNULL_END
