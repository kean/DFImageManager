//
//  TDFImageFetcher.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 2/28/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "TDFMockImageFetcher.h"
#import "TDFMockResource.h"
#import "TDFTesting.h"


@implementation TDFMockImageFetcher

- (instancetype)init {
    if (self = [super init]) {
        _queue = [NSOperationQueue new];
        _response = [TDFMockImageFetcher successfullResponse];
    }
    return self;
}

- (BOOL)canHandleRequest:(DFImageRequest *)request {
    return [request.resource isKindOfClass:[TDFMockResource class]];
}

- (BOOL)isRequestFetchEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    return [request1.resource isEqual:request2.resource];
}

- (BOOL)isRequestCacheEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    return [request1.resource isEqual:request2.resource];
}

- (NSOperation *)startOperationWithRequest:(DFImageRequest *)request progressHandler:(void (^)(double))progressHandler completion:(void (^)(DFImageResponse *))completion {
    _createdOperationCount++;
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        completion([self.response copy]);
    }];
    [_queue addOperation:operation];
    return operation;
}

+ (DFMutableImageResponse *)successfullResponse {
    return [[DFMutableImageResponse alloc] initWithImage:[TDFTesting testImage]];
}

@end
