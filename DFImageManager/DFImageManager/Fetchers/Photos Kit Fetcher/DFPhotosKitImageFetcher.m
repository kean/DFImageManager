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

#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"
#import "DFPHAssetlocalIdentifier.h"
#import "DFPhotosKitImageFetchOperation.h"
#import "DFPhotosKitImageFetcher.h"
#import <Photos/Photos.h>


@implementation DFPhotosKitImageFetcher {
    NSOperationQueue *_queue;
}

- (instancetype)init {
    if (self = [super init]) {
        _queue = [NSOperationQueue new];
        _queue.maxConcurrentOperationCount = 2;
    }
    return self;
}

#pragma mark - <DFImageFetcher>

- (BOOL)canHandleRequest:(DFImageRequest *)request {
    id asset = request.asset;
    return [asset isKindOfClass:[PHAsset class]] || [asset isKindOfClass:[DFPHAssetlocalIdentifier class]];
}

- (NSString *)uniqueIDForAsset:(id)asset {
    if ([asset isKindOfClass:[PHAsset class]]) {
        return [((PHAsset *)asset) localIdentifier];
    } else if ([asset isKindOfClass:[DFPHAssetlocalIdentifier class]]) {
        return [((DFPHAssetlocalIdentifier *)asset) identifier];
    }
    return nil;
}

- (NSString *)executionContextIDForRequest:(DFImageRequest *)request {
    NSString *assetUID = [self uniqueIDForAsset:request.asset];
    
    NSMutableString *ECID = [[NSMutableString alloc] initWithString:@"requestID?"];
    NSArray *keyPaths = [self _keyPathsAffectingExecutionContextIDForRequest:request];
    for (NSString *keyPath in keyPaths) {
        [ECID appendFormat:@"%@=%@&", keyPath, [request valueForKeyPath:keyPath]];
    }
    [ECID appendFormat:@"assetID=%@", assetUID];
    return ECID;
}

- (NSArray *)_keyPathsAffectingExecutionContextIDForRequest:(DFImageRequest *)request {
    static NSArray *keyPaths;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keyPaths = @[ @"targetSize",
                      @"contentMode",
                      @"options.networkAccessAllowed" ];
    });
    return keyPaths;
}

- (NSOperation<DFImageManagerOperation> *)createOperationForRequest:(DFImageRequest *)request previousOperation:(NSOperation<DFImageManagerOperation> *)previousOperation {
    if (!previousOperation) {
        return [[DFPhotosKitImageFetchOperation alloc] initWithRequest:request];
    }
    return nil;
}

- (void)enqueueOperation:(NSOperation<DFImageManagerOperation> *)operation {
    [_queue addOperation:operation];
}

@end
