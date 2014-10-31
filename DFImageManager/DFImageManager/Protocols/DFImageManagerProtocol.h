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

#import "DFImageManagerDefines.h"

@class DFImageRequestOptions;
@class DFImageRequestID;


@protocol DFImageManager <NSObject>

- (DFImageRequestID *)requestImageForAsset:(id)asset options:(DFImageRequestOptions *)options completion:(void (^)(UIImage *image, NSDictionary *info))completion;
- (void)cancelRequestWithID:(DFImageRequestID *)requestID;

- (void)setPriority:(DFImageRequestPriority)priority forRequestWithID:(DFImageRequestID *)requestID;

/*! Start prefetch operation with a given prefetch priority. You would normally DFImageRequestPriorityLow or DFImageRequestPriorityVeryLow.
 */
- (DFImageRequestID *)prefetchImageForAsset:(id)asset options:(DFImageRequestOptions *)options;

/*! Cancels all image prefetching operations.
 @note Do not cancel operations that were started as a prefetch operations but than were assigned 'real' handlers.
 */
- (void)stopPrefetchingAllImages;

@end
