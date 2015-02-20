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

#import "DFCompositeImageRequest.h"
#import "DFImageManager.h"
#import "DFImageRequestID.h"


@implementation DFCompositeImageRequest {
    NSMutableArray *_completedRequests;
    NSMapTable *_requestIDs;
    void (^_handler)(UIImage *, NSDictionary *, DFImageRequest *);
    BOOL _isStarted;
}

- (instancetype)initWithRequests:(NSArray *)requests handler:(void (^)(UIImage *, NSDictionary *, DFImageRequest *))handler {
    if (self = [super init]) {
        NSParameterAssert(requests.count > 0);
        _requests = [[NSArray alloc] initWithArray:requests copyItems:YES];
        _handler = [handler copy];
        
        _completedRequests = [NSMutableArray new];
        _requestIDs = [NSMapTable strongToStrongObjectsMapTable];
        
        _imageManager = [DFImageManager sharedManager];
        _allowsObsoleteRequests = YES;
    }
    return self;
}

+ (DFCompositeImageRequest *)requestImageForRequests:(NSArray *)requests handler:(void (^)(UIImage *, NSDictionary *, DFImageRequest *))handler {
    DFCompositeImageRequest *request = [[DFCompositeImageRequest alloc] initWithRequests:requests handler:handler];
    [request start];
    return request;
}

- (NSTimeInterval)elapsedTime {
    return CACurrentMediaTime() - _startTime;
}

- (void)start {
    if (!_isStarted) {
        _isStarted = YES;
        _startTime = CACurrentMediaTime();
        DFCompositeImageRequest *__weak weakSelf = self;
        for (DFImageRequest *request in _requests) {
            DFImageRequestID *requestID = [self.imageManager requestImageForRequest:request completion:^(UIImage *image, NSDictionary *info) {
                [weakSelf _didFinishRequest:request image:image info:info];
            }];
            if (requestID != nil) {
                [_requestIDs setObject:requestID forKey:request];
            }
        }
    }
}

- (void)_didFinishRequest:(DFImageRequest *)request image:(UIImage *)image info:(NSDictionary *)info {
    [_completedRequests addObject:request];
    
    // Iterate through the 'left' subarray and cancel obsolete requests
    if (self.allowsObsoleteRequests) {
        for (NSInteger i = 0; i < [_requests indexOfObject:request]; i++) {
            DFImageRequest *obsoleteRequest = _requests[i];
            if (![_completedRequests containsObject:obsoleteRequest] && [self shouldCancelObsoleteRequest:obsoleteRequest]) {
                [self cancelRequest:obsoleteRequest];
            }
        }
    }
    
    if (!self.allowsObsoleteRequests || [self shouldCallCompletionHandlerForRequest:request image:image info:info]) {
        if (_handler) {
            _handler(image, info, request);
        }
    }
}

- (BOOL)shouldCallCompletionHandlerForRequest:(DFImageRequest *)request image:(UIImage *)image info:(NSDictionary *)info {
    // Iterate throught the 'right' subarray of requests
    for (NSInteger i = [_requests indexOfObject:request] + 1; i < _requests.count; i++) {
        if ([_completedRequests containsObject:_requests[i]]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)shouldCancelObsoleteRequest:(DFImageRequest *)request {
    return YES;
}

- (void)cancel {
    _handler = nil;
    [self cancelRequests:_requests];
}

- (void)cancelRequest:(DFImageRequest *)request {
    [self cancelRequests:(request != nil ? @[ request ] : nil)];
}

- (void)cancelRequests:(NSArray *)requests {
    for (DFImageRequest *request in requests) {
        [((DFImageRequestID *)[_requestIDs objectForKey:request]) cancel];
    }
}

- (void)setPriority:(DFImageRequestPriority)priority {
    for (DFImageRequest *request in _requestIDs) {
        [((DFImageRequestID *)[_requestIDs objectForKey:request]) setPriority:priority];
    }
}

@end
