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

/*! For more info check the enumerations and other definitions provided in this header file:
 */
#import "DFImageManagerDefines.h"

@class DFImageRequest;
@class DFImageRequestOptions;
@class DFImageRequestID;

typedef void (^DFImageRequestCompletion)(UIImage *image, NSDictionary *info);


/*! Provides an API for loading images associated with a given resources. The resources might by anything from a NSURL to a PHAsset objects or even your custom classes.
 */
@protocol DFImageManagingCore <NSObject>

/*! Inspects the given request and determines whether or not it can be handled.
 */
- (BOOL)canHandleRequest:(DFImageRequest *)request;

/*! Requests an image representation for the specified request.
 @param request The request that contains the resource whose image it to be loaded as well as other request options. The implementation should create a deep copy of the request so that it can't be changed underneath it later. The implementation may provide more request options that are available in a base class, so make sure to check the documentation on that.
 @param completion A block to be called when image loading is complete, providing the requested image or information about the status of the request. The info dictionary provides information about the status of the request. See the definitions of DFImageInfo*Key strings for possible keys and values.
 @return An unique identifier for the request, which can be used to cancel the request or change its priority.
 */
- (DFImageRequestID *)requestImageForRequest:(DFImageRequest *)request completion:(void (^)(UIImage *image, NSDictionary *info))completion;

/*! Advices the image manager that the request with a given ID should be cancelled. 
 @note The method has the same effect as calling -cancel method on a request ID itself.
 */
- (void)cancelRequestWithID:(DFImageRequestID *)requestID;

/*! Changes the priority of a request with a given ID.
 @note The method has the same effect as calling -setPriority: method on a request ID itself.
 */
- (void)setPriority:(DFImageRequestPriority)priority forRequestWithID:(DFImageRequestID *)requestID;

/*! Prepares image representations of the specified resources and options for later use.
 @note The application is responsible for providing the same requests when preheating the images and when actually requesting them later or else the preheating might be either partially effective or not effective at all.
 */
- (void)startPreheatingImagesForRequests:(NSArray /* DFImageRequest */ *)requests;

/*! Cancels image preparation for the resources assets and options.
 */
- (void)stopPreheatingImagesForRequests:(NSArray /* DFImageRequest */ *)requests;

/*! Cancels all image preheating requests registered with a manager.
 */
- (void)stopPreheatingImagesForAllRequests;

@end


/*! Convenience methods for classes that implement <DFImageManagingCore> protocol. In general, implementation should not do anything apart from creating instances of DFImageRequest class for the given resources and options and then dispatching them to the <DFImageManagingCore> methods.
 */
@protocol DFImageManaging <DFImageManagingCore>

/*! Requests an image representation for the specified resource.
 @param resource The resource whose image data is to be loaded.
 @param targetSize The size in pixels of image to be returned.
 @param contentMode An option for how to fit the image to the aspect ratio of the requested size. For details, see DFImageContentMode.
 @param options Options specifying how image manager should handle the request and process the received image. More options that are provided in a base class may be available, so make sure to check the documentation on that.
 @param completion A block to be called when loading is complete, providing the requested image and information about the status of the request.
 */
- (DFImageRequestID *)requestImageForResource:(id)resource targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options completion:(void (^)(UIImage *image, NSDictionary *info))completion;

/*! Requests an image representation with a maximum available size for the specified resource.
 */
- (DFImageRequestID *)requestImageForResource:(id)resource completion:(void (^)(UIImage *image, NSDictionary *info))completion;

/*! Prepares image representations of the specified resources and options for later use. 
 @note The application is responsible for providing the same requests when preheating the images and when actually requesting them later or else the preheating might be either partially effective or not effective at all.
 */
- (void)startPreheatingImageForResources:(NSArray *)resources targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options;

/*! Cancels image preparation for the resources assets and options.
 */
- (void)stopPreheatingImagesForResources:(NSArray *)resources targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options;

@end
