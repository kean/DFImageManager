//
//  DFImageManagerImageLoader.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 22/07/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "DFCachedImageResponse.h"
#import "DFImageCaching.h"
#import "DFImageFetching.h"
#import "DFImageManagerDefines.h"
#import "DFImageManagerImageLoader.h"
#import "DFImageProcessing.h"
#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"
#import "DFImageResponse.h"

#if DF_IMAGE_MANAGER_GIF_AVAILABLE
#import "DFImageManagerKit+GIF.h"
#endif


#pragma mark - _DFImageRequestKey

@class _DFImageRequestKey;

@protocol _DFImageRequestKeyOwner <NSObject>

- (BOOL)isImageRequestKey:(_DFImageRequestKey *)key1 equalToKey:(_DFImageRequestKey *)key2;

@end

/*! Make it possible to use DFImageRequest as a key in dictionaries (and dictionary-like structures). Requests may be interpreted differently so we compare them using <DFImageFetching> -isRequestFetchEquivalent:toRequest: method and (optionally) similar <DFImageProcessing> method.
 */
@interface _DFImageRequestKey : NSObject <NSCopying>

@property (nonatomic, readonly) DFImageRequest *request;
@property (nonatomic, readonly) BOOL isCacheKey;
@property (nonatomic, weak, readonly) id<_DFImageRequestKeyOwner> owner;

- (instancetype)initWithRequest:(DFImageRequest *)request isCacheKey:(BOOL)isCacheKey owner:(id<_DFImageRequestKeyOwner>)owner;

@end

@implementation _DFImageRequestKey {
    NSUInteger _hash;
}

- (instancetype)initWithRequest:(DFImageRequest *)request isCacheKey:(BOOL)isCacheKey owner:(id<_DFImageRequestKeyOwner>)owner {
    if (self = [super init]) {
        _request = request;
        _hash = [request.resource hash];
        _isCacheKey = isCacheKey;
        _owner = owner;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSUInteger)hash {
    return _hash;
}

- (BOOL)isEqual:(_DFImageRequestKey *)other {
    if (other == self) {
        return YES;
    }
    if (other.owner != self.owner) {
        return NO;
    }
    return [self.owner isImageRequestKey:self equalToKey:other];
}

@end


#pragma mark - DFImageManagerImageLoaderTask

@class _DFImageLoadOperation;

@interface DFImageManagerImageLoaderTask ()

@property (nonnull, nonatomic, readonly) DFImageRequest *request;
@property (nonnull, nonatomic, copy) void (^progressHandler)(int64_t, int64_t);
@property (nonnull, nonatomic, copy) void (^completionHandler)(DFImageResponse *);

@property (nonatomic, weak) _DFImageLoadOperation *loadOperation;
@property (nonatomic, weak) NSOperation *processOperation;

@property (nonatomic) int64_t totalUnitCount;
@property (nonatomic) int64_t completedUnitCount;

@end

@implementation DFImageManagerImageLoaderTask

- (nonnull instancetype)initWithRequest:(nonnull DFImageRequest *)request {
    if (self = [super init]) {
        _request = request;
    }
    return self;
}

@end


#pragma mark - _DFImageLoadOperation

@interface _DFImageLoadOperation : NSObject

@property (nullable, nonatomic) _DFImageRequestKey *key;
@property (nullable, nonatomic, weak) NSOperation *operation;
@property (nonnull, nonatomic, readonly) NSMutableArray *tasks;
@property (nonatomic) int64_t totalUnitCount;
@property (nonatomic) int64_t completedUnitCount;

@end

@implementation _DFImageLoadOperation

- (nonnull instancetype)init {
    if (self = [super init]) {
        _tasks = [NSMutableArray new];
    }
    return self;
}

- (void)updateOperationPriority {
    if (_operation && _tasks.count) {
        DFImageRequestPriority priority = DFImageRequestPriorityVeryLow;
        for (DFImageManagerImageLoaderTask *task in _tasks) {
            priority = MAX(task.request.options.priority, priority);
        }
        if (_operation.queuePriority != (NSOperationQueuePriority)priority) {
            _operation.queuePriority = (NSOperationQueuePriority)priority;
        }
    }
}

@end


#pragma mark - DFImageManagerImageLoader

#define DFImageCacheKeyCreate(request) [[_DFImageRequestKey alloc] initWithRequest:request isCacheKey:YES owner:self]
#define DFImageLoadKeyCreate(request) [[_DFImageRequestKey alloc] initWithRequest:request isCacheKey:NO owner:self]

@interface DFImageManagerImageLoader () <_DFImageRequestKeyOwner>
@end

@implementation DFImageManagerImageLoader {
    dispatch_queue_t _queue;
    id<DFImageFetching> _fetcher;
    id<DFImageCaching> _cache;
    id<DFImageProcessing> _processor;
    NSOperationQueue *_processingQueue;
    NSMutableDictionary /* _DFImageLoadKey : _DFImageLoadOperation */ *_loadOperations;
    BOOL _fetcherRespondsToCanonicalRequest;
}

- (nonnull instancetype)initWithFetcher:(nonnull id<DFImageFetching>)fetcher cache:(nullable id<DFImageCaching>)cache processor:(nullable id<DFImageProcessing>)processor processingQueue:(nullable NSOperationQueue *)processingQueue {
    if (self = [super init]) {
        _fetcher = fetcher;
        _cache = cache;
        _processor = processor;
        _processingQueue = processingQueue;
        
        _loadOperations = [NSMutableDictionary new];
        _queue = dispatch_queue_create([[NSString stringWithFormat:@"%@-queue-%p", [self class], self] UTF8String], DISPATCH_QUEUE_SERIAL);
        _fetcherRespondsToCanonicalRequest = [_fetcher respondsToSelector:@selector(canonicalRequestForRequest:)];
    }
    return self;
}

- (nonnull DFImageManagerImageLoaderTask *)requestImageForRequest:(nonnull DFImageRequest *)request progressHandler:(void (^ __nonnull)(int64_t, int64_t))progressHandler completion:(void (^ __nonnull)(DFImageResponse * __nullable))completion {
    DFImageManagerImageLoaderTask *loadTask = [[DFImageManagerImageLoaderTask alloc] initWithRequest:request];
    loadTask.progressHandler = progressHandler;
    loadTask.completionHandler = completion;
    
    dispatch_async(_queue, ^{
        _DFImageRequestKey *loadKey = DFImageLoadKeyCreate(request);
        _DFImageLoadOperation *loadOperation = _loadOperations[loadKey];
        if (!loadOperation) {
            loadOperation = [_DFImageLoadOperation new];
            DFImageManagerImageLoader *__weak weakSelf = self;
            loadOperation.operation = [_fetcher startOperationWithRequest:request progressHandler:^(int64_t completedUnitCount, int64_t totalUnitCount) {
                [weakSelf _loadOperation:loadOperation didUpdateProgressWithCompletedUnitCount:completedUnitCount totalUnitCount:totalUnitCount];
            } completion:^(DFImageResponse * __nonnull response) {
                [weakSelf _loadOperation:loadOperation didCompleteWithResponse:response];
            }];
            loadOperation.key = loadKey;
            _loadOperations[loadKey] = loadOperation;
        } else {
            loadTask.progressHandler(loadTask.completedUnitCount, loadTask.totalUnitCount);
        }
        loadTask.loadOperation = loadOperation;
        [loadOperation.tasks addObject:loadTask];
        [loadOperation updateOperationPriority];
        
    });
    return loadTask;
}

- (void)_loadOperation:(nonnull _DFImageLoadOperation *)operation didUpdateProgressWithCompletedUnitCount:(int64_t)completedUnitCount totalUnitCount:(int64_t)totalUnitCount {
    dispatch_async(_queue, ^{
        operation.totalUnitCount = totalUnitCount;
        operation.completedUnitCount = completedUnitCount;
        for (DFImageManagerImageLoaderTask *task in operation.tasks) {
            task.progressHandler(completedUnitCount, totalUnitCount);
        }
    });
}

- (void)_loadOperation:(nonnull _DFImageLoadOperation *)operation didCompleteWithResponse:(nullable DFImageResponse *)response {
    dispatch_async(_queue, ^{
        DFImageManagerImageLoader *__weak weakSelf = self;
        for (DFImageManagerImageLoaderTask *task in operation.tasks) {
            if ([self _shouldProcessResponse:response]) {
                task.processOperation = [self _processResponse:response forRequest:task.request completion:^(DFImageResponse *processedResponse) {
                    // TODO: Should I really dispatch it?
                    dispatch_async(_queue, ^{
                        task.completionHandler(response);
                    });
                }];
            } else {
                [weakSelf _storeResponse:response forRequest:task.request];
                task.completionHandler(response);
            }
        }
        [operation.tasks removeAllObjects];
        [_loadOperations removeObjectForKey:operation.key];
    });
}

- (void)cancelImageLoaderTask:(nullable DFImageManagerImageLoaderTask *)task {
    dispatch_async(_queue, ^{
        _DFImageLoadOperation *loadOperation = task.loadOperation;
        if (loadOperation) {
            [loadOperation.tasks removeObject:task];
            if (loadOperation.tasks.count == 0) {
                [loadOperation.operation cancel];
                [_loadOperations removeObjectForKey:loadOperation.key];
            } else {
                [loadOperation updateOperationPriority];
            }
        }
        [task.processOperation cancel];
    });
}

- (void)updatePriorityForTask:(nullable DFImageManagerImageLoaderTask *)task {
    dispatch_async(_queue, ^{
        [task.loadOperation updateOperationPriority];
    });
}

#pragma mark - Processing

- (NSOperation *)_processResponse:(DFImageResponse *)response forRequest:(nonnull DFImageRequest *)request completion:(void (^__nonnull)(DFImageResponse *processedResponse))completion {
    DFImageManagerImageLoader *__weak weakSelf = self;
    id<DFImageProcessing> processor = _processor;
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        DFImageResponse *processedResponse = [weakSelf cachedResponseForRequest:request];
        if (!processedResponse) {
            UIImage *processedImage = [processor processedImage:response.image forRequest:request];
            processedResponse = [[DFImageResponse alloc] initWithImage:processedImage error:response.error userInfo:response.userInfo];
            [weakSelf _storeResponse:processedResponse forRequest:request];
        }
        completion(processedResponse);
    }];
    [_processingQueue addOperation:operation];
    return operation;
}

- (BOOL)_shouldProcessResponse:(DFImageResponse *)response {
    if (!response.image || !_processor || !_processingQueue) {
        return NO;
    }
#if DF_IMAGE_MANAGER_GIF_AVAILABLE
    if ([response.image isKindOfClass:[DFAnimatedImage class]]) {
        return NO;
    }
#endif
    return YES;
}

#pragma mark - Caching

- (nullable DFImageResponse *)cachedResponseForRequest:(nonnull DFImageRequest *)request {
    return request.options.memoryCachePolicy != DFImageRequestCachePolicyReloadIgnoringCache ? [_cache cachedImageResponseForKey:DFImageCacheKeyCreate(request)].response : nil;
}

- (void)_storeResponse:(nullable DFImageResponse *)response forRequest:(nonnull DFImageRequest *)request {
    if (response.image) {
        DFCachedImageResponse *cachedResponse = [[DFCachedImageResponse alloc] initWithResponse:response expirationDate:(CACurrentMediaTime() + request.options.expirationAge)];
        [_cache storeImageResponse:cachedResponse forKey:DFImageCacheKeyCreate(request)];
    }
}

#pragma mark - Misc

- (nonnull DFImageRequest *)canonicalRequestForRequest:(nonnull DFImageRequest *)request {
    if (_fetcherRespondsToCanonicalRequest) {
        return [[_fetcher canonicalRequestForRequest:[request copy]] copy];
    }
    return [request copy];
}

- (nonnull id<NSCopying>)processingKeyForRequest:(nonnull DFImageRequest *)request {
    return DFImageCacheKeyCreate(request);
}

#pragma mark <_DFImageRequestKeyOwner>

- (BOOL)isImageRequestKey:(_DFImageRequestKey *)lhs equalToKey:(_DFImageRequestKey *)rhs {
    if (lhs.isCacheKey) {
        if (![_fetcher isRequestCacheEquivalent:lhs.request toRequest:rhs.request]) {
            return NO;
        }
        return _processor ? [_processor isProcessingForRequestEquivalent:lhs.request toRequest:rhs.request] : YES;
    } else {
        return [_fetcher isRequestFetchEquivalent:lhs.request toRequest:rhs.request];
    }
}

@end
