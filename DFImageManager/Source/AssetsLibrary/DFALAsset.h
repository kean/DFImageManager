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

#import <Foundation/Foundation.h>

@class ALAsset;

NS_ASSUME_NONNULL_BEGIN

/*! ALAsset wrapper that implements -hash method and memorizes assetURL.
 @note The asset URL is created lazily. In some cases it might be a good idea to warm-up this property.
 */
@interface DFALAsset : NSObject

/*! The asset the receiver was initialized with.
 */
@property (nonatomic, readonly) ALAsset *asset;

/*! The asset URL (assets-library:) of the asset. Asset URL is created lazily.
 */
@property (nonatomic, readonly) NSURL *assetURL;

/*! Initializes DFALAsset with an instance of ALAsset class.
 */
- (instancetype)initWithAsset:(ALAsset *)asset NS_DESIGNATED_INITIALIZER;

/*! Warms up the receiver's properties. For best performance use it in the background before displaying multiple DFALAsset instances. ALAssetsLibrary is ridiculously slow and might otherwise trash the image manager.
 */
- (void)warmup;

@end

NS_ASSUME_NONNULL_END
