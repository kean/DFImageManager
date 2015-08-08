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
@property (nonatomic) UIImage *image;
@property (nonatomic) NSError *error;
@property (nonatomic) NSDictionary *info;

+ (instancetype)mockWithImage:(UIImage *)image;
+ (instancetype)mockWithImage:(UIImage *)image elapsedTime:(NSTimeInterval)elapsedTime;
+ (instancetype)mockWithError:(NSError *)error elapsedTime:(NSTimeInterval)elapsedTime;

@end

/*! Mock used for composite image task tests.
 */
@interface TDFMockFetcher : NSObject <DFImageFetching>

@property (nonatomic, readonly) NSOperationQueue *queue;

- (void)setResponse:(TDFMockResponse *)response forResource:(NSString *)resource;

@end
