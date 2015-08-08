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

#import "DFImageManaging.h"
#import "DFImageRequest.h"
#import <Foundation/Foundation.h>

/*! The DFProxyRequestTransforming protocol defines an interface for transforming application-specific classes or protocols to the resources supported by the DFImageManager.
 */
@protocol DFProxyRequestTransforming <NSObject>

/*! Returns the result of transforming a given request.
 @param request The copy of the original request, users can modify passed request.
 */
- (nonnull DFImageRequest *)transformedRequest:(nonnull DFImageRequest *)request;

@end


/*! The DFProxyImageManager is used to modify image requests before they are received by the actual image manager. For example, the users can use it to transform application-specific classes or protocols to the resources supported by the DFImageManager.
 */
@interface DFProxyImageManager : NSProxy <DFImageManaging>

/*! Image manager that the receiver was initialized with.
 */
@property (nonnull, nonatomic) id<DFImageManaging> imageManager;

/*! Initializes proxy with the image manager.
 */
- (nonnull instancetype)initWithImageManager:(nonnull id<DFImageManaging>)imageManager;

/*! Sets the request transformer.
 */
@property (nullable, nonatomic) id<DFProxyRequestTransforming> transformer;

/*! Sets request transformer with a given block. Overwrites transformer value.
 */
- (void)setRequestTransformerWithBlock:(DFImageRequest *__nonnull (^__nullable)(DFImageRequest *__nonnull request))block;

@end
