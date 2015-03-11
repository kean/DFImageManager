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

#import "DFPhotosKitImageFetchOperation.h"
#import <Photos/Photos.h>

@interface DFPhotosKitImageFetchOperation ()

@property (nonatomic, getter = isExecuting) BOOL executing;
@property (nonatomic, getter = isFinished) BOOL finished;

@end

@implementation DFPhotosKitImageFetchOperation {
    PHAsset *_asset;
    NSString *_localIdentifier;
    CGSize _targetSize;
    PHImageContentMode _contentMode;
    PHImageRequestOptions *_options;
    PHImageRequestID _requestID;
}

@synthesize executing = _executing;
@synthesize finished = _finished;

- (instancetype)initWithResource:(id)resource targetSize:(CGSize)targetSize contentMode:(PHImageContentMode)contentMode options:(PHImageRequestOptions *)options {
    if (self = [super init]) {
        if ([resource isKindOfClass:[PHAsset class]]) {
            _asset = (PHAsset *)resource;
        } else if ([resource isKindOfClass:[NSString class]]) {
            _localIdentifier = (NSString *)resource;
        }
        _targetSize = targetSize;
        _contentMode = contentMode;
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
            _asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[_localIdentifier] options:nil] firstObject];
        }
    }
    if (!self.isCancelled) {
        DFPhotosKitImageFetchOperation *__weak weakSelf = self;
        _requestID = [[PHImageManager defaultManager] requestImageForAsset:_asset targetSize:_targetSize contentMode:_contentMode options:_options resultHandler:^(UIImage *result, NSDictionary *info) {
            result = result ? [UIImage imageWithCGImage:result.CGImage scale:[UIScreen mainScreen].scale orientation:result.imageOrientation] : nil;
            [weakSelf _didFetchImage:result info:info];
        }];
    } else {
        [self finish];
    }
}

- (void)_didFetchImage:(UIImage *)result info:(NSDictionary *)info {
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

@end
