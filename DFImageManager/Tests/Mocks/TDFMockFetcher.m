//
//  TDFMockResourceImageFetcher.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 11/07/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "TDFMockFetcher.h"
#import "TDFMockFetchOperation.h"

NSString *TDFMockFetcherDidStartOperationNotification = @"TDFMockFetcherDidStartOperationNotification";

@implementation TDFMockResponse

+ (instancetype)mockWithImage:(UIImage *)image {
    TDFMockResponse *response = [TDFMockResponse new];
    response.image = image;
    return response;
}

+ (instancetype)mockWithImage:(UIImage *)image elapsedTime:(NSTimeInterval)elapsedTime {
    TDFMockResponse *response = [TDFMockResponse new];
    response.image = image;
    response.elapsedTime = elapsedTime;
    return response;
}

+ (instancetype)mockWithError:(NSError *)error elapsedTime:(NSTimeInterval)elapsedTime {
    TDFMockResponse *response = [TDFMockResponse new];
    response.error = error;
    response.elapsedTime = elapsedTime;
    return response;
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

- (nonnull NSOperation *)startOperationWithRequest:(nonnull DFImageRequest *)request progressHandler:(nullable DFImageFetchingProgressHandler)progressHandler completion:(nullable DFImageFetchingCompletionHandler)completion {
    TDFMockFetchOperation *operation = [TDFMockFetchOperation blockOperationWithBlock:^{
        TDFMockResponse *response = _responses[request.resource];
        [NSThread sleepForTimeInterval:response.elapsedTime];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(response.image, response.info, response.error);
            }
        });
    }];
    operation.request = request;
    [_queue addOperation:operation];
    [[NSNotificationCenter defaultCenter] postNotificationName:TDFMockFetcherDidStartOperationNotification object:self userInfo:nil];
    return operation;
}

@end
