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

#import "DFCompositeImageTask.h"
#import "DFImageManager.h"
#import "DFImageRequest.h"
#import "DFImageTask.h"

@implementation DFCompositeImageTask {
    void (^_handler)(UIImage *, NSDictionary *, DFImageRequest *, DFCompositeImageTask *task);
    
    BOOL _isStarted;
    BOOL _isCompletionCalledAtLeastOnce;
    NSMutableArray *_remainingTasks;
    
    DFImageTask *_task; // Optimization for single request case
    NSMapTable *_tasks;
}

- (instancetype)initWithRequests:(NSArray *)requests handler:(void (^)(UIImage *, NSDictionary *, DFImageRequest *, DFCompositeImageTask *))handler {
    if (self = [super init]) {
        NSParameterAssert(requests.count > 0);
        _requests = [requests copy];
        _handler = [handler copy];
        _remainingTasks = [NSMutableArray new];
        if (requests.count > 1) {
            _tasks = [NSMapTable strongToStrongObjectsMapTable];
        }
        _imageManager = [DFImageManager sharedManager];
        _allowsObsoleteRequests = YES;
    }
    return self;
}

- (instancetype)initWithRequest:(DFImageRequest *)request handler:(void (^)(UIImage *, NSDictionary *, DFImageRequest *, DFCompositeImageTask *))handler {
    return [self initWithRequests:@[request] handler:handler];
}

+ (DFCompositeImageTask *)requestImageForRequests:(NSArray *)requests handler:(void (^)(UIImage *, NSDictionary *, DFImageRequest *, DFCompositeImageTask *))handler {
    DFCompositeImageTask *request = [[DFCompositeImageTask alloc] initWithRequests:requests handler:handler];
    [request resume];
    return request;
}

- (void)resume {
    if (_isStarted) {
        return;
    }
    _isStarted = YES;
    DFCompositeImageTask *__weak weakSelf = self;
    for (DFImageRequest *request in _requests) {
        DFImageTask *task = [self.imageManager imageTaskForRequest:request completion:^(UIImage *image, NSDictionary *info) {
            [weakSelf _didFinishRequest:request image:image info:info];
        }];
        if (_tasks) {
            [_tasks setObject:task forKey:request];
        } else {
            _task = task;
        }
        [_remainingTasks addObject:task];
    }
    for (DFImageTask *task in _remainingTasks) {
        [task resume];
    }
}

- (BOOL)isFinished {
    return _isStarted && _remainingTasks.count == 0;
}

- (DFImageTask *)imageTaskForRequest:(DFImageRequest *)request {
    if (_tasks) {
        return [_tasks objectForKey:request];
    } else {
        return request == [_requests firstObject] ? _task : nil;
    }
}

- (void)cancel {
    _handler = nil;
    for (DFImageTask *task in _remainingTasks) {
        [self _cancelTask:task];
    }
}

- (void)_cancelTask:(DFImageTask *)task {
    [_remainingTasks removeObject:task];
    [task cancel];
}

- (void)setPriority:(DFImageRequestPriority)priority {
    for (DFImageRequest *request in _requests) {
        [[self imageTaskForRequest:request] setPriority:priority];
    }
}

- (void)_didFinishRequest:(DFImageRequest *)request image:(UIImage *)image info:(NSDictionary *)info {
    DFImageTask *task = info[DFImageInfoTaskKey];
    if (![_remainingTasks containsObject:task]) {
        return;
    }
    if (self.allowsObsoleteRequests) {
        BOOL isSuccess = [self _isRequestSuccessful:request];
        BOOL isObsolete = [self _isRequestObsolete:request];
        BOOL isFinal = _remainingTasks.count == 1;
        if (isSuccess) {
            // Iterate through the 'left' subarray and cancel obsolete requests
            NSArray *obsoleteTasks = [_remainingTasks objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [_remainingTasks indexOfObject:task])]];
            for (DFImageTask *obsoleteTask in obsoleteTasks) {
                [self _cancelTask:obsoleteTask];
            }
        }
        [_remainingTasks removeObject:task];
        if ((isSuccess && !isObsolete) || (isFinal && !_isCompletionCalledAtLeastOnce)) {
            _isCompletionCalledAtLeastOnce = YES;
            if (_handler) {
                _handler(image, info, request, self);
            }
        }
    } else {
        [_remainingTasks removeObject:task];
        if (_handler) {
            _handler(image, info, request, self);
        }
    }
}

/*! Returns YES if the request is completed successfully.
 @param request Request should be contained by the receiver's array of the requests.
 */
- (BOOL)_isRequestSuccessful:(DFImageRequest *)inputRequest {
    DFImageTask *task = [self imageTaskForRequest:inputRequest];
    return task.state == DFImageTaskStateCompleted && task.error == nil;
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

@end
