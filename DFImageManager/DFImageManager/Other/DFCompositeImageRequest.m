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
    NSArray *_requests;
    NSMutableArray *_requestIDs;
    DFImageRequest *_lastFullfilledRequest;
    void (^_handler)(UIImage *, NSDictionary *, BOOL);
}

- (instancetype)initWithRequests:(NSArray *)requests handler:(void (^)(UIImage *, NSDictionary *, BOOL))handler {
    if (self = [super init]) {
        _requests = [requests copy];
        _requestIDs = [NSMutableArray new];
        _imageManager = [DFImageManager sharedManager];
        _handler = [handler copy];
    }
    return self;
}

+ (DFCompositeImageRequest *)requestImageForRequests:(NSArray *)requests handler:(void (^)(UIImage *, NSDictionary *, BOOL))handler {
    DFCompositeImageRequest *request = [[DFCompositeImageRequest alloc] initWithRequests:requests handler:handler];
    [request start];
    return request;
}

- (void)start {
    DFCompositeImageRequest *__weak weakSelf = self;
    for (DFImageRequest *request in _requests) {
        DFImageRequestID *requestID = [self.imageManager requestImageForRequest:request completion:^(UIImage *image, NSDictionary *info) {
            [weakSelf _didFullfillRequest:request image:image info:info];
        }];
        if (requestID != nil) {
            [_requestIDs addObject:requestID];
        }
    }
    if (!_requestIDs.count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_handler) {
                _handler(nil, nil, YES);
            }
        });
    }
}

- (void)_didFullfillRequest:(DFImageRequest *)request image:(UIImage *)image info:(NSDictionary *)info {
    BOOL shouldCallHandler = NO;
    BOOL isLastRequest = NO;
    if (!_lastFullfilledRequest || [_requests indexOfObject:request] > [_requests indexOfObject:_lastFullfilledRequest]) {
        shouldCallHandler = YES;
        _lastFullfilledRequest = request;
    }
    if (request == [_requests lastObject]) {
        isLastRequest = YES;
    }
    if (shouldCallHandler) {
        if (_handler) {
            _handler(image, info, isLastRequest);
        }
    }
}

- (void)cancel {
    _handler = nil;
    for (DFImageRequestID *requestID in _requestIDs) {
        [requestID cancel];
    }
}

- (void)setPriority:(DFImageRequestPriority)priority {
    for (DFImageRequestID *requestID in _requestIDs) {
        [requestID setPriority:priority];
    }
}

@end
