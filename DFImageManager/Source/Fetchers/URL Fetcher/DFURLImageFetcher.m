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

#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"
#import "DFImageResponse.h"
#import "DFURLHTTPImageDeserializer.h"
#import "DFURLImageDeserializer.h"
#import "DFURLImageFetcher.h"
#import "DFURLImageRequestOptions.h"
#import "DFURLResponseDeserializing.h"
#import "DFURLSessionOperation.h"

NSString *const DFImageInfoURLResponseKey = @"DFImageInfoURLResponseKey";


@interface _DFURLSessionDataTaskHandler : NSObject

@property (nonatomic, copy, readonly) DFURLSessionProgressHandler progressHandler;
@property (nonatomic, copy, readonly) DFURLSessionCompletionHandler completionHandler;
@property (nonatomic, readonly) NSMutableData *data;

- (instancetype)initWithProgressHandler:(DFURLSessionProgressHandler)progressHandler completion:(DFURLSessionCompletionHandler)completion;

@end

@implementation _DFURLSessionDataTaskHandler

- (instancetype)initWithProgressHandler:(DFURLSessionProgressHandler)progressHandler completion:(DFURLSessionCompletionHandler)completionHandler {
    if (self = [super init]) {
        _progressHandler = [progressHandler copy];
        _completionHandler = [completionHandler copy];
        _data = [NSMutableData new];
    }
    return self;
}

@end



@implementation DFURLImageFetcher {
    NSOperationQueue *_queue;
    NSMutableDictionary *_sessionTaskHandlers;
    id<DFURLSessionOperationDelegate> __weak _operationsDelegate;
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration sessionDelegate:(id<NSURLSessionDelegate,DFURLSessionOperationDelegate>)sessionDelegate delegateQueue:(NSOperationQueue *)queue {
    NSParameterAssert(configuration);
    NSParameterAssert(sessionDelegate);
    
    if (self = [super init]) {
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:sessionDelegate delegateQueue:queue];
        _operationsDelegate = sessionDelegate;
        
        _sessionTaskHandlers = [NSMutableDictionary new];
        
        // We don't need to limit concurrent operations for NSURLSession. For more info see https://github.com/kean/DFImageManager/wiki/Image-Caching-Guide
        _queue = [NSOperationQueue new];
        
        _supportedSchemes = [NSSet setWithObjects:@"http", @"https", @"ftp", @"file", @"data", nil];
    }
    return self;
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration {
    return [self initWithSessionConfiguration:configuration sessionDelegate:self delegateQueue:nil];
}

#pragma mark - <DFImageFetching>

- (BOOL)canHandleRequest:(DFImageRequest *)request {
    if ([request.resource isKindOfClass:[NSURL class]]) {
        if ([self.supportedSchemes containsObject:((NSURL *)request.resource).scheme]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isRequestFetchEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    if (![self isRequestCacheEquivalent:request1 toRequest:request2]) {
        return NO;
    }
    DFURLImageRequestOptions *options1 = (id)request1.options;
    DFURLImageRequestOptions *options2 = (id)request2.options;
    return (options1.allowsNetworkAccess == options2.allowsNetworkAccess &&
            options1.cachePolicy == options2.cachePolicy);
}

- (BOOL)isRequestCacheEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    if (request1 == request2) {
        return YES;
    }
    NSURL *URL1 = (NSURL *)request1.resource;
    NSURL *URL2 = (NSURL *)request2.resource;
    return [URL1 isEqual:URL2];
}

- (DFImageRequest *)canonicalRequestForRequest:(DFImageRequest *)request {
    if (!request.options || ![request.options isKindOfClass:[DFURLImageRequestOptions class]]) {
        DFURLImageRequestOptions *options = [[DFURLImageRequestOptions alloc] initWithOptions:request.options];
        NSURLSessionConfiguration *conf = self.session.configuration;
        options.cachePolicy = conf.requestCachePolicy;
        
        DFImageRequest *canonicalRequest = [request copy];
        canonicalRequest.options = options;
        return canonicalRequest;
    }
    return request;
}

- (NSOperation *)startOperationWithRequest:(DFImageRequest *)request progressHandler:(void (^)(double))progressHandler completion:(void (^)(DFImageResponse *))completion {
    DFURLSessionOperation *operation = [self _createOperationForImageRequest:request];
    operation.delegate = _operationsDelegate;
    
    DFURLSessionOperation *__weak weakOp = operation;
    [operation setProgressHandler:^(int64_t countOfBytesReceived, int64_t countOfBytesExpectedToReceive) {
        if (progressHandler) {
            progressHandler((double)countOfBytesReceived / (double)countOfBytesExpectedToReceive);
        }
    }];
    [operation setCompletionBlock:^{
        DFMutableImageResponse *response = [DFMutableImageResponse new];
        response.image = weakOp.responseObject;
        response.error = weakOp.error;
        NSURLResponse *URLResponse = weakOp.response;
        if (URLResponse != nil) {
            response.userInfo = @{ DFImageInfoURLResponseKey : URLResponse };
        }
        completion([response copy]);
    }];
    [_queue addOperation:operation];
    return operation;
}

- (DFURLSessionOperation *)_createOperationForImageRequest:(DFImageRequest *)imageRequest {
    NSURLRequest *URLRequest = [self _URLRequestForImageRequest:imageRequest];
    DFURLSessionOperation *operation = [self _operationForImageRequest:imageRequest URLRequest:URLRequest];
    operation.deserializer = [self _responseDeserializerForImageRequest:imageRequest URLRequest:URLRequest];
    return operation;
}

- (NSURLRequest *)_URLRequestForImageRequest:(DFImageRequest *)imageRequest {
    NSURLRequest *URLRequest = [self _defaultURLRequestForImageRequest:imageRequest];
    if ([self.delegate respondsToSelector:@selector(URLImageFetcher:URLRequestForImageRequest:URLRequest:)]) {
        URLRequest = [self.delegate URLImageFetcher:self URLRequestForImageRequest:imageRequest URLRequest:URLRequest];
    }
    return URLRequest;
}

- (NSURLRequest *)_defaultURLRequestForImageRequest:(DFImageRequest *)imageRequest {
    NSURL *URL = (NSURL *)imageRequest.resource;
    DFURLImageRequestOptions *options = (id)imageRequest.options;
    
    /*! From NSURLSessionConfiguration class reference:
     "In some cases, the policies defined in this configuration may be overridden by policies specified by an NSURLRequest object provided for a task. Any policy specified on the request object is respected unless the session’s policy is more restrictive. For example, if the session configuration specifies that cellular networking should not be allowed, the NSURLRequest object cannot request cellular networking."
     
     Apple doesn't not provide a complete documentation on what NSURLSessionConfiguration options can be overridden by NSURLRequest and in when. So it's best to copy all the options, because the NSURLSession implementation might change in future versons.
     */
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    
    /* Set options that can not be configured by DFURLImageRequestOptions.
     */
    NSURLSessionConfiguration *conf = self.session.configuration;
    request.timeoutInterval = conf.timeoutIntervalForRequest;
    request.networkServiceType = conf.networkServiceType;
    request.allowsCellularAccess = conf.allowsCellularAccess;
    request.HTTPShouldHandleCookies = conf.HTTPShouldSetCookies;
    request.HTTPShouldUsePipelining = conf.HTTPShouldUsePipelining;
    
    /* Set options that can be configured by DFURLImageRequestOptions.
     */
    request.cachePolicy = options.cachePolicy;
    if (!options.allowsNetworkAccess) {
        request.cachePolicy = NSURLRequestReturnCacheDataDontLoad;
    }
    
    return [request copy];
}

- (DFURLSessionOperation *)_operationForImageRequest:(DFImageRequest *)imageRequest URLRequest:(NSURLRequest *)URLRequest {
    if ([self.delegate respondsToSelector:@selector(URLImageFetcher:operationForImageRequest:URLRequest:)]) {
        return [self.delegate URLImageFetcher:self operationForImageRequest:imageRequest URLRequest:URLRequest];
    }
    return [[DFURLSessionOperation alloc] initWithRequest:URLRequest];
}

- (id<DFURLResponseDeserializing>)_responseDeserializerForImageRequest:(DFImageRequest *)imageRequest URLRequest:(NSURLRequest *)URLRequest {
    if ([self.delegate respondsToSelector:@selector(URLImageFetcher:responseDeserializerForImageRequest:URLRequest:)]) {
        return [self.delegate URLImageFetcher:self responseDeserializerForImageRequest:imageRequest URLRequest:URLRequest];
    }
    if ([URLRequest.URL.scheme hasPrefix:@"http"]) {
        return [DFURLHTTPImageDeserializer new];
    } else {
        return [DFURLImageDeserializer new];
    }
}

#pragma mark - <NSURLSessionDataTaskDelegate>

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    @synchronized(self) {
        _DFURLSessionDataTaskHandler *handler = _sessionTaskHandlers[dataTask];
        if (handler.progressHandler) {
            handler.progressHandler(dataTask.countOfBytesReceived, dataTask.countOfBytesExpectedToReceive);
        }
        [handler.data appendData:data];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    @synchronized(self) {
        _DFURLSessionDataTaskHandler *handler = _sessionTaskHandlers[task];
        if (handler.completionHandler) {
            handler.completionHandler(handler.data, task.response, error);
        }
        [_sessionTaskHandlers removeObjectForKey:task];
    }
}

#pragma mark - <DFURLSessionOperationDelegate>

- (NSURLSessionDataTask *)URLSessionOperation:(DFURLSessionOperation *)operation dataTaskWithRequest:(NSURLRequest *)request progressHandler:(DFURLSessionProgressHandler)progressHandler completionHandler:(DFURLSessionCompletionHandler)completionHandler {
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request];
    if (task) {
        @synchronized(self) {
            _sessionTaskHandlers[task] = [[_DFURLSessionDataTaskHandler alloc] initWithProgressHandler:progressHandler completion:completionHandler];
        }
    }
    return task;
}

@end
