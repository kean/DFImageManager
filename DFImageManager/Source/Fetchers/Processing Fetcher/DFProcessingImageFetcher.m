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

#import "DFImageProcessing.h"
#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"
#import "DFImageResponse.h"
#import "DFProcessingImageFetcher.h"
#import "DFProcessingInput.h"


@implementation DFProcessingImageFetcher {
    id<DFImageProcessing> _processor;
    NSOperationQueue *_queue;
}

- (instancetype)initWithProcessor:(id<DFImageProcessing>)processor queue:(NSOperationQueue *)queue {
    if (self = [super init]) {
        _processor = processor;
        _queue = queue;
    }
    return self;
}

- (BOOL)canHandleRequest:(DFImageRequest *)request {
    return [request.resource isKindOfClass:[DFProcessingInput class]];
}

- (BOOL)isRequestFetchEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    return [self isRequestCacheEquivalent:request1 toRequest:request2];
}

- (BOOL)isRequestCacheEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    if (request1 == request2) {
        return YES;
    }
    DFProcessingInput *input1 = request1.resource;
    DFProcessingInput *input2 = request2.resource;
    if (!(input1.image == input2.image || [input1.imageIdentifier isEqualToString:input2.imageIdentifier])) {
        return NO;
    }
    return [_processor isProcessingForRequestEquivalent:request1 toRequest:request2];
}

- (NSOperation *)startOperationWithRequest:(DFImageRequest *)request progressHandler:(void (^)(double))progressHandler completion:(void (^)(DFImageResponse *))completion {
    UIImage *image = [((DFProcessingInput *)request.resource) image];
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        UIImage *processedImage = [_processor processedImage:image forRequest:request];
        completion([[DFImageResponse alloc] initWithImage:processedImage ?: image]);
    }];
    [_queue addOperation:operation];
    return operation;
}

@end
