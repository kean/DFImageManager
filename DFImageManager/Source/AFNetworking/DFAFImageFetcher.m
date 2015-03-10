// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "DFAFImageDeserializer.h"
#import "DFAFImageFetcher.h"
#import "DFAFImageRequestOptions.h"
#import "DFImageManagerDefines.h"
#import "DFImageRequest.h"
#import "DFImageResponse.h"


@interface _DFAFOperation : NSOperation

@property (nonatomic, copy) void (^cancellationHandler)(void);
@property (nonatomic, copy) void (^priorityHandler)(NSOperationQueuePriority priority);

@end

@implementation _DFAFOperation

- (void)cancel {
    @synchronized(self) {
        if (!self.isCancelled) {
            [super cancel];
            if (self.cancellationHandler) {
                self.cancellationHandler();
            }
        }
    }
}

- (void)setQueuePriority:(NSOperationQueuePriority)queuePriority {
    [super setQueuePriority:queuePriority];
    if (self.priorityHandler) {
        self.priorityHandler(queuePriority);
    }
}

@end


@implementation DFAFImageFetcher

- (instancetype)initWithSessionManager:(AFURLSessionManager *)sessionManager {
    if (self = [super init]) {
        _sessionManager = sessionManager;
        _supportedSchemes = [NSSet setWithObjects:@"http", @"https", @"ftp", @"file", @"data", nil];
    }
    return self;
}

#pragma mark - <DFImageFetching>

- (BOOL)canHandleRequest:(DFImageRequest *)request {
    if ([request.resource isKindOfClass:[NSURL class]]) {
        return [self.supportedSchemes containsObject:((NSURL *)request.resource).scheme];
    }
    return NO;
}

- (BOOL)isRequestFetchEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    if (![self isRequestCacheEquivalent:request1 toRequest:request2]) {
        return NO;
    }
    DFAFImageRequestOptions *options1 = (id)request1.options;
    DFAFImageRequestOptions *options2 = (id)request2.options;
    return (options1.allowsNetworkAccess == options2.allowsNetworkAccess && options1.cachePolicy == options2.cachePolicy);
}

- (BOOL)isRequestCacheEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    return request1 == request2 || [(NSURL *)request1.resource isEqual:(NSURL *)request2.resource];
}

- (DFImageRequest *)canonicalRequestForRequest:(DFImageRequest *)request {
    if (!request.options || ![request.options isKindOfClass:[DFAFImageRequestOptions class]]) {
        DFAFImageRequestOptions *options = [[DFAFImageRequestOptions alloc] initWithOptions:request.options];
        options.cachePolicy = self.sessionManager.session.configuration.requestCachePolicy;
        request.options = options;
    }
    return request;
}

- (NSOperation *)startOperationWithRequest:(DFImageRequest *)request progressHandler:(void (^)(double))progressHandler completion:(void (^)(DFImageResponse *))completion {
    NSURLRequest *URLRequest = [self _URLRequestForImageRequest:request];
    NSURLSessionDataTask *task = [self.sessionManager dataTaskWithRequest:URLRequest completionHandler:^(NSURLResponse *URLResponse, UIImage *result, NSError *error) {
        if (completion) {
            completion([[DFImageResponse alloc] initWithImage:result error:error userInfo:nil]);
        }
    }];
    [task resume];
    
    _DFAFOperation *operation = [_DFAFOperation new];
    operation.cancellationHandler = ^{
        [task cancel];
    };
    operation.priorityHandler = ^(NSOperationQueuePriority priority){
        task.priority = [DFAFImageFetcher _taskPriorityForQueuePriority:priority];
    };
    return operation;
}

- (NSURLRequest *)_URLRequestForImageRequest:(DFImageRequest *)imageRequest {
    NSURLRequest *URLRequest = [self _defaultURLRequestForImageRequest:imageRequest];
    if ([self.delegate respondsToSelector:@selector(imageFetcher:URLRequestForImageRequest:URLRequest:)]) {
        URLRequest = [self.delegate imageFetcher:self URLRequestForImageRequest:imageRequest URLRequest:URLRequest];
    }
    return URLRequest;
}

- (NSURLRequest *)_defaultURLRequestForImageRequest:(DFImageRequest *)imageRequest {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:(NSURL *)imageRequest.resource];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    DFAFImageRequestOptions *options = (id)imageRequest.options;
    request.cachePolicy = options.allowsNetworkAccess ? options.cachePolicy : NSURLRequestReturnCacheDataDontLoad;
    return [request copy];
}

+ (float)_taskPriorityForQueuePriority:(NSOperationQueuePriority)queuePriority {
    switch (queuePriority) {
        case NSOperationQueuePriorityVeryHigh: return 0.9f;
        case NSOperationQueuePriorityHigh: return 0.7f;
        case NSOperationQueuePriorityNormal: return 0.5f;
        case NSOperationQueuePriorityLow: return 0.3f;
        case NSOperationQueuePriorityVeryLow: return 0.1f;
    }
}

@end
