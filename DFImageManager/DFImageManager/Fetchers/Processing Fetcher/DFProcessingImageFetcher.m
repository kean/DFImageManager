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

#import "DFProcessingImageFetcher.h"
#import "DFImageResponse.h"


@interface _DFImageProcessingOperation : NSOperation <DFImageManagerOperation>

- (instancetype)initWithProcessor:(id<DFImageProcessor>)processor image:(UIImage *)image request:(DFImageRequest *)request;

@end

@implementation _DFImageProcessingOperation {
    id<DFImageProcessor> _processor;
    UIImage *_image;
    DFImageRequest *_request;
    DFImageResponse *_response;
}

- (instancetype)initWithProcessor:(id<DFImageProcessor>)processor image:(UIImage *)image request:(DFImageRequest *)request {
    if (self = [super init]) {
        _processor = processor;
        _image = image;
        _request = request;
    }
    return self;
}

- (void)main {
    UIImage *processedImage = [_processor processedImage:_image forRequest:_request];
    _response = [[DFImageResponse alloc] initWithImage:processedImage ?: _image];
}

- (DFImageResponse *)imageResponse {
    return _response;
}

@end


@implementation DFProcessingImageFetcher {
    id<DFImageProcessor> _processor;
    NSOperationQueue *_queue;
}

- (instancetype)initWithProcessor:(id<DFImageProcessor>)processor qeueu:(NSOperationQueue *)queue {
    if (self = [super init]) {
        _processor = processor;
        _queue = queue;
    }
    return self;
}

- (BOOL)canHandleRequest:(DFImageRequest *)request {
    return [request.asset isKindOfClass:[DFProcessingInput class]];
}

- (BOOL)isRequestEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    if (request1 == request2) {
        return YES;
    }
    return [_processor isRequestEquivalent:request1 toRequest:request2];
}

- (NSOperation<DFImageManagerOperation> *)createOperationForRequest:(DFImageRequest *)request {
    UIImage *image = [((DFProcessingInput *)request.asset) image];
    return [[_DFImageProcessingOperation alloc] initWithProcessor:_processor image:image request:request];
}

- (void)enqueueOperation:(NSOperation<DFImageManagerOperation> *)operation {
    [_queue addOperation:operation];
}

@end
