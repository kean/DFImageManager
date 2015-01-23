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

extern NSString *const DFImageInfoURLResponseKey;


/*! The DFURLImageFetcher is a class that implements DFImageFetching protocol to provide a functionality of fetching images via Cocoa URL Loading System.
 @note Uses NSURLSession with a custom delegate. For more info on NSURLSession life cycle with custom delegates see the "URL Loading System Programming Guide" from Apple.
 @note Supported URL schemes: http:, https:, ftp:, file:
 */
@interface DFURLImageFetcher : NSObject <DFImageFetching, NSURLSessionDelegate, NSURLSessionDataDelegate, DFURLSessionOperationDelegate>

/*! The NSURLSession instance used by the reciever.
 */
@property (nonatomic, readonly) NSURLSession *session;

/*! A set containing all the supported URL schemes. The default set contains "http", "https", "ftp", "file" and "data" schemes.
 @note The property can be changed in case there are any custom protocols supported by NSURLSession.
 */
@property (nonatomic) NSSet *supportedSchemes;

/*! Initializes DFURLImageFetcher with a given session configuration. DFURLImageFetcher creates an instance of NSURLSession with a given configuration and sets itself as a session delegate.
 */
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration;

/*! Initializes DFURLImageFetcher with a given session configuration, delegate and delegate queue. DFURLImageFetcher creates an instance of NSURLSession with a given configuration, delegate and delegate queue.
 */
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration delegate:(id<NSURLSessionDelegate, DFURLSessionOperationDelegate>)delegate delegateQueue:(NSOperationQueue *)queue NS_DESIGNATED_INITIALIZER;

@end
