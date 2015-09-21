// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageFetching.h"
#import <AFNetworking/AFURLSessionManager.h>
#import <Foundation/Foundation.h>

/*! The NSNumber with NSURLRequestCachePolicy value that specifies a request cache policy.
 @note Should be put into DFImageRequestOptions userInfo dictionary.
 */
extern NSString *__nonnull const DFAFRequestCachePolicyKey;

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
- (nonnull NSURLRequest *)imageFetcher:(nonnull DFAFImageFetcher *)fetcher URLRequestForImageRequest:(nonnull DFImageRequest *)imageRequest URLRequest:(nonnull NSURLRequest *)URLRequest;

@end

/*! The DFAFURLImageFetcher implements DFImageFetching protocol using AFNetworking library.
 @note AFNetworking doesn't track progress of NSURLSessionDataTask objects, tracking progress it currently not implemented.
 */
@interface DFAFImageFetcher : NSObject <DFImageFetching>

/*! The session manager that the receiver was initialized with.
 */
@property (nonnull, nonatomic, readonly) AFURLSessionManager *sessionManager;

/*! The delegate of the receiver.
 */
@property (nullable, nonatomic, weak) id<DFAFImageFetcherDelegate> delegate;

/*! A set containing all the supported URL schemes. The default set contains "http", "https", "ftp", "file" and "data" schemes.
 @note The property can be changed in case there are any custom protocols supported by NSURLSession.
 */
@property (nonnull, nonatomic, copy) NSSet<NSString *> *supportedSchemes;

/*! Initializes the DFURLImageFetcher with a given session manager.
 */
- (nonnull instancetype)initWithSessionManager:(nonnull AFURLSessionManager *)sessionManager NS_DESIGNATED_INITIALIZER;

/*! Unavailable initializer, please use designated initializer.
 */
- (nullable instancetype)init NS_UNAVAILABLE;

@end
