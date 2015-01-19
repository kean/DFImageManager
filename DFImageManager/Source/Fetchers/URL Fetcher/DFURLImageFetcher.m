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

#import "DFImageDeserializer.h"
#import "DFImageManagerOperationProtocol.h"
#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"
#import "DFImageResponse.h"
#import "DFURLImageFetcher.h"
#import "DFURLResponseDeserializing.h"
#import "DFURLSessionOperation.h"
#import "NSURL+DFImageAsset.h"


@interface DFImageRequest (DFURLImageFetcher)

- (BOOL)_isFileRequest;

@end

@implementation DFImageRequest (DFURLImageFetcher)

- (BOOL)_isFileRequest {
    return [((NSURL *)self.asset) isFileURL];
}

@end


@interface DFURLImageFetcher ()

@property (nonatomic, readonly) NSOperationQueue *queueForCache;
@property (nonatomic, readonly) NSOperationQueue *queueForNetwork;

@end


@interface _DFURLImageFetcherOperation : DFURLSessionOperation <DFImageManagerOperation>

@end

@implementation _DFURLImageFetcherOperation {
    DFImageResponse *_response;
    NSOperation *_currentOperation;
}

- (void)finish {
    DFMutableImageResponse *response = [DFMutableImageResponse new];
    response.image = self.responseObject;
    response.error = self.error;
    if (self.responseObject != nil) {
        response.data = self.data;
    }
    _response = [response copy];
    [super finish];
}

- (DFImageResponse *)imageResponse {
    return _response;
}

@end



@implementation DFURLImageFetcher {
    NSOperationQueue *_queue;
}

- (instancetype)initWithSession:(NSURLSession *)session {
    if (self = [super init]) {
        NSParameterAssert(session);
        _session = session;
        
        // We don't need to limit concurrent operations for NSURLSession. For more info see https://github.com/kean/DFImageManager/wiki/Image-Caching-Guide
        _queue = [NSOperationQueue new];
    }
    return self;
}

#pragma mark - <DFImageFetcher>

- (BOOL)canHandleRequest:(DFImageRequest *)request {
    if ([request.asset isKindOfClass:[NSURL class]]) {
        NSURL *URL = (NSURL *)request.asset;
        if ([[[self class] supportedSchemes] containsObject:URL.scheme]) {
            return YES;
        }
    }
    return NO;
}

+ (NSSet *)supportedSchemes {
    static NSSet *schemes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        schemes = [NSSet setWithObjects:@"http", @"https", @"ftp", @"file", nil];
    });
    return schemes;
}

- (BOOL)isRequestEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    if (request1 == request2) {
        return YES;
    }
    NSURL *URL1 = (NSURL *)request1.asset;
    NSURL *URL2 = (NSURL *)request2.asset;
    if (![URL1 isEqual:URL2]) {
        return NO;
    }
    return [request1 _isFileRequest] ? YES : request1.options.networkAccessAllowed == request2.options.networkAccessAllowed;
}

- (NSOperation<DFImageManagerOperation> *)createOperationForRequest:(DFImageRequest *)request {
    _DFURLImageFetcherOperation *operation = [[_DFURLImageFetcherOperation alloc] initWithURL:(NSURL *)request.asset session:self.session];
    operation.deserializer = [DFImageDeserializer new];
    return operation;
}

- (void)enqueueOperation:(NSOperation<DFImageManagerOperation> *)operation {
    [_queue addOperation:operation];
}

@end
