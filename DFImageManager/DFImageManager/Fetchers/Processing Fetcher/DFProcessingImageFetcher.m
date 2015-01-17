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

#import "DFBlockImageManagerOperation.h"
#import "DFImageResponse.h"
#import "DFProcessingImageFetcher.h"


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
    if (![[request1.asset uniqueImageAssetIdentifier] isEqualToString:[request2.asset uniqueImageAssetIdentifier]]) {
        return NO;
    }
    return [_processor isProcessingForRequestEquivalent:request1 toRequest:request2];
}

- (NSOperation<DFImageManagerOperation> *)createOperationForRequest:(DFImageRequest *)request {
    UIImage *image = [((DFProcessingInput *)request.asset) image];
    return [[DFBlockImageManagerOperation alloc] initWithBlock:^DFImageResponse *(DFBlockImageManagerOperation *operation) {
        UIImage *processedImage = [_processor processedImage:image forRequest:request];
         return [[DFImageResponse alloc] initWithImage:processedImage ?: image];
    }];
}

- (void)enqueueOperation:(NSOperation<DFImageManagerOperation> *)operation {
    [_queue addOperation:operation];
}

@end
