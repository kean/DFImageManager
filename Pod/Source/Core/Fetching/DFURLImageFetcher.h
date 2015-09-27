// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageFetching.h"
#import <Foundation/Foundation.h>

@class DFURLImageFetcher;
@protocol DFURLResponseValidating;

NS_ASSUME_NONNULL_BEGIN

/*! The NSNumber with NSURLRequestCachePolicy value that specifies a request cache policy.
 @note Should be put into DFImageRequestOptions userInfo dictionary.
 */
extern NSString *const DFURLRequestCachePolicyKey;


/*! Delegate that allows to customize DFURLImageFetcher.
 */
@protocol DFURLImageFetcherDelegate <NSObject>

@optional

/*! Allows delegate to modify the given URL request.
 @param URLRequest The default URL request.
 @return The delegate may return unmodified NSURLResponse or create new NSURLResponse instance.
 */
- (NSURLRequest *)URLImageFetcher:(DFURLImageFetcher *)fetcher URLRequestForImageRequest:(DFImageRequest *)imageRequest URLRequest:(NSURLRequest *)URLRequest;

/*! Creates response validator for a given request.
 */
- (nullable id<DFURLResponseValidating>)URLImageFetcher:(DFURLImageFetcher *)fetcher responseValidatorForURLRequest:(NSURLRequest *)URLRequest;

@end


/*! The DFURLImageFetcher provides basic networking using NSURLSession.
 */
@interface DFURLImageFetcher : NSObject <DFImageFetching, NSURLSessionDelegate, NSURLSessionDataDelegate>

/*! The NSURLSession instance used by the image fetcher.
 */
@property (nonatomic, readonly) NSURLSession *session;

/*! A set containing all the supported URL schemes. The default set contains "http", "https", "ftp", "file" and "data" schemes.
 */
@property (nonatomic, copy) NSSet<NSString *> *supportedSchemes;

/*! The delegate of the receiver.
 */
@property (nullable, nonatomic, weak) id<DFURLImageFetcherDelegate> delegate;

/*! Initializes DFURLImageFetcher with a given session configuration.
 */
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration;

/*! Initializer DFURLImageFetcher with default session configuration.
 */
- (nullable instancetype)init;

@end

NS_ASSUME_NONNULL_END
