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

#import "DFURLSessionOperation.h"
#import "DFImageFetching.h"
#import <Foundation/Foundation.h>

@class DFURLImageFetcher;


/*! A URL response received by the URL loading system (NSURLRequest). Clients may use it to retrieve HTTP status code and other metadata associated with a URL load.
 */
extern NSString *const DFImageInfoURLResponseKey;

/*! The DFURLImageFetcherDelegate protocol describes the methods that DFURLImageFetcher objects call on their delegates to customize its behavior.
 */
@protocol DFURLImageFetcherDelegate <NSObject>

@optional

/*! Sent before the DFURLImageFetcher creates a DFURLSessionOperation for load.
 @param fetcher The image fetcher sending the message.
 @param imageRequest The image request.
 @param URLRequest The proposed URL request to used for image load.
 @return The delegate may return modified, unmodified NSURLResponse or create NSURLResponse from scratch.
 */
- (NSURLRequest *)URLImageFetcher:(DFURLImageFetcher *)fetcher URLRequestForImageRequest:(DFImageRequest *)imageRequest URLRequest:(NSURLRequest *)URLRequest;

/*! Creates operation for a given request.
 */
- (DFURLSessionOperation *)URLImageFetcher:(DFURLImageFetcher *)fetcher operationForImageRequest:(DFImageRequest *)imageRequest URLRequest:(NSURLRequest *)URLRequest;

/*! Creates response deserializer for a given request.
 */
- (id<DFURLResponseDeserializing>)URLImageFetcher:(DFURLImageFetcher *)fetcher responseDeserializerForImageRequest:(DFImageRequest *)imageRequest URLRequest:(NSURLRequest *)URLRequest;

@end


/*! The DFURLImageFetcher implements DFImageFetching protocol to provide a functionality of fetching images using Cocoa URL Loading System.
 @note Uses NSURLSession with a custom delegate. For more info on NSURLSession life cycle with custom delegates see the "URL Loading System Programming Guide" from Apple.
 @note Supported URL schemes: http, https, ftp, file and data
 */
@interface DFURLImageFetcher : NSObject <DFImageFetching, NSURLSessionDelegate, NSURLSessionDataDelegate, DFURLSessionOperationDelegate>

/*! The NSURLSession instance used by the image fetcher.
 */
@property (nonatomic, readonly) NSURLSession *session;

/*! A set containing all the supported URL schemes. The default set contains "http", "https", "ftp", "file" and "data" schemes.
 @note The property can be changed in case there are any custom protocols supported by NSURLSession.
 */
@property (nonatomic) NSSet *supportedSchemes;

/*! The delegate of the DFURLImageFetcher.
 */
@property (nonatomic, weak) id<DFURLImageFetcherDelegate> delegate;

/*! Initializes DFURLImageFetcher with a given session configuration. DFURLImageFetcher creates an instance of NSURLSession with a given configuration and sets itself as a session delegate.
 */
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration;

/*! Initializes DFURLImageFetcher with a given session configuration, delegate and delegate queue. DFURLImageFetcher creates an instance of NSURLSession with a given configuration, delegate and delegate queue.
 */
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration sessionDelegate:(id<NSURLSessionDelegate, DFURLSessionOperationDelegate>)sessionDelegate delegateQueue:(NSOperationQueue *)queue NS_DESIGNATED_INITIALIZER;

@end
