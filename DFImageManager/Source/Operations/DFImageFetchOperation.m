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

#import "DFImageFetchOperation.h"
#import "DFImageManager.h"
#import "DFImageManaging.h"
#import "DFImageRequestID.h"


@implementation DFImageFetchOperation {
    void (^_completion)(UIImage *, NSDictionary *);
}

- (instancetype)initWithRequest:(DFImageRequest *)request completion:(void (^)(UIImage *, NSDictionary *))completion {
    if (self = [super init]) {
        _request = request;
        _completion = [completion copy];
        _imageManager = [DFImageManager sharedManager];
    }
    return self;
}

- (void)start {
    @synchronized(self) {
        [super start];
        if (self.isCancelled) {
            [self finish];
        } else {
            DFImageFetchOperation *__weak weakSelf = self;
            _requestID = [self.imageManager requestImageForRequest:self.request completion:^(UIImage *image, NSDictionary *info) {
                [weakSelf _requestDidCompleteWithImage:image info:info];
            }];
        }
    }
}

- (void)_requestDidCompleteWithImage:(UIImage *)image info:(NSDictionary *)info {
    @synchronized(self) {
        _image = image;
        _info = info;
        if (!self.isCancelled) {
            [self finish];
        }
        if (_completion) {
            _completion(image, info);
        }
    }
}

- (void)cancel {
    @synchronized(self) {
        if (!self.isCancelled && !self.isFinished) {
            [super cancel];
            _completion = nil;
            if (_requestID != nil) {
                [_requestID cancel];
                [self finish];
            }
        }
    }
}

@end
