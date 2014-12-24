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

#import "DFImageRequestOptions.h"
#import "DFPHAssetlocalIdentifier.h"
#import "DFPHImageFetchOperation.h"
#import "DFPHImageManagerConfiguration.h"
#import <Photos/Photos.h>


@implementation DFPHImageManagerConfiguration {
    NSOperationQueue *_queueForAssets;
}

- (instancetype)init {
    if (self = [super init]) {
        _queueForAssets = [NSOperationQueue new];
        _queueForAssets.maxConcurrentOperationCount = 4;
    }
    return self;
}

#pragma mark - <DFImageManagerConfiguration>

- (NSString *)imageManager:(id<DFImageManager>)manager uniqueIDForAsset:(id)asset {
    if ([asset isKindOfClass:[PHAsset class]]) {
        return [((PHAsset *)asset) localIdentifier];
    } else if ([asset isKindOfClass:[DFPHAssetlocalIdentifier class]]) {
        return [((DFPHAssetlocalIdentifier *)asset) identifier];
    } else {
        return nil;
    }
}

- (NSString *)imageManager:(id<DFImageManager>)manager createRequestIDForAsset:(id)asset options:(DFImageRequestOptions *)options {
    // TODO: Implement properly
    return [self imageManager:manager uniqueIDForAsset:asset];
}

- (NSOperation<DFImageManagerOperation> *)imageManager:(id<DFImageManager>)manager createOperationForAsset:(id)asset options:(DFImageRequestOptions *)options previousOperation:(NSOperation<DFImageManagerOperation> *)previousOperation {
    if (!previousOperation) {
        if ([asset isKindOfClass:[PHAsset class]]) {
            //      return [[DFPHImageFetchOperation alloc] initWithAsset:asset options:(id)options];
        }
        
        else if ([asset isKindOfClass:[DFPHAssetlocalIdentifier class]]) {
            //        return [[DFPHImageFetchOperation alloc] initWithAssetLocalIdentifier:asset options:(id)options];
        }
    }
    return nil;
}

- (void)imageManager:(id<DFImageManager>)manager enqueueOperation:(NSOperation<DFImageManagerOperation> *)operation {
    [_queueForAssets addOperation:operation];
}

@end
