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

#import "DFImageManagerOperationProtocol.h"
#import "DFImageManagerProtocol.h"

@class DFImageRequest;
@class DFImageRequestOptions;


/*! Factory for multiple image provider components.
 */
@protocol DFImageFetcher <NSObject>

- (BOOL)canHandleRequest:(DFImageRequest *)request;

- (NSString *)uniqueIDForAsset:(id)asset;

/*! Creates execution context ID for request so that existing operations could be reused for new handlers.
 */
- (NSString *)executionContextIDForRequest:(DFImageRequest *)request;

/*! Return nil if no work is required.
 */
- (NSOperation<DFImageManagerOperation> *)createOperationForRequest:(DFImageRequest *)request previousOperation:(NSOperation<DFImageManagerOperation> *)previousOperation;

- (void)enqueueOperation:(NSOperation<DFImageManagerOperation> *)operation;

@optional

- (void)imageManager:(id<DFImageManager>)manager didEncounterError:(NSError *)error;

@end
