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

#import "DFImageManagerDefines.h"

@class DFMutableImageRequestOptions;

/*! You use a DFImageRequestOptions object to specify options when requesting image representations of resources using classes conforming DFImageManaging protocol.
 */
@interface DFImageRequestOptions : NSObject

/*! Image request priority.
 */
@property (nonatomic, readonly) DFImageRequestPriority priority;

/*! A Boolean value that specifies whether image manager can download the requested image using network connection.
 */
@property (nonatomic, readonly) BOOL allowsNetworkAccess;

/*! If YES allows some portion of the image content to be clipped when filling the content to target size. Only works with DFImageContentModeAspectFill.
 */
@property (nonatomic, readonly) BOOL allowsClipping;

/*! If YES allows progressive image decoding.
 */
@property (nonatomic, readonly) BOOL allowsProgressiveImage;

/*! The request cache policy used for memory caching.
 */
@property (nonatomic, readonly) DFImageRequestCachePolicy memoryCachePolicy;

/*! The amount of time to elapse before memory-cached images associated with a request are considered to have expired.
 @warning This property doesn't affect caching implemented in a classes conforming to DFImageFetching protocol (for example, NSURLSession caching). For more info see DFImageCaching protocol and DFCachedImageResponse class.
 */
@property (nonatomic, readonly) NSTimeInterval expirationAge;

/*! A dictionary containing image manager-specific data pertaining to the receiver. Default value is nil.
 */
@property (nullable, nonatomic, readonly) NSDictionary *userInfo;

/*! Initializes DFImageRequestOptions with another instance of request options.
 @param options The given options. Options might be nil.
 */
- (nonnull instancetype)initWithOptions:(nonnull DFMutableImageRequestOptions *)options NS_DESIGNATED_INITIALIZER;

/*! Initializes DFImageRequestOptions with default options.
 */
- (nonnull instancetype)init;

@end


/*! DFImageRequestOptions builder. Use options property of the builder to create DFImageRequestOptions object.
 */
@interface DFMutableImageRequestOptions : NSObject

/*! Creates request options from the receiver.
 */
@property (nonnull, nonatomic, readonly) DFImageRequestOptions *options;

/*! Initializes DFMutableImageRequestOptions with default options.
 */
- (nonnull instancetype)init NS_DESIGNATED_INITIALIZER;

/*! Image request priority. Default value is DFImageRequestPriorityNormal.
 */
@property (nonatomic) DFImageRequestPriority priority;

/*! A Boolean value that specifies whether image manager can download the requested image using network connection. Default value is YES.
 */
@property (nonatomic) BOOL allowsNetworkAccess;

/*! If YES allows some portion of the image content to be clipped when filling the content to target size. Only works with DFImageContentModeAspectFill. Default value is NO.
 */
@property (nonatomic) BOOL allowsClipping;

/*! If YES allows progressive image decoding. Default value is NO.
 */
@property (nonatomic) BOOL allowsProgressiveImage;

/*! The request cache policy used for memory caching. Default value is DFImageRequestCachePolicyDefault.
 */
@property (nonatomic) DFImageRequestCachePolicy memoryCachePolicy;

/*! The amount of time to elapse before memory-cached images associated with a request are considered to have expired. Default value is 600.0 seconds.
 @warning This property doesn't affect caching implemented in a classes conforming to DFImageFetching protocol (for example, NSURLSession caching)! For more info see DFImageCaching protocol and DFCachedImageResponse class.
 */
@property (nonatomic) NSTimeInterval expirationAge;

/*! A dictionary containing image manager-specific data pertaining to the receiver. Default value is nil.
 */
@property (nullable, copy, nonatomic) NSDictionary *userInfo;

/*! Returns default image request options builder that is used when new DFMutableImageRequestOptions instance is initialized.
 */
+ (nonnull instancetype)defaultOptions;

@end
