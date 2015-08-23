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
#import <Foundation/Foundation.h>

@protocol DFURLResponseValidating;
@class DFURLImageFetcher;

NS_ASSUME_NONNULL_BEGIN

/*! The NSNumber with NSURLRequestCachePolicy value that specifies a request cache policy.
 @note Should be put into DFImageRequestOptions userInfo dictionary.
 */
extern NSString *const DFURLRequestCachePolicyKey;


/*! The DFURLImageFetcherDelegate protocol describes the methods that DFURLImageFetcher objects call on their delegates to customize its behaviour.
 */
@protocol DFURLImageFetcherDelegate <NSObject>

@optional

/*! Sent to allow delegate to modify the given URL request.
 @param fetcher The image fetcher sending the message.
 @param imageRequest The image request.
 @param URLRequest The proposed URL request to used for image load.
 @return The delegate may return modified, unmodified NSURLResponse or create NSURLResponse from scratch.
 */
- (NSURLRequest *)URLImageFetcher:(DFURLImageFetcher *)fetcher URLRequestForImageRequest:(DFImageRequest *)imageRequest URLRequest:(NSURLRequest *)URLRequest;

/*! Creates response validator for a given request.
 */
- (nullable id<DFURLResponseValidating>)URLImageFetcher:(DFURLImageFetcher *)fetcher responseValidatorForImageRequest:(DFImageRequest *)imageRequest URLRequest:(NSURLRequest *)URLRequest;

/*! Sent every time image fetcher encounters error. Doesn't get called if image fetcher isn't set as NSURLSession delegate.
 */
- (void)URLImageFetcher:(DFURLImageFetcher *)fetcher didEncounterError:(NSError *)error;

@end


/*! The DFURLImageFetcherSessionDelegate protocol should be implemented by your classes if you initialize DFURLImageFetcher with an instance of NSURLSession and implement NSURLSession delegate by yourself.
 */
@protocol DFURLImageFetcherSessionDelegate <NSObject>

/*! Creates NSURLSessionDataTask with a given request.
 */
- (NSURLSessionDataTask *)URLImageFetcher:(DFURLImageFetcher *)fetcher dataTaskWithRequest:(NSURLRequest *)request progressHandler:(void (^__nullable)(NSData *__nullable data, int64_t countOfBytesReceived, int64_t countOfBytesExpectedToReceive))progressHandler completionHandler:(void (^__nullable)(NSData *__nullable data, NSURLResponse *__nullable response, NSError *__nullable error))completionHandler;

@end

/*! The DFURLImageFetcher implements DFImageFetching protocol to provide a functionality of fetching images using Cocoa URL Loading System.
 @note Uses NSURLSession with a custom delegate. For more info on NSURLSession life cycle with custom delegates see the "URL Loading System Programming Guide" from Apple.
 @note Supported URL schemes: http, https, ftp, file and data
 */
@interface DFURLImageFetcher : NSObject <DFImageFetching, NSURLSessionDelegate, NSURLSessionDataDelegate, DFURLImageFetcherSessionDelegate>

/*! The NSURLSession instance used by the image fetcher.
 */
@property (nonatomic, readonly) NSURLSession *session;

/*! A set containing all the supported URL schemes. The default set contains "http", "https", "ftp", "file" and "data" schemes.
 @note The property can be changed in case there are any custom protocols supported by NSURLSession.
 */
@property (nonatomic, copy) NSSet *supportedSchemes;

/*! The delegate of the receiver.
 */
@property (nullable, nonatomic, weak) id<DFURLImageFetcherDelegate> delegate;

/*! The session delegate of the receiver.
 */
@property (nullable, nonatomic, weak) id<DFURLImageFetcherSessionDelegate> sessionDelegate;

/*! Initializes the DFURLImageFetcher with a given session configuration. The DFURLImageFetcher sets itself as a NSURLSessionDelegate and DFURLImageFetcherSessionDelegate.
 */
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration;

/*! Initializes the DFURLImageFetcher with a given session and sessionDelegate.
 @param session The NSURLSession instance that is used with a custom delegate. For more info on NSURLSession life cycle with custom delegates see the "URL Loading System Programming Guide" from Apple.
 @param sessionDelegate Apart from implementing NSURLSessionDataDelegate protocol your classes should also provide a DFURLImageFetcherSessionDelegate implementation.
 */
- (instancetype)initWithSession:(NSURLSession *)session sessionDelegate:(id<DFURLImageFetcherSessionDelegate>)sessionDelegate NS_DESIGNATED_INITIALIZER;

/*! Unavailable initializer, please use designated initializer.
 */
- (nullable instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
