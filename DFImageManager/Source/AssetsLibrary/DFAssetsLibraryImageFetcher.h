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

#import "DFImageFetching.h"
#import <Foundation/Foundation.h>


/*! Image fetcher for ALAssetsLibrary framework. Supported resources: DLALAsset, NSURL with scheme assets-library.
 @note You may use the DFProxyImageManager to add support for ALAsset class.
 @warning Refrain from using DFAssetsLibraryImageFetcher on iOS 8.0+.
 @warning For best results use NSURL with assets-library scheme instead of of ALAsset class (which might seem counterintuitive). You can retrieve the asset URL like this [asset valueForProperty:ALAssetPropertyAssetURL]. If you use DFALAsset you should warmup instances of that class in background before use. The problem is, unlike PHAsset, the ALAsset class doesn't implement -hash and -isEqual methods. And what's worse, retrieving the ALAsset URL is very (very!) slow operation that blocks the entire assets library.
 */
@interface DFAssetsLibraryImageFetcher : NSObject <DFImageFetching>

@end
