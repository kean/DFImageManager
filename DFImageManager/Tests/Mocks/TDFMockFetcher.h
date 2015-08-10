//
//  TDFMockResourceImageFetcher.h
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 11/07/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "DFImageManagerKit.h"
#import <Foundation/Foundation.h>

extern NSString *TDFMockFetcherDidStartOperationNotification;

@interface TDFMockResponse : NSObject

@property (nonatomic) NSTimeInterval elapsedTime;
@property (nonatomic) NSData *data;
@property (nonatomic) NSError *error;
@property (nonatomic) NSDictionary *info;

+ (instancetype)mockWithData:(NSData *)data;
+ (instancetype)mockWithData:(NSData *)data elapsedTime:(NSTimeInterval)elapsedTime;
+ (instancetype)mockWithError:(NSError *)error elapsedTime:(NSTimeInterval)elapsedTime;

@end

/*! Mock used for composite image task tests.
 */
@interface TDFMockFetcher : NSObject <DFImageFetching>

@property (nonatomic, readonly) NSOperationQueue *queue;

- (void)setResponse:(TDFMockResponse *)response forResource:(NSString *)resource;

@end
