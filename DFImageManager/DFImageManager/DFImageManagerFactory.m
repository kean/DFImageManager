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

#import "DFImageManagerFactory.h"

@implementation DFImageManagerFactory {
    NSMutableDictionary *_imageManagers;
}

- (instancetype)init {
    if (self = [super init]) {
        _imageManagers = [NSMutableDictionary new];
    }
    return self;
}

- (void)registerImageManager:(id<DFImageManager>)imageManager forAssetClass:(Class)assetClass {
    if (imageManager != nil && assetClass) {
        _imageManagers[NSStringFromClass(assetClass)] = imageManager;
    }
}

#pragma mark - <DFImageManagerFactory>

- (id<DFImageManager>)imageManagerForAsset:(id)asset {
    id<DFImageManager> __block imageManager;
    [_imageManagers enumerateKeysAndObjectsUsingBlock:^(NSString *key, id<DFImageManager> object, BOOL *stop) {
        if ([asset isKindOfClass:NSClassFromString(key)]) {
            imageManager = object;
            *stop = YES;
        }
    }];
    return imageManager;
}

@end
