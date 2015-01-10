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

#import "DFURLConnectionOperation.h"


@interface DFURLConnectionOperation ()

@property (nonatomic, getter = isExecuting) BOOL executing;
@property (nonatomic, getter = isFinished) BOOL finished;

@end

@implementation DFURLConnectionOperation {
    NSURLSessionDataTask *_task;
}

@synthesize executing = _executing;
@synthesize finished = _finished;

- (instancetype)initWithURL:(NSURL *)URL session:(NSURLSession *)session {
    if (self = [super init]) {
        _URL = URL;
        _session = session;
    }
    return self;
}

#pragma mark - Operation

- (void)start {
    @synchronized(self) {
        if (self.isCancelled) {
            [self finish];
            return;
        }
        self.executing = YES;
        [self _startExecutiong];
    }
}

- (void)_startExecutiong {
    DFURLConnectionOperation *__weak weakSelf = self;
    _task = [self.session dataTaskWithURL:self.URL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        [weakSelf _didFinishWithData:data response:response error:error];
    }];
    if (_task != nil) {
        [_task resume];
    } else {
        [self finish];
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
    if (![_deserializer isValidResponse:_response error:&error]) {
        _error = error;
        [self finish];
        return;
    }
    _responseObject = [_deserializer objectFromResponse:_response data:_data error:&error];
    _error = error;
    [self finish];
}

- (void)finish {
    @synchronized(self) {
        if (_executing) {
            self.executing = NO;
        }
        self.finished = YES;
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

#pragma mark - KVO

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

@end


@implementation DFURLConnectionOperation (HTTP)

- (NSHTTPURLResponse *)HTTPResponse {
    return [self.response isKindOfClass:[NSHTTPURLResponse class]] ? (id)self.response : nil;
}

@end
