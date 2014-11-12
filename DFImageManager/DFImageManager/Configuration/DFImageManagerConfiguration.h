// The MIT License (MIT)
//
// Copyright (c) 2014 Alexander Grebenyuk (github.com/kean).
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

#import "DFImageManagerConfigurationProtocol.h"
#import <Foundation/Foundation.h>


extern NSString *const DFImageManagerCacheLookupOperationType;
extern NSString *const DFImageManagerImageFetchOperationType;
extern NSString *const DFImageManagerCacheStoreOperationType;


@interface DFImageManagerConfiguration : NSObject <DFImageManagerConfiguration>

@end


@interface DFImageManagerConfiguration (SubclassingHooks)

// methods for constracting requestID

- (NSString *)uniqueIDForAsset:(id)asset;
- (NSArray *)parametersForOptions:(DFImageRequestOptions *)options;

// operations factory methods

- (NSOperation<DFImageManagerOperation> *)createCacheLookupOperationForAsset:(id)asset options:(DFImageRequestOptions *)options;
- (NSOperation<DFImageManagerOperation> *)createImageFetchOperationForAsset:(id)asset options:(DFImageRequestOptions *)options;
- (NSOperation *)createCacheStoreOperationForAsset:(id)asset options:(DFImageRequestOptions *)options previousOperation:(NSOperation<DFImageManagerOperation> *)previousOperation;

- (NSString *)operationTypeForOperation:(NSOperation *)operation;

// other

- (NSOperationQueue *)operationQueueForOperation:(NSOperation *)operation;

@end
