// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageFetchingOperation.h"
#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"
#import "DFPhotosKitImageFetcher.h"
#import "NSURL+DFPhotosKit.h"
#import <Photos/Photos.h>

@interface _DFPhotosKitImageFetchOperation : NSOperation <DFImageFetchingOperation>

@property (nonatomic, readonly) NSData *result;
@property (nonatomic, readonly) NSDictionary *info;

- (instancetype)initWithResource:(id)resource options:(PHImageRequestOptions *)options NS_DESIGNATED_INITIALIZER;

@end


NSString *const DFPhotosKitVersionKey = @"DFPhotosKitVersionKey";

static inline NSString *_PHAssetLocalIdentifier(id resource) {
    if ([resource isKindOfClass:[PHAsset class]]) {
        return ((PHAsset *)resource).localIdentifier;
    } else {
        return [((NSURL *)resource) df_assetLocalIdentifier];
    }
}

@implementation DFPhotosKitImageFetcher {
    NSOperationQueue *_queue;
}

- (instancetype)init {
    if (self = [super init]) {
        _queue = [NSOperationQueue new];
        _queue.maxConcurrentOperationCount = 2;
    }
    return self;
}

#pragma mark <DFImageFetching>

- (BOOL)canHandleRequest:(DFImageRequest *)request {
    id asset = request.resource;
    if ([asset isKindOfClass:[PHAsset class]]) {
        return YES;
    }
    if ([asset isKindOfClass:[NSURL class]]) {
        if ([((NSURL *)asset).scheme isEqualToString:DFPhotosKitURLScheme]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isRequestFetchEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    if (![self isRequestCacheEquivalent:request1 toRequest:request2]) {
        return NO;
    }
    return (request1.options.allowsNetworkAccess == request2.options.allowsNetworkAccess);
}

- (BOOL)isRequestCacheEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    if ([request1.resource isKindOfClass:[PHAsset class]] &&
        [request2.resource isKindOfClass:[PHAsset class]]) {
        // Comparing PHAsset's directly is much faster then getting their localIdentifiers.
        if (![request1.resource isEqual:request2.resource]) {
            return NO;
        }
    } else if (![_PHAssetLocalIdentifier(request1.resource) isEqualToString:_PHAssetLocalIdentifier(request2.resource)]) {
        return NO;
    }
    PHImageRequestOptionsVersion version1 = [self _imageVersionFromUserInfo:request1.options.userInfo];
    PHImageRequestOptionsVersion version2 = [self _imageVersionFromUserInfo:request2.options.userInfo];
    return version1 == version2;
}

- (nonnull NSOperation *)startOperationWithRequest:(nonnull DFImageRequest *)request progressHandler:(nullable DFImageFetchingProgressHandler)progressHandler completion:(nullable DFImageFetchingCompletionHandler)completion {
    PHImageRequestOptions *requestOptions = [PHImageRequestOptions new];
    requestOptions.networkAccessAllowed = request.options.allowsNetworkAccess;
    requestOptions.version = [self _imageVersionFromUserInfo:request.options.userInfo];
    requestOptions.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info){
        if (progressHandler) {
            int64_t totalUnitCount = 1000;
            progressHandler(nil, (int64_t)progress * totalUnitCount, totalUnitCount);
        }
    };
    
    id resource = request.resource;
    if ([resource isKindOfClass:[NSURL class]]) {
        resource = [((NSURL *)resource) df_assetLocalIdentifier];
    }
    
    _DFPhotosKitImageFetchOperation *operation = [[_DFPhotosKitImageFetchOperation alloc] initWithResource:resource options:requestOptions];
    _DFPhotosKitImageFetchOperation *__weak weakOp = operation;
    operation.completionBlock = ^{
        if (completion) {
            completion(weakOp.result, weakOp.info, nil);
        }
    };
    [_queue addOperation:operation];
    return operation;
}

- (PHImageRequestOptionsVersion)_imageVersionFromUserInfo:(NSDictionary *)info {
    NSNumber *version = info[DFPhotosKitVersionKey];
    return version ? version.integerValue : PHImageRequestOptionsVersionCurrent;
}

@end


static inline NSOperationQueuePriority _DFQueuePriorityForRequestPriority(DFImageRequestPriority priority) {
    switch (priority) {
        case DFImageRequestPriorityHigh: return NSOperationQueuePriorityHigh;
        case DFImageRequestPriorityNormal: return NSOperationQueuePriorityNormal;
        case DFImageRequestPriorityLow: return NSOperationQueuePriorityLow;
    }
}

@interface _DFPhotosKitImageFetchOperation ()

@property (nonatomic, getter = isExecuting) BOOL executing;
@property (nonatomic, getter = isFinished) BOOL finished;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithResource:(id)resource options:(PHImageRequestOptions *)options NS_DESIGNATED_INITIALIZER;

@end

@implementation _DFPhotosKitImageFetchOperation {
    PHAsset *_asset;
    NSString *_localIdentifier;
    PHImageRequestOptions *_options;
    PHImageRequestID _requestID;
}

@synthesize executing = _executing;
@synthesize finished = _finished;

DF_INIT_UNAVAILABLE_IMPL

- (instancetype)initWithResource:(id)resource options:(PHImageRequestOptions *)options {
    if (self = [super init]) {
        if ([resource isKindOfClass:[PHAsset class]]) {
            _asset = (PHAsset *)resource;
        } else if ([resource isKindOfClass:[NSString class]]) {
            _localIdentifier = (NSString *)resource;
        }
        _options = options;
        _requestID = PHInvalidImageRequestID;
    }
    return self;
}

- (void)start {
    @synchronized(self) {
        self.executing = YES;
        if (self.isCancelled) {
            [self finish];
        } else {
            [self _fetch];
        }
    }
}

- (void)finish {
    if (_executing) {
        self.executing = NO;
    }
    self.finished = YES;
}

- (void)_fetch {
    if (!_asset && _localIdentifier) {
        if (_localIdentifier) {
            _asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[_localIdentifier] options:nil].firstObject;
        }
    }
    if (!self.isCancelled) {
        typeof(self) __weak weakSelf = self;
        _requestID = [[PHImageManager defaultManager] requestImageDataForAsset:_asset options:_options resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
            [weakSelf _didFetchImageData:imageData info:info];
        }];
    } else {
        [self finish];
    }
}

- (void)_didFetchImageData:(NSData *)result info:(NSDictionary *)info {
    @synchronized(self) {
        if (!self.isCancelled) {
            _result = result;
            _info = info;
            [self finish];
        }
    }
}

- (void)cancel {
    @synchronized(self) {
        if (!self.isCancelled && !self.isFinished) {
            [super cancel];
            if (_requestID != PHInvalidImageRequestID) {
                /*! From Apple docs: "If the request is cancelled, resultHandler may not be called at all.", that's why all the mess.
                 */
                [[PHImageManager defaultManager] cancelImageRequest:_requestID];
                [self finish];
            }
        }
    }
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

#pragma mark - <DFImageFetchingOperation>

- (void)cancelImageFetching {
    [self cancel];
}

- (void)setImageFetchingPriority:(DFImageRequestPriority)priority {
    self.queuePriority = _DFQueuePriorityForRequestPriority(priority);
}

@end
