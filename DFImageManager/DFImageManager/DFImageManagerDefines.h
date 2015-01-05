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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


typedef void (^DFImageRequestCompletion)(UIImage *image, NSDictionary *info);

extern NSString *const DFImageInfoRequestIDKey;
extern NSString *const DFImageInfoErrorKey;
extern NSString *const DFImageInfoCancelledKey;
extern NSString *const DFImageInfoDataKey;

/*! Boolean value indicating whether the image was returned from memory cache. (NSNumber)
 */
extern NSString *const DFImageInfoResultIsFromMemoryCacheKey;


/* Size to pass when requesting the largest image for asset available (contentMode will be ignored).
 */
extern CGSize const DFImageManagerMaximumSize;


typedef NS_ENUM(NSInteger, DFImageCacheStoragePolicy) {
    DFImageCacheStorageAllowed,
    DFImageCacheStorageAllowedInMemoryOnly,
    DFImageCacheStorageNotAllowed
};

typedef NS_ENUM(NSInteger, DFImageContentMode) {
    DFImageContentModeAspectFill = 0,
    DFImageContentModeAspectFit = 1,
    DFImageContentModeDefault = DFImageContentModeAspectFill
};

typedef NS_ENUM(NSInteger, DFImageRequestPriority) {
    DFImageRequestPriorityVeryLow = NSOperationQueuePriorityVeryLow,
    DFImageRequestPriorityLow = NSOperationQueuePriorityLow,
    DFImageRequestPriorityNormal = NSOperationQueuePriorityNormal,
    DFImageRequestPriorityHigh = NSOperationQueuePriorityHigh,
    DFImageRequestPriorityVeryHigh = NSOperationQueuePriorityVeryHigh
};

extern NSString *const DFImageErrorDomain;
