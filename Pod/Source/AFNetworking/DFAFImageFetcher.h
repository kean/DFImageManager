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
#import <AFNetworking/AFURLSessionManager.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*! The NSNumber with NSURLRequestCachePolicy value that specifies a request cache policy.
 @note Should be put into DFImageRequestOptions userInfo dictionary.
 */
extern NSString *const DFAFRequestCachePolicyKey;

@class DFAFImageFetcher;

/*! The DFAFImageFetcherDelegate protocol describes the methods that DFAFImageFetcher objects call on their delegates to customize its behaviour.
 */
@protocol DFAFImageFetcherDelegate <NSObject>

@optional

/*! Sent to allow delegate to modify the given URL request.
 @param fetcher The image fetcher sending the message.
 @param imageRequest The image request.
 @param URLRequest The proposed URL request to used for image load.
 @return The delegate may return modified, unmodified NSURLResponse or create NSURLResponse from scratch.
 */
- (NSURLRequest *)imageFetcher:(DFAFImageFetcher *)fetcher URLRequestForImageRequest:(DFImageRequest *)imageRequest URLRequest:(NSURLRequest *)URLRequest;

@end

/*! The DFAFURLImageFetcher implements DFImageFetching protocol using AFNetworking library.
 @note AFNetworking doesn't track progress of NSURLSessionDataTask objects, tracking progress it currently not implemented.
 */
@interface DFAFImageFetcher : NSObject <DFImageFetching>

/*! The session manager that the receiver was initialized with.
 */
@property (nonatomic, readonly) AFURLSessionManager *sessionManager;

/*! The delegate of the receiver.
 */
@property (nullable, nonatomic, weak) id<DFAFImageFetcherDelegate> delegate;

/*! A set containing all the supported URL schemes. The default set contains "http", "https", "ftp", "file" and "data" schemes.
 @note The property can be changed in case there are any custom protocols supported by NSURLSession.
 */
@property (nonatomic, copy) NSSet *supportedSchemes;

/*! Initializes the DFURLImageFetcher with a given session manager.
 */
- (instancetype)initWithSessionManager:(AFURLSessionManager *)sessionManager NS_DESIGNATED_INITIALIZER;

/*! Unavailable initializer, please use designated initializer.
 */
- (nullable instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
