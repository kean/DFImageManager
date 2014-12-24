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

extern NSString *const DFImageInfoSourceKey;
extern NSString *const DFImageInfoErrorKey;
extern NSString *const DFImageInfoDataKey;


typedef NS_ENUM(NSInteger, DFImageCacheStoragePolicy) {
    DFImageCacheStorageAllowed,
    DFImageCacheStorageAllowedInMemoryOnly,
    DFImageCacheStorageNotAllowed
};

typedef NS_ENUM(NSInteger, DFImageSource) {
    DFImageSourceMemoryCache,
    DFImageSourceDiskCache,
    DFImageSourceExternal
};

typedef NS_ENUM(NSInteger, DFImageContentMode) {
    DFImageContentModeAspectFill = 0,
    DFImageContentModeAspectFit = 1,
    DFImageContentModeDefault = DFImageContentModeAspectFill
};


typedef NSOperationQueuePriority DFImageRequestPriority;
static const DFImageRequestPriority DFImageRequestPriorityVeryLow = NSOperationQueuePriorityVeryLow;
static const DFImageRequestPriority DFImageRequestPriorityLow = NSOperationQueuePriorityLow;
static const DFImageRequestPriority DFImageRequestPriorityNormal = NSOperationQueuePriorityNormal;
static const DFImageRequestPriority DFImageRequestPriorityHigh = NSOperationQueuePriorityHigh;
static const DFImageRequestPriority DFImageRequestPriorityVeryHigh = NSOperationQueuePriorityVeryHigh;

extern NSString *const DFImageErrorDomain;
