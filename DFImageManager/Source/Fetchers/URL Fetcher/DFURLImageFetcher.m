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
#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"
#import "DFImageResponse.h"
#import "DFURLImageFetcher.h"
#import "DFURLImageRequestOptions.h"
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

- (DFImageRequest *)canonicalRequestForRequest:(DFImageRequest *)request {
    if (!request.options || ![request.options isKindOfClass:[DFURLImageRequestOptions class]]) {
        DFURLImageRequestOptions *options = [[DFURLImageRequestOptions alloc] initWithOptions:request.options];
        NSURLSessionConfiguration *conf = self.session.configuration;
        options.cachePolicy = conf.requestCachePolicy;
        
        DFImageRequest *canonical = [request copy];
        canonical.options = options;
        return canonical;
    }
    return request;
}

- (NSOperation *)startOperationWithRequest:(DFImageRequest *)request completion:(void (^)(DFImageResponse *))completion {
    NSURLRequest *URLRequest = [self _createURLRequestWithRequest:request];
    DFURLSessionOperation *operation = [[DFURLSessionOperation alloc] initWithRequest:URLRequest session:self.session];
    operation.deserializer = [DFImageDeserializer new];
    DFURLSessionOperation *__weak weakOp = operation;
    [operation setCompletionBlock:^{
        DFMutableImageResponse *response = [DFMutableImageResponse new];
        response.image = weakOp.responseObject;
        response.error = weakOp.error;
        completion([response copy]);
    }];
    [_queue addOperation:operation];
    return operation;
}

- (NSMutableURLRequest *)_createURLRequestWithRequest:(DFImageRequest *)imageRequest {
    NSURL *URL = (NSURL *)imageRequest.asset;
    DFURLImageRequestOptions *options = (id)imageRequest.options;
    
    /*! From NSURLSessionConfiguration class reference:
     "In some cases, the policies defined in this configuration may be overridden by policies specified by an NSURLRequest object provided for a task. Any policy specified on the request object is respected unless the session’s policy is more restrictive. For example, if the session configuration specifies that cellular networking should not be allowed, the NSURLRequest object cannot request cellular networking."
     
     Apple doesn't not provide a complete documentation on what NSURLSessionConfiguration options can be overridden by NSURLRequest and in when. So it's best to copy all the options, because the NSURLSession implementation might change in future versons.
     */
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
    
    /* Set options that can not be configured by DFURLImageRequestOptions.
     */
    NSURLSessionConfiguration *conf = self.session.configuration;
    request.timeoutInterval = conf.timeoutIntervalForRequest;
    request.networkServiceType = conf.networkServiceType;
    request.allowsCellularAccess = conf.allowsCellularAccess;
    request.HTTPShouldHandleCookies = conf.HTTPShouldSetCookies;
    request.HTTPShouldUsePipelining = conf.HTTPShouldUsePipelining;
    request.allowsCellularAccess = conf.allowsCellularAccess;
    
    /* Set options that can be configured by DFURLImageRequestOptions.
     */
    request.cachePolicy = options.cachePolicy;
    if (!options.networkAccessAllowed) {
        request.cachePolicy = NSURLRequestReturnCacheDataDontLoad;
    }
    
    return [request copy];
}

@end
