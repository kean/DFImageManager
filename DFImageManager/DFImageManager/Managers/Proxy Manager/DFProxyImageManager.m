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

#import "DFImageManagerBlockValueTransformer.h"
#import "DFProxyImageManager.h"

#define _DF_TRANSFORMED_ASSET(asset) _transformer ? [_transformer transformedAsset:asset] : asset

@implementation DFProxyImageManager

@synthesize valueTransformer = _transformer;
@synthesize imageManager = _manager;

- (instancetype)initWithImageManager:(id<DFImageManager>)imageManager {
    self.imageManager = imageManager;
    return self;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    [anInvocation invokeWithTarget:_manager];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return [(NSObject *)_manager methodSignatureForSelector:aSelector];
}

- (void)setValueTransformerWithBlock:(id (^)(id))block {
    self.valueTransformer = [[DFImageManagerBlockValueTransformer alloc] initWithBlock:block];
}

#pragma mark - <DFImageManager>

- (BOOL)canHandleAsset:(id)asset {
    return [_manager canHandleAsset:_DF_TRANSFORMED_ASSET(asset)];
}

- (DFImageRequestID *)requestImageForAsset:(id)asset targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options completion:(void (^)(UIImage *, NSDictionary *))completion {
    return [_manager requestImageForAsset:_DF_TRANSFORMED_ASSET(asset) targetSize:targetSize contentMode:contentMode options:options completion:completion];
}

- (void)startPreheatingImageForAssets:(NSArray *)assets targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    [_manager startPreheatingImageForAssets:[self _transformedAssets:assets] targetSize:targetSize contentMode:contentMode options:options];
}

- (void)stopPreheatingImagesForAssets:(NSArray *)assets targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    [_manager stopPreheatingImagesForAssets:[self _transformedAssets:assets] targetSize:targetSize contentMode:contentMode options:options];
}

- (NSArray *)_transformedAssets:(NSArray *)assets {
    NSMutableArray *transformedAssets = [NSMutableArray new];
    for (id asset in assets) {
        id transformedAsset = _DF_TRANSFORMED_ASSET(asset);
        if (transformedAssets != nil) {
            [transformedAssets addObject:transformedAsset];
        }
    }
    return transformedAssets;
}

@end
