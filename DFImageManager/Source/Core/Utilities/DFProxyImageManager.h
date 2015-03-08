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
#import <Foundation/Foundation.h>


/*! The DFProxyResourceTransforming protocol defines an interface for transforming application-specific classes or protocols to the resources supported by the DFImageManager.
 */
@protocol DFProxyResourceTransforming <NSObject>

/*! Returns the result of transforming a given resource.
 */
- (id)transformedResource:(id)resource;

@end


/*! The DFProxyImageManager is used to transform application-specific classes or protocols to the resources supported by the DFImageManager. The DFImageManager that the DFProxyImageManager was initialized with will always receive a transformed resources.
 @note Adapts image manager that it was initialized with to <DFImageManaging> protocol.
 */
@interface DFProxyImageManager : NSProxy <DFImageManaging>

/*! Image manager that the receiver was initialized with.
 */
@property (nonatomic) id<DFImageManagingCore> imageManager;

/*! Initializes proxy with the image manager.
 */
- (instancetype)initWithImageManager:(id<DFImageManagingCore>)imageManager;

/*! Set resource transformer in case you need to transform resources before passing them to the image manager factory and to the image managers.
 */
@property (nonatomic) id<DFProxyResourceTransforming> resourceTransformer;

/*! Sets resource transformer with a given block. Overwrites resourceTransformer value.
 */
- (void)setResourceTransformerWithBlock:(id (^)(id resource))transformer;

@end
