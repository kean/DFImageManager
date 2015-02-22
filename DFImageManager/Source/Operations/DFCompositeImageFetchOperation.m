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

#import "DFCompositeImageFetchOperation.h"
#import "DFImageManager.h"
#import "DFImageRequest.h"
#import "DFImageRequestID.h"
#import <objc/runtime.h>


/*! Associated objects are used for better performance, we don't want to create NSMapTable or other structures for each operation.
 */
@interface DFImageRequest (DFCompositeImageFetchOperation)

@property (nonatomic) DFCompositeImageRequestContext *df_compositeContext;

@end

static char *_contextKey;

@implementation DFImageRequest (DFCompositeImageFetchOperation)

- (DFCompositeImageRequestContext *)df_compositeContext {
    return objc_getAssociatedObject(self, &_contextKey);
}

- (void)setDf_compositeContext:(DFCompositeImageRequestContext *)context {
    objc_setAssociatedObject(self, &_contextKey, context, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


@interface DFCompositeImageRequestContext (Protected)

- (void)completeWithImage:(UIImage *)image info:(NSDictionary *)info;

@end

@implementation DFCompositeImageRequestContext

- (instancetype)initWithRequestID:(DFImageRequestID *)requestID {
    if (self = [super init]) {
        _requestID = requestID;
    }
    return self;
}

- (void)completeWithImage:(UIImage *)image info:(NSDictionary *)info {
    _isCompleted = YES;
    _image = image;
    _info = info;
}

@end


@implementation DFCompositeImageFetchOperation {
    void (^_handler)(UIImage *, NSDictionary *, DFImageRequest *);
}

- (instancetype)initWithRequests:(NSArray *)requests handler:(void (^)(UIImage *, NSDictionary *, DFImageRequest *))handler {
    if (self = [super init]) {
        NSParameterAssert(requests.count > 0);
        _requests = [requests copy];
        _handler = [handler copy];

        _imageManager = [DFImageManager sharedManager];
        _allowsObsoleteRequests = YES;
    }
    return self;
}

+ (DFCompositeImageFetchOperation *)requestImageForRequests:(NSArray *)requests handler:(void (^)(UIImage *, NSDictionary *, DFImageRequest *))handler {
    DFCompositeImageFetchOperation *request = [[DFCompositeImageFetchOperation alloc] initWithRequests:requests handler:handler];
    [request start];
    return request;
}

- (NSTimeInterval)elapsedTime {
    return CACurrentMediaTime() - _startTime;
}

- (void)start {
    _startTime = CACurrentMediaTime();
    DFCompositeImageFetchOperation *__weak weakSelf = self;
    for (DFImageRequest *request in _requests) {
        DFImageRequestID *requestID = [self.imageManager requestImageForRequest:request completion:^(UIImage *image, NSDictionary *info) {
            [weakSelf _didFinishRequest:request image:image info:info];
        }];
        request.df_compositeContext = [[DFCompositeImageRequestContext alloc] initWithRequestID:requestID];
    }
}

- (BOOL)isFinished {
    for (DFImageRequest *request in _requests) {
        if (![self contextForRequest:request].isCompleted) {
            return NO;
        }
    }
    return YES;
}

- (DFCompositeImageRequestContext *)contextForRequest:(DFImageRequest *)request {
    return request.df_compositeContext;
}

- (void)cancel {
    _handler = nil;
    [self cancelRequests:_requests];
}

- (void)cancelRequest:(DFImageRequest *)request {
    DFCompositeImageRequestContext *context = [self contextForRequest:request];
    if (!context.isCompleted) {
        [context completeWithImage:nil info:nil];
        [context.requestID cancel];
    }
}

- (void)cancelRequests:(NSArray *)requests {
    for (DFImageRequest *request in requests) {
        [self cancelRequest:request];
    }
}

- (void)setPriority:(DFImageRequestPriority)priority {
    for (DFImageRequest *request in _requests) {
        [[self contextForRequest:request].requestID setPriority:priority];
    }
}

- (void)_didFinishRequest:(DFImageRequest *)request image:(UIImage *)image info:(NSDictionary *)info {
    DFCompositeImageRequestContext *context = [self contextForRequest:request];
    [context completeWithImage:image info:info];
    
    if (self.allowsObsoleteRequests) {
        BOOL isSuccess = [self isRequestSuccessful:request];
        BOOL isObsolete = [self isRequestObsolete:request];
        BOOL isFinal = [self isRequestFinal:request];
        if ((isSuccess && !isObsolete) || isFinal) {
            if (_handler) {
                _handler(image, info, request);
            }
        }
        if (isSuccess) {
            // Iterate through the 'left' subarray and cancel obsolete requests
            for (NSUInteger i = 0; i < [_requests indexOfObject:request]; i++) {
                DFImageRequest *obsoleteRequest = _requests[i];
                if ([self shouldCancelObsoleteRequest:obsoleteRequest]) {
                    [self cancelRequest:obsoleteRequest];
                }
            }
        }
    } else {
        if (_handler) {
            _handler(image, info, request);
        }
    }
}

- (BOOL)isRequestSuccessful:(DFImageRequest *)inputRequest {
    return [self contextForRequest:inputRequest].image != nil;
}

- (BOOL)isRequestObsolete:(DFImageRequest *)inputRequest {
    // Iterate throught the 'right' subarray of requests
    for (NSUInteger i = [_requests indexOfObject:inputRequest] + 1; i < _requests.count; i++) {
        if ([self isRequestSuccessful:_requests[i]]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isRequestFinal:(DFImageRequest *)inputRequest {
    for (DFImageRequest *request in _requests) {
        if (request == inputRequest) {
            continue;
        }
        if (![self contextForRequest:request].isCompleted) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)shouldCancelObsoleteRequest:(DFImageRequest *)request {
    return YES;
}

@end
