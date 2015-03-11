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

#import "DFAssetsLibraryDefines.h"
#import <Foundation/Foundation.h>

@class UIImage;
@class ALAsset;

/*! The operation the implements fetching of image representation of instances of ALAsset class.
 */
@interface DFAssetsLibraryImageFetchOperation : NSOperation

/*! The image size. Default value is DFALAssetImageSizeThumbnail.
 */
@property (nonatomic) DFALAssetImageSize imageSize;

/*! The image version. Default value is DFALAssetVersionCurrent.
 @warning Using DFALAssetVersionUnadjusted will always return the biggest, best representation available, ignoring the value of imageSize property.
 */
@property (nonatomic) DFALAssetVersion version;

/*! The image that was fetched by the receiver.
 */
@property (nonatomic, readonly) UIImage *image;

/*! The error associated with the image load.
 */
@property (nonatomic, readonly) NSError *error;

/*! Initializes operation with instance of ALAsset class.
 */
- (instancetype)initWithAsset:(ALAsset *)asset;

/*! Initializes operation with asset URL. Instance of ALAsset will be fetched automatically when operation is started.
 */
- (instancetype)initWithAssetURL:(NSURL *)assetURL;

@end
