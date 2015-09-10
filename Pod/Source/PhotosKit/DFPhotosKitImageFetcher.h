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

NS_ASSUME_NONNULL_BEGIN

/*! The PHImageRequestOptionsVersion value for requesting an image asset with or without adjustments, used by the version property. Default value is PHImageRequestOptionsVersionCurrent.
 @note Should be put into DFImageRequestOptions userInfo dictionary.
 */
extern NSString *const DFPhotosKitVersionKey;

/*! Image fetcher for Photos Kit framework. Supported resources: PHAsset, NSURL with scheme com.github.kean.photos-kit.
 @note Use methods of NSURL+DFPhotosKit category to construct URLs for PHAssets.
 */
NS_CLASS_AVAILABLE_IOS(8_0) @interface DFPhotosKitImageFetcher : NSObject <DFImageFetching>

@end

NS_ASSUME_NONNULL_END
