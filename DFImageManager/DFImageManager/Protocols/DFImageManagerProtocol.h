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

#import "DFImageManagerDefines.h"
#import "DFImageRequest.h"
#import "DFImageRequestID.h"

@class DFImageRequestOptions;


@protocol DFCoreImageManager <NSObject>

- (BOOL)canHandleRequest:(DFImageRequest *)request;

- (DFImageRequestID *)requestImageForRequest:(DFImageRequest *)request completion:(void (^)(UIImage *image, NSDictionary *info))completion;

/*! Advices the image manager that the request should be cancelled. This method doesn't force the request to be cancelled.
 */
- (void)cancelRequestWithID:(DFImageRequestID *)requestID;

- (void)setPriority:(DFImageRequestPriority)priority forRequestWithID:(DFImageRequestID *)requestID;

- (void)startPreheatingImagesForRequests:(NSArray /* DFImageRequest */ *)requests;
- (void)stopPreheatingImagesForRequests:(NSArray /* DFImageRequest */ *)requests;

/*! Cancels all image preheating operations.
 @note Do not cancel operations that were started as a preheat operations but than were assigned 'real' handlers.
 */
- (void)stopPreheatingImageForAllAssets;

@end


/*! Convenience methods.
 @discussion Implementation details. All you need to do is pack given parameters in a DFImageRequest object and dispatch it to the appropriate DFCoreImageManager method.
 */
@protocol DFConvenienceImageManager <NSObject>

/*! Requests an image representation for the specified asset.
 @param asset The asset whose image data is to be loaded. If asset is nil behavior is undefined.
 @param targetSize The target size in pixels of image to be returned.
 @param contentMode An option for how to fit the image to the aspect ratio of the requested size. For details, see DFImageContentMode.
 @param options Options specifying how image manager should handle the request.
 @param completion A block to be called when loading is complete, providing the requested image and information about the status of the request.
 */
- (DFImageRequestID *)requestImageForAsset:(id)asset targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options completion:(void (^)(UIImage *image, NSDictionary *info))completion;

- (void)startPreheatingImageForAssets:(NSArray *)assets targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options;

- (void)stopPreheatingImagesForAssets:(NSArray *)assets targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options;

@end


@protocol DFImageManager <DFCoreImageManager, DFConvenienceImageManager>

@end
