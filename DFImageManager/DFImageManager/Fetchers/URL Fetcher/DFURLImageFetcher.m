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

#import "DFImageDeserializer.h"
#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"
#import "DFImageResponse.h"
#import "DFOperation.h"
#import "DFURLCacheLookupOperation.h"
#import "DFURLImageFetcher.h"
#import "DFURLResponseDeserializing.h"
#import "DFURLSessionOperation.h"
#import "NSURL+DFImageAsset.h"


@interface DFImageRequest (DFURLImageFetcher)

- (BOOL)_isFileRequest;

@end

@implementation DFImageRequest (DFURLImageFetcher)

- (BOOL)_isFileRequest {
    return [((NSURL *)self.asset) isFileURL];
}

@end


@interface DFURLImageFetcher ()

@property (nonatomic, readonly) NSOperationQueue *queueForCache;
@property (nonatomic, readonly) NSOperationQueue *queueForNetwork;

@end


@interface _DFURLImageFetcherOperation : DFOperation <DFImageManagerOperation>

@property (nonatomic, readonly) DFImageRequest *request;
@property (nonatomic, weak, readonly) DFURLImageFetcher *fetcher;

- (instancetype)initWithRequest:(DFImageRequest *)request fetcher:(DFURLImageFetcher *)fetcher;

@end



@implementation _DFURLImageFetcherOperation {
    DFImageResponse *_response;
    NSOperation *_currentOperation;
}

- (instancetype)initWithRequest:(DFImageRequest *)request fetcher:(DFURLImageFetcher *)fetcher {
    if (self = [super init]) {
        _request = request;
        _fetcher = fetcher;
    }
    return self;
}

#pragma mark - Operation

- (void)start {
    @synchronized(self) {
        if (self.isCancelled) {
            [self finish];
        } else {
            [super start];
            [self _startCacheLookup];
        }
    }
}

- (void)_startCacheLookup {
    NSURLCache *cache = self.fetcher.session.configuration.URLCache;
    if (cache != nil && ![self.request _isFileRequest]) {
        NSURLRequest *URLRequest = [[NSURLRequest alloc] initWithURL:(NSURL *)self.request.asset];
        DFURLCacheLookupOperation *operation =  [[DFURLCacheLookupOperation alloc] initWithRequest:URLRequest cache:cache];
        _DFURLImageFetcherOperation *__weak weakSelf = self;
        DFURLCacheLookupOperation *__weak weakOp = operation;
        [operation setCompletionBlock:^{
            @synchronized(self) {
                [weakSelf _cacheLookupOperationDidComplete:weakOp];
            }
        }];
        operation.queuePriority = self.queuePriority;
        [self.fetcher.queueForCache addOperation:operation];
        _currentOperation = operation;
    } else {
        [self _startFetching];
    }
    
}

- (void)_cacheLookupOperationDidComplete:(DFURLCacheLookupOperation *)operation {
    DFImageResponse *cachedResponse = [operation imageResponse];
    if (cachedResponse.image != nil) {
        _response = cachedResponse;
        [self finish];
    } else {
        [self _startFetching];
    }
}

- (void)_startFetching  {
    if (self.isCancelled) {
        _response = [DFImageResponse emptyResponse];
        [self finish];
    } else {
        DFImageRequest *request = self.request;
        if (request.options.networkAccessAllowed || [request _isFileRequest]) {
            DFURLSessionOperation *operation = [[DFURLSessionOperation alloc] initWithURL:(NSURL *)request.asset session:self.fetcher.session];
            operation.deserializer = [DFImageDeserializer new];
            _DFURLImageFetcherOperation *__weak weakSelf = self;
            DFURLSessionOperation *__weak weakOp = operation;
            [operation setCompletionBlock:^{
                @synchronized(self) {
                    [weakSelf _imageFetchOperationDidComplete:weakOp];
                }
            }];
            operation.queuePriority = self.queuePriority;
            [self.fetcher.queueForNetwork addOperation:operation];
            _currentOperation = operation;
        } else {
            _response = [DFImageResponse emptyResponse];
            [self finish];
        }
    }
}

- (void)_imageFetchOperationDidComplete:(DFURLSessionOperation *)operation {
    DFMutableImageResponse *response = [DFMutableImageResponse new];
    response.image = operation.responseObject;
    response.error = operation.error;
    if (operation.responseObject != nil) {
        response.data = operation.data;
    }
    _response = [response copy];
    [self finish];
}


- (void)cancel {
    @synchronized(self) {
        if (!self.isCancelled) {
            [super cancel];
            [_currentOperation cancel];
        }
    }
}

- (void)setQueuePriority:(NSOperationQueuePriority)queuePriority {
    [super setQueuePriority:queuePriority];
    _currentOperation.queuePriority = queuePriority;
}

#pragma mark - <DFImageManagerOperation>

- (DFImageResponse *)imageResponse {
    return _response;
}

@end



@implementation DFURLImageFetcher {
    NSOperationQueue *_queue;
}

- (instancetype)initWithSession:(NSURLSession *)session {
    if (self = [super init]) {
        NSParameterAssert(session);
        _session = session;
        
        _queue = [NSOperationQueue new];
        
        _queueForCache = [NSOperationQueue new];
        _queueForCache.maxConcurrentOperationCount = 1;
        
        _queueForNetwork = [NSOperationQueue new];
        _queueForNetwork.maxConcurrentOperationCount = 2;
    }
    return self;
}

#pragma mark - <DFImageFetcher>

- (BOOL)canHandleRequest:(DFImageRequest *)request {
    if ([request.asset isKindOfClass:[NSURL class]]) {
        NSURL *URL = (NSURL *)request.asset;
        if ([[[self class] supportedSchemes] containsObject:URL.scheme]) {
            return YES;
        }
    }
    return NO;
}

+ (NSSet *)supportedSchemes {
    static NSSet *schemes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        schemes = [NSSet setWithObjects:@"http", @"https", @"ftp", @"file", nil];
    });
    return schemes;
}

- (NSString *)executionContextIDForRequest:(DFImageRequest *)request {
    return DFExecutionContextIDForRequest(request, [self _keyPathsAffectingExecutionContextIDForRequest:request]);
}

- (NSArray *)_keyPathsAffectingExecutionContextIDForRequest:(DFImageRequest *)request {
    static NSArray *_keyPathsForNetworking;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _keyPathsForNetworking = @[ @"options.networkAccessAllowed" ];
        
    });
    return [request _isFileRequest] ? nil : _keyPathsForNetworking;
}

- (NSOperation<DFImageManagerOperation> *)createOperationForRequest:(DFImageRequest *)request {
    _DFURLImageFetcherOperation *operation = [[_DFURLImageFetcherOperation alloc] initWithRequest:request fetcher:self];
    return operation;
}

- (void)enqueueOperation:(NSOperation<DFImageManagerOperation> *)operation {
    [_queue addOperation:operation];
}

@end
