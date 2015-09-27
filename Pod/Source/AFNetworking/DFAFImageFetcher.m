// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFAFImageFetcher.h"
#import "DFImageFetchingOperation.h"
#import "DFImageManagerDefines.h"
#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"

NSString *const DFAFRequestCachePolicyKey = @"DFAFRequestCachePolicyKey";

static inline float _DFAFSessionTaskPriorityForRequestPriority(DFImageRequestPriority priority) {
    switch (priority) {
        case DFImageRequestPriorityHigh: return 0.25;
        case DFImageRequestPriorityNormal: return 0.5;
        case DFImageRequestPriorityLow: return 0.75;
    }
}

@interface _DFAFImageFetchOperation : NSObject <DFImageFetchingOperation>

@property (nullable, nonatomic, weak, readonly) NSURLSessionTask *task;

@end

@implementation _DFAFImageFetchOperation

- (nonnull instancetype)initWithTask:(nonnull NSURLSessionTask *)task {
    if (self = [super init]) {
        _task = task;
    }
    return self;
}

- (void)cancelImageFetching {
    [_task cancel];
}

- (void)setImageFetchingPriority:(DFImageRequestPriority)priority {
    _task.priority = _DFAFSessionTaskPriorityForRequestPriority(priority);
}

@end


@interface _DFDataTaskDelegate : NSObject

@property (nonatomic, copy) void (^dataTaskDidReceiveDataBlock)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data);

@end

@implementation _DFDataTaskDelegate

@end


@implementation DFAFImageFetcher {
    NSMutableDictionary *_dataTaskDelegates;
}

DF_INIT_UNAVAILABLE_IMPL

- (instancetype)initWithSessionManager:(AFURLSessionManager *)sessionManager {
    if (self = [super init]) {
        _sessionManager = sessionManager;
        _dataTaskDelegates = [NSMutableDictionary new];
        _supportedSchemes = [NSSet setWithObjects:@"http", @"https", @"ftp", @"file", @"data", nil];
        typeof(self) __weak weakSelf = self;
        [sessionManager setDataTaskDidReceiveDataBlock:^(NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data) {
            DFAFImageFetcher *strongSelf = weakSelf;
            if (strongSelf) {
                _DFDataTaskDelegate *delegate;
                @synchronized(strongSelf) {
                    delegate = strongSelf->_dataTaskDelegates[dataTask];
                }
                if (delegate.dataTaskDidReceiveDataBlock) {
                    delegate.dataTaskDidReceiveDataBlock(session, dataTask, data);
                }
            }
        }];
    }
    return self;
}

#pragma mark <DFImageFetching>

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
    if (request1.options.allowsNetworkAccess != request2.options.allowsNetworkAccess) {
        return NO;
    }
    NSURLRequestCachePolicy defaultCachePolicy = self.sessionManager.session.configuration.requestCachePolicy;
    NSURLRequestCachePolicy cachePolicy1 = request1.options.userInfo[DFAFRequestCachePolicyKey] ? [request1.options.userInfo[DFAFRequestCachePolicyKey] unsignedIntegerValue] : defaultCachePolicy;
    NSURLRequestCachePolicy cachePolicy2 = request2.options.userInfo[DFAFRequestCachePolicyKey] ? [request2.options.userInfo[DFAFRequestCachePolicyKey] unsignedIntegerValue] : defaultCachePolicy;
    return cachePolicy1 == cachePolicy2;
}

- (BOOL)isRequestCacheEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    return [(NSURL *)request1.resource isEqual:(NSURL *)request2.resource];
}

- (id<DFImageFetchingOperation>)startOperationWithRequest:(DFImageRequest *)request progressHandler:(DFImageFetchingProgressHandler)progressHandler completion:(DFImageFetchingCompletionHandler)completion {
    NSURLRequest *URLRequest = [self _URLRequestForImageRequest:request];
    typeof(self) __weak weakSelf = self;
    NSURLSessionDataTask *__block task = [self.sessionManager dataTaskWithRequest:URLRequest completionHandler:^(NSURLResponse *URLResponse, NSData *result, NSError *error) {
        DFAFImageFetcher *strongSelf = weakSelf;
        if (strongSelf) {
            @synchronized(strongSelf) {
                [strongSelf->_dataTaskDelegates removeObjectForKey:task];
            }
            if (completion) {
                completion(result, nil, error);
            }
        }
    }];
    // Track progress using dataTaskDidReceiveDataBlock exposed by AFURLSessionManager.
    _DFDataTaskDelegate *dataTaskDelegate = [_DFDataTaskDelegate new];
    dataTaskDelegate.dataTaskDidReceiveDataBlock = ^(NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data) {
        if (progressHandler) {
            progressHandler(data, dataTask.countOfBytesReceived, dataTask.countOfBytesExpectedToReceive);
        }
    };
    @synchronized(self) {
        _dataTaskDelegates[task] = dataTaskDelegate;
    }
    
    [task resume];
    return [[_DFAFImageFetchOperation alloc] initWithTask:task];
}

- (void)removeAllCachedImages {
    [_sessionManager.session.configuration.URLCache removeAllCachedResponses];
}

- (void)invalidate {
    [_sessionManager invalidateSessionCancelingTasks:YES];
}

#pragma mark Support

- (NSURLRequest *)_URLRequestForImageRequest:(DFImageRequest *)imageRequest {
    NSURLRequest *URLRequest = [self _defaultURLRequestForImageRequest:imageRequest];
    if ([self.delegate respondsToSelector:@selector(imageFetcher:URLRequestForImageRequest:URLRequest:)]) {
        URLRequest = [self.delegate imageFetcher:self URLRequestForImageRequest:imageRequest URLRequest:URLRequest];
    }
    return URLRequest;
}

- (NSURLRequest *)_defaultURLRequestForImageRequest:(DFImageRequest *)imageRequest {
    NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:(NSURL *)imageRequest.resource];
    DFImageRequestOptions *options = imageRequest.options;
    if (options.userInfo[DFAFRequestCachePolicyKey]) {
        URLRequest.cachePolicy = [options.userInfo[DFAFRequestCachePolicyKey] unsignedIntegerValue];
    } else {
        URLRequest.cachePolicy = options.allowsNetworkAccess ? self.sessionManager.session.configuration.requestCachePolicy : NSURLRequestReturnCacheDataDontLoad;
    }
    return [URLRequest copy];
}

@end
