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

#import "DFImageFetcherProtocol.h"
#import <Foundation/Foundation.h>

@class DFImageRequest;


extern NSString *const DFImageManagerCacheLookupOperationType;
extern NSString *const DFImageManagerImageFetchOperationType;
extern NSString *const DFImageManagerCacheStoreOperationType;

/*! Base image fetcher that implements <DFImageFetcher> protocol and defines a specific operations flow (cache lookup ~> fetch ~> cache store). 
 */
@interface DFCachingImageFetcher : NSObject <DFImageFetcher>

@end


@interface DFCachingImageFetcher (SubclassingHooks)

- (NSArray *)keyPathForRequestParametersAffectingExecutionContextID:(DFImageRequest *)request;

// factory methods

- (NSOperation<DFImageManagerOperation> *)createCacheLookupOperationForRequest:(DFImageRequest *)request;
- (NSOperation<DFImageManagerOperation> *)createImageFetchOperationForRequest:(DFImageRequest *)request;
- (NSOperation *)createCacheStoreOperationForRequest:(DFImageRequest *)request previousOperation:(NSOperation<DFImageManagerOperation> *)previousOperation;

// other

- (NSString *)operationTypeForOperation:(NSOperation *)operation;

- (NSOperationQueue *)operationQueueForOperation:(NSOperation *)operation;

@end
