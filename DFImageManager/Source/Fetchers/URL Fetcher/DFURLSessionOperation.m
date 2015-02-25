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

#import "DFURLResponseDeserializing.h"
#import "DFURLSessionOperation.h"


@implementation DFURLSessionOperation {
    NSURLSessionDataTask *_task;
}

- (instancetype)initWithRequest:(NSURLRequest *)request {
    if (self = [super init]) {
        _request = request;
    }
    return self;
}

#pragma mark - Operation

- (void)start {
    @synchronized(self) {
        [super start];
        if (self.isCancelled) {
            [self finish];
        } else {
            [self _startDataTask];
        }
    }
}

- (void)_startDataTask {
    DFURLSessionOperation *__weak weakSelf = self;
    _task = [self.delegate URLSessionOperation:self dataTaskWithRequest:self.request progressHandler:^(int64_t countOfBytesReceived, int64_t countOfBytesExpectedToReceive) {
        [weakSelf _didUpdateProgressWithCountOfBytesReceived:countOfBytesReceived countOfBytesExpectedToReceive:countOfBytesExpectedToReceive];
    } completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        [weakSelf _didFinishWithData:data response:response error:error];
    }];
    if (_task != nil) {
        [_task resume];
    } else {
        [self finish];
    }
}

- (void)_didUpdateProgressWithCountOfBytesReceived:(int64_t) countOfBytesReceived countOfBytesExpectedToReceive:(int64_t)countOfBytesExpectedToReceive {
    if (self.progressHandler) {
        self.progressHandler(countOfBytesReceived, countOfBytesExpectedToReceive);
    }
}

- (void)_didFinishWithData:(NSData *)data response:(NSURLResponse *)response error:(NSError *)error {
    _data = data;
    _response = response;
    _error = error;
    
    if (error != nil || self.isCancelled) {
        [self finish];
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @autoreleasepool {
                [self _deserializeResponse];
            }
        });
    }
}

- (void)_deserializeResponse {
    NSError *error;
    _responseObject = [_deserializer objectFromResponse:_response data:_data error:&error];
    _error = error;
    [self finish];
}

- (void)finish {
    @synchronized(self) {
        [super finish];
    }
}

- (void)cancel {
    @synchronized(self) {
        if (!self.isCancelled) {
            [super cancel];
            [_task cancel];
        }
    }
}

- (void)setQueuePriority:(NSOperationQueuePriority)queuePriority {
    [super setQueuePriority:queuePriority];
    if ([_task respondsToSelector:@selector(setPriority:)]) {
        _task.priority = [DFURLSessionOperation _taskPriorityForQueuePriority:queuePriority];
    }
}

+ (float)_taskPriorityForQueuePriority:(NSOperationQueuePriority)queuePriority {
    switch (queuePriority) {
        case NSOperationQueuePriorityVeryHigh: return 0.9f;
        case NSOperationQueuePriorityHigh: return 0.7f;
        case NSOperationQueuePriorityNormal: return 0.5f;
        case NSOperationQueuePriorityLow: return 0.3f;
        case NSOperationQueuePriorityVeryLow: return 0.1f;
    }
}

@end


@implementation DFURLSessionOperation (HTTP)

- (NSHTTPURLResponse *)HTTPResponse {
    return [self.response isKindOfClass:[NSHTTPURLResponse class]] ? (id)self.response : nil;
}

@end
