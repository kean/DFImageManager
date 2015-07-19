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
    BOOL _isStarted;
    NSMutableOrderedSet *_remainingTasks;
}

- (instancetype)initWithImageTasks:(NSArray *)tasks imageHandler:(DFCompositeImageTaskImageHandler)imageHandler completionHandler:(nullable DFCompositeImageTaskCompletionHandler)completionHandler {
    if (self = [super init]) {
        NSParameterAssert(tasks.count > 0);
        _imageTasks = [tasks copy];
        _remainingTasks = [NSMutableOrderedSet orderedSetWithArray:tasks];
        _imageHandler = [imageHandler copy];
        _completionHandler = [completionHandler copy];
        _allowsObsoleteRequests = YES;
    }
    return self;
}

+ (DFCompositeImageTask *)compositeImageTaskWithRequests:(NSArray *)requests imageHandler:(DFCompositeImageTaskImageHandler)imageHandler completionHandler:(nullable DFCompositeImageTaskCompletionHandler)completionHandler {
    NSParameterAssert(requests.count > 0);
    NSMutableArray *tasks = [NSMutableArray new];
    for (DFImageRequest *request in requests) {
        DFImageTask *task = [[DFImageManager sharedManager] imageTaskForRequest:request completion:nil];
        if (task) {
            [tasks addObject:task];
        }
    }
    return tasks.count ? [[DFCompositeImageTask alloc] initWithImageTasks:tasks imageHandler:imageHandler completionHandler:completionHandler] : nil;
}

- (void)resume {
    if (_isStarted) {
        return;
    }
    _isStarted = YES;
    DFCompositeImageTask *__weak weakSelf = self;
    for (DFImageTask *task in _remainingTasks) {
        DFImageTask *__weak weakTask = task;
        DFImageRequestCompletion completionHandler = task.completionHandler;
        [task setCompletionHandler:^(UIImage *image, NSDictionary *info) {
            [weakSelf _didFinishImageTask:weakTask withImage:image info:info];
            if (completionHandler) {
                completionHandler(image, info);
            }
        }];
    }
    for (DFImageTask *task in [_remainingTasks copy]) {
        [task resume];
    }
}

- (BOOL)isFinished {
    return _remainingTasks.count == 0;
}

- (void)cancel {
    _imageHandler = nil;
    _completionHandler = nil;
    for (DFImageTask *task in [_remainingTasks copy]) {
        [self _cancelTask:task];
    }
}

- (void)setPriority:(DFImageRequestPriority)priority {
    for (DFImageTask *task in _remainingTasks) {
        [task setPriority:priority];
    }
}

- (void)_didFinishImageTask:(DFImageTask *)task withImage:(UIImage *)image info:(NSDictionary *)info {
    if (![_remainingTasks containsObject:task]) {
        return;
    }
    if (self.allowsObsoleteRequests) {
        BOOL isSuccess = [self _isTaskSuccessfull:task];
        BOOL isObsolete = [self _isTaskObsolete:task];
        if (isSuccess) {
            // Iterate through the 'left' subarray and cancel obsolete requests
            NSArray *obsoleteTasks = [_remainingTasks objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [_remainingTasks indexOfObject:task])]];
            for (DFImageTask *obsoleteTask in obsoleteTasks) {
                [self _cancelTask:obsoleteTask];
            }
        }
        [_remainingTasks removeObject:task];
        if (isSuccess && !isObsolete) {
            if (_imageHandler) {
                _imageHandler(image, info, self);
            }
        }
    } else {
        [_remainingTasks removeObject:task];
        if (_imageHandler) {
            _imageHandler(image, info, self);
        }
    }
    if (self.isFinished) {
        if (_completionHandler) {
            _completionHandler(self);
        }
    }
}

- (void)_cancelTask:(DFImageTask *)task {
    [_remainingTasks removeObject:task];
    [task cancel];
}

- (BOOL)_isTaskSuccessfull:(DFImageTask *)task {
    return task.state == DFImageTaskStateCompleted && task.error == nil;

}

/*! Returns YES if the request is obsolete. The request is considered obsolete if there is at least one successfully completed request in the 'right' subarray of the requests.
 */
- (BOOL)_isTaskObsolete:(DFImageTask *)task {
    // Iterate throught the 'right' subarray of tasks
    for (NSUInteger i = [_imageTasks indexOfObject:task] + 1; i < _imageTasks.count; i++) {
        if ([self _isTaskSuccessfull:_imageTasks[i]]) {
            return YES;
        }
    }
    return NO;
}

- (NSArray *)imageRequests {
    NSMutableArray *requests = [NSMutableArray new];
    for (DFImageTask *task in _imageTasks) {
        [requests addObject:task.request];
    }
    return [requests copy];
}

@end
