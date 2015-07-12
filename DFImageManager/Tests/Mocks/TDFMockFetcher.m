//
//  TDFMockResourceImageFetcher.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 11/07/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "TDFMockFetcher.h"
#import "TDFMockFetchOperation.h"

@implementation TDFMockResponse

+ (instancetype)mockWithResponse:(DFImageResponse *)response elapsedTime:(NSTimeInterval)elapsedTime {
    TDFMockResponse *mock = [TDFMockResponse new];
    mock.response = response;
    mock.elapsedTime = elapsedTime;
    return mock;
}

+ (instancetype)mockWithResponse:(DFImageResponse *)response {
    return [self mockWithResponse:response elapsedTime:0.01];
}

@end


@implementation TDFMockFetcher  {
    NSMutableDictionary *_responses;
}

- (instancetype)init {
    if (self = [super init]) {
        _queue = [NSOperationQueue new];
        _responses = [NSMutableDictionary new];
    }
    return self;
}

- (void)setResponse:(TDFMockResponse *)response forResource:(NSString *)resource {
    [_responses setObject:response forKey:resource];
}

#pragma mark - DFImageFetching

- (BOOL)canHandleRequest:(DFImageRequest *)request {
    return [request.resource isKindOfClass:[NSString class]];
}

- (BOOL)isRequestFetchEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    return [request1.resource isEqual:request2.resource];
}

- (BOOL)isRequestCacheEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    return [request1.resource isEqual:request2.resource];
}

- (NSOperation *)startOperationWithRequest:(DFImageRequest *)request progressHandler:(void (^)(double))progressHandler completion:(void (^)(DFImageResponse *))completion {
    TDFMockFetchOperation *operation = [TDFMockFetchOperation blockOperationWithBlock:^{
        TDFMockResponse *mock = _responses[request.resource];
        [NSThread sleepForTimeInterval:mock.elapsedTime];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(mock.response);
            }
        });
    }];
    operation.request = request;
    [_queue addOperation:operation];
    return operation;
}

@end
