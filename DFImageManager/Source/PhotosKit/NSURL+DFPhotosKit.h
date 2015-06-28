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

@class PHAsset;

NS_ASSUME_NONNULL_BEGIN

/*! The URL scheme used for accessing PHAsset objects.
 */
static NSString *const DFPhotosKitURLScheme = @"com.github.kean.photos-kit";

/*! The NSURL category that adds methods for manipulating URLs with "com.github.kean.photos-kit" scheme.
 */
@interface NSURL (DFPhotosKit)

/*! Returns NSURL with a given local identifier for asset.
 */
+ (nullable NSURL *)df_assetURLWithAssetLocalIdentifier:(nullable NSString *)localIdentifier NS_AVAILABLE_IOS(8_0);

/*! Returns NSURL with a local identifier for a given asset.
 */
+ (nullable NSURL *)df_assetURLWithAsset:(nullable PHAsset *)asset NS_AVAILABLE_IOS(8_0);

/*! Returns local identifier from a given URL.
 */
- (nullable NSString *)df_assetLocalIdentifier NS_AVAILABLE_IOS(8_0);

@end

NS_ASSUME_NONNULL_END
