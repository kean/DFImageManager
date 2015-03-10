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

#import "DFImageFetchTask.h"
#import "DFImageManager.h"
#import "DFImageRequest.h"
#import "DFImageRequestID.h"


@interface DFImageFetchContext ()

@property (nonatomic) DFImageRequestID *requestID;

- (void)completeWithImage:(UIImage *)image info:(NSDictionary *)info;

@end

@implementation DFImageFetchContext

- (void)completeWithImage:(UIImage *)image info:(NSDictionary *)info {
    _isCompleted = YES;
    _image = image;
    _info = info;
}

@end


@implementation DFImageFetchTask {
    void (^_handler)(UIImage *, NSDictionary *, DFImageRequest *);
    NSMapTable *_contexts;
    DFImageFetchContext *_context; // Optimization for single request case
}

- (instancetype)initWithRequests:(NSArray *)requests handler:(void (^)(UIImage *, NSDictionary *, DFImageRequest *))handler {
    if (self = [super init]) {
        NSParameterAssert(requests.count > 0);
        _requests = [requests copy];
        _handler = [handler copy];
        if (requests.count > 1) {
            _contexts = [NSMapTable strongToStrongObjectsMapTable];
        }
        _imageManager = [DFImageManager sharedManager];
        _allowsObsoleteRequests = YES;
    }
    return self;
}

- (instancetype)initWithRequest:(DFImageRequest *)request handler:(void (^)(UIImage *, NSDictionary *, DFImageRequest *))handler {
    return [self initWithRequests:(request ? @[request] : nil) handler:handler];
}

+ (DFImageFetchTask *)requestImageForRequests:(NSArray *)requests handler:(void (^)(UIImage *, NSDictionary *, DFImageRequest *))handler {
    DFImageFetchTask *request = [[DFImageFetchTask alloc] initWithRequests:requests handler:handler];
    [request start];
    return request;
}

- (NSTimeInterval)elapsedTime {
    return CACurrentMediaTime() - _startTime;
}

- (void)start {
    _startTime = CACurrentMediaTime();
    DFImageFetchTask *__weak weakSelf = self;
    for (DFImageRequest *request in _requests) {
        DFImageFetchContext *context = [DFImageFetchContext new];
        if (_contexts) {
            [_contexts setObject:context forKey:request];
        } else {
            _context = context;
        }
        context.requestID = [self.imageManager requestImageForRequest:request completion:^(UIImage *image, NSDictionary *info) {
            [weakSelf _didFinishRequest:request image:image info:info];
        }];
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

- (DFImageFetchContext *)contextForRequest:(DFImageRequest *)request {
    if (_contexts) {
        return [_contexts objectForKey:request];
    } else {
        return request == [_requests firstObject] ? _context : nil;
    }
}

- (void)cancel {
    _handler = nil;
    [self cancelRequests:_requests];
}

- (void)cancelRequests:(NSArray *)requests {
    for (DFImageRequest *request in requests) {
        [self cancelRequest:request];
    }
}

- (void)cancelRequest:(DFImageRequest *)request {
    DFImageFetchContext *context = [self contextForRequest:request];
    if (!context.isCompleted) {
        [context completeWithImage:nil info:nil];
        [context.requestID cancel];
    }
}

- (void)setPriority:(DFImageRequestPriority)priority {
    for (DFImageRequest *request in _requests) {
        [[self contextForRequest:request].requestID setPriority:priority];
    }
}

- (void)_didFinishRequest:(DFImageRequest *)request image:(UIImage *)image info:(NSDictionary *)info {
    DFImageFetchContext *context = [self contextForRequest:request];
    [context completeWithImage:image info:info];
    
    if (self.allowsObsoleteRequests) {
        BOOL isSuccess = [self _isRequestSuccessful:request];
        BOOL isObsolete = [self _isRequestObsolete:request];
        BOOL isFinal = [self _isRequestFinal:request];
        if ((isSuccess && !isObsolete) || isFinal) {
            if (_handler) {
                _handler(image, info, request);
            }
        }
        if (isSuccess) {
            // Iterate through the 'left' subarray and cancel obsolete requests
            for (NSUInteger i = 0; i < [_requests indexOfObject:request]; i++) {
                DFImageRequest *obsoleteRequest = _requests[i];
                [self cancelRequest:obsoleteRequest];
            }
        }
    } else {
        if (_handler) {
            _handler(image, info, request);
        }
    }
}

/*! Returns YES if the request is completed successfully. The request is considered successful if the image was fetched.
 @param request Request should be contained by the receiver's array of the requests.
 */
- (BOOL)_isRequestSuccessful:(DFImageRequest *)inputRequest {
    return [self contextForRequest:inputRequest].image != nil;
}

/*! Returns YES if the request is obsolete. The request is considered obsolete if there is at least one successfully completed request in the 'right' subarray of the requests.
 @param request Request should be contained by the receiver's array of the requests.
 */
- (BOOL)_isRequestObsolete:(DFImageRequest *)inputRequest {
    // Iterate throught the 'right' subarray of requests
    for (NSUInteger i = [_requests indexOfObject:inputRequest] + 1; i < _requests.count; i++) {
        if ([self _isRequestSuccessful:_requests[i]]) {
            return YES;
        }
    }
    return NO;
}

/*! Returns YES if all the requests are completed.
 @param request Request should be contained by the receiver's array of the requests.
 */
- (BOOL)_isRequestFinal:(DFImageRequest *)inputRequest {
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

@end
