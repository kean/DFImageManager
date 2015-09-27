// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageFetchingOperation.h"
#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"
#import "DFURLHTTPResponseValidator.h"
#import "DFURLImageFetcher.h"

NSString *const DFURLRequestCachePolicyKey = @"DFURLRequestCachePolicyKey";


#pragma mark - _DFURLFetcherTaskQueue -

static const NSTimeInterval _kTaskExecutionInterval = 0.005; // 5 ms

/*! The _DFURLFetcherTaskQueue serves multiple puproses:
 - Prevents NSURLSession trashing
 - Prevents excessive resuming of tasks during the extremely fast scrolling
 - Limits the possibility of the known system crash http://prod.lists.apple.com/archives/macnetworkprog/2014/Oct/msg00001.html that sometimes reproduces on an older devices. It does NOT reproduce on newer devices.
 */
@interface _DFURLFetcherTaskQueue : NSObject
@end

@implementation _DFURLFetcherTaskQueue {
    NSMutableOrderedSet *_pendingTasks;
    BOOL _executing;
}

- (instancetype)init {
    if (self = [super init]) {
        _pendingTasks = [NSMutableOrderedSet new];
    }
    return self;
}

- (void)resumeTask:(NSURLSessionTask *)task {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_pendingTasks addObject:task];
        [self _setNeedsResumePendingTasks];
    });
}

- (void)cancelTask:(NSURLSessionTask *)task {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_pendingTasks containsObject:task]) {
            [_pendingTasks removeObject:task];
        } else {
            [task cancel];
        }
    });
}

- (void)_setNeedsResumePendingTasks {
    if (!_executing) {
        _executing = YES;
        typeof(self) __weak weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_kTaskExecutionInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf _resumePendingTask];
        });
    }
}

- (void)_resumePendingTask {
    _executing = NO;
    NSURLSessionTask *task = _pendingTasks.firstObject;
    if (task) {
        [task resume];
        [_pendingTasks removeObject:task];
    }
    if (_pendingTasks.count) {
        [self _setNeedsResumePendingTasks];
    }
}

@end


#pragma mark - _DFURLImageFetchOperation -

static inline float _DFSessionTaskPriorityForRequestPriority(DFImageRequestPriority priority) {
    switch (priority) {
        case DFImageRequestPriorityHigh: return 0.25;
        case DFImageRequestPriorityNormal: return 0.5;
        case DFImageRequestPriorityLow: return 0.75;
    }
}

@interface _DFURLImageFetchOperation : NSObject <DFImageFetchingOperation>

@property (nullable, nonatomic, readonly) NSURLSessionTask *task;
@property (nullable, nonatomic, readonly) _DFURLFetcherTaskQueue *queue;

@end

@implementation _DFURLImageFetchOperation

- (nonnull instancetype)initWithTask:(nonnull NSURLSessionTask *)task queue:(nonnull _DFURLFetcherTaskQueue *)queue {
    if (self = [super init]) {
        _task = task;
        _queue = queue;
    }
    return self;
}

- (void)cancelImageFetching {
    [_queue cancelTask:_task];
}

- (void)setImageFetchingPriority:(DFImageRequestPriority)priority {
    _task.priority = _DFSessionTaskPriorityForRequestPriority(priority);
}

@end


#pragma mark - _DFURLSessionDataTaskHandler -

@interface _DFURLSessionDataTaskHandler : NSObject

@property (nullable, nonatomic, copy, readonly) DFImageFetchingProgressHandler progressHandler;
@property (nullable, nonatomic, copy, readonly) DFImageFetchingCompletionHandler completionHandler;
@property (nonnull, nonatomic, readonly) NSMutableData *data;

@end

@implementation _DFURLSessionDataTaskHandler

- (instancetype)initWithProgressHandler:(DFImageFetchingProgressHandler)progressHandler completion:(DFImageFetchingCompletionHandler)completionHandler {
    if (self = [super init]) {
        _progressHandler = [progressHandler copy];
        _completionHandler = [completionHandler copy];
        _data = [NSMutableData new];
    }
    return self;
}

@end


#pragma mark - DFURLImageFetcher -

@interface DFURLImageFetcher ()

@property (nonnull, nonatomic, readonly) _DFURLFetcherTaskQueue *taskQueue;
@property (nonnull, nonatomic, readonly) NSMutableDictionary *sessionTaskHandlers;

@end

@implementation DFURLImageFetcher

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration {
    NSParameterAssert(configuration);
    if (self = [super init]) {
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        _sessionTaskHandlers = [NSMutableDictionary new];
        _taskQueue = [_DFURLFetcherTaskQueue new];
        _supportedSchemes = [NSSet setWithObjects:@"http", @"https", @"ftp", @"file", @"data", nil];
    }
    return self;
}

- (instancetype)init {
    return [self initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
}

#pragma mark <DFImageFetching>

- (BOOL)canHandleRequest:(nonnull DFImageRequest *)request {
    if ([request.resource isKindOfClass:[NSURL class]]) {
        return [self.supportedSchemes containsObject:((NSURL *)request.resource).scheme];
    }
    return NO;
}

- (BOOL)isRequestFetchEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    if (![self isRequestCacheEquivalent:request1 toRequest:request2]) {
        return NO;
    }
    if (request1.options.allowsNetworkAccess != request2.options.allowsNetworkAccess) {
        return NO;
    }
    NSURLRequestCachePolicy defaultCachePolicy = self.session.configuration.requestCachePolicy;
    NSURLRequestCachePolicy requestCachePolicy1 = request1.options.userInfo[DFURLRequestCachePolicyKey] ? [request1.options.userInfo[DFURLRequestCachePolicyKey] unsignedIntegerValue] : defaultCachePolicy;
    NSURLRequestCachePolicy requestCachePolicy2 = request2.options.userInfo[DFURLRequestCachePolicyKey] ? [request2.options.userInfo[DFURLRequestCachePolicyKey] unsignedIntegerValue] : defaultCachePolicy;
    return requestCachePolicy1 == requestCachePolicy2;
}

- (BOOL)isRequestCacheEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    return [(NSURL *)request1.resource isEqual:(NSURL *)request2.resource];
}

- (id<DFImageFetchingOperation>)startOperationWithRequest:(DFImageRequest *)request progressHandler:(DFImageFetchingProgressHandler)progressHandler completion:(DFImageFetchingCompletionHandler)completion {
    NSURLRequest *URLRequest = [self _URLRequestForImageRequest:request];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:URLRequest];
    if (task) {
        @synchronized(self) {
            _sessionTaskHandlers[task] = [[_DFURLSessionDataTaskHandler alloc] initWithProgressHandler:progressHandler completion:completion];
        }
    }
    [_taskQueue resumeTask:task];
    return [[_DFURLImageFetchOperation alloc] initWithTask:task queue:self.taskQueue];
}

- (NSURLRequest *)_URLRequestForImageRequest:(DFImageRequest *)imageRequest {
    NSURLRequest *URLRequest = [self _defaultURLRequestForImageRequest:imageRequest];
    if ([self.delegate respondsToSelector:@selector(URLImageFetcher:URLRequestForImageRequest:URLRequest:)]) {
        URLRequest = [self.delegate URLImageFetcher:self URLRequestForImageRequest:imageRequest URLRequest:URLRequest];
    }
    return URLRequest;
}

- (NSURLRequest *)_defaultURLRequestForImageRequest:(DFImageRequest *)imageRequest {
    NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:(NSURL *)imageRequest.resource];
    DFImageRequestOptions *options = imageRequest.options;
    if (options.userInfo[DFURLRequestCachePolicyKey]) {
        URLRequest.cachePolicy = [options.userInfo[DFURLRequestCachePolicyKey] unsignedIntegerValue];
    } else {
        URLRequest.cachePolicy = options.allowsNetworkAccess ? self.session.configuration.requestCachePolicy : NSURLRequestReturnCacheDataDontLoad;
    }
    return [URLRequest copy];
}

- (nullable id<DFURLResponseValidating>)_responseValidatorForURLRequest:(nonnull NSURLRequest *)URLRequest {
    if ([self.delegate respondsToSelector:@selector(URLImageFetcher:responseValidatorForURLRequest:)]) {
        return [self.delegate URLImageFetcher:self responseValidatorForURLRequest:URLRequest];
    }
    return [URLRequest.URL.scheme hasPrefix:@"http"] ? [DFURLHTTPResponseValidator new] : nil;
}

- (void)removeAllCachedImages {
    [_session.configuration.URLCache removeAllCachedResponses];
}

- (void)invalidate {
    [_session invalidateAndCancel];
}

#pragma mark <NSURLSessionDataTaskDelegate>

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    @synchronized(self) {
        _DFURLSessionDataTaskHandler *handler = _sessionTaskHandlers[dataTask];
        if (handler.progressHandler) {
            handler.progressHandler(data, dataTask.countOfBytesReceived, dataTask.countOfBytesExpectedToReceive);
        }
        [handler.data appendData:data];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    @synchronized(self) {
        _DFURLSessionDataTaskHandler *handler = _sessionTaskHandlers[task];
        NSData *data = handler.data;
        if (data) {
            id<DFURLResponseValidating> validator = [self _responseValidatorForURLRequest:task.currentRequest];
            if (validator && ![validator isValidResponse:task.response data:data error:&error]) {
                data = nil;
            }
        }
        if (handler.completionHandler) {
            handler.completionHandler(data, nil, error);
        }
        [_sessionTaskHandlers removeObjectForKey:task];
    }
}

@end
