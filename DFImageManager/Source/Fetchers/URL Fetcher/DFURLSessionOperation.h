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

#import "DFOperation.h"

@protocol DFURLResponseDeserializing;

typedef void (^DFURLSessionProgressHandler)(int64_t countOfBytesReceived, int64_t countOfBytesExpectedToReceive);
typedef void (^DFURLSessionCompletionHandler)(NSData *data, NSURLResponse *response, NSError *error);


@class DFURLSessionOperation;

@protocol DFURLSessionOperationDelegate <NSObject>

/*! The DFURLSessionOperation delegates the creation and managing of the NSURLSessionDataTask to its delegate.
 */
- (NSURLSessionDataTask *)URLSessionOperation:(DFURLSessionOperation *)operation dataTaskWithRequest:(NSURLRequest *)request progressHandler:(DFURLSessionProgressHandler)progressHandler completionHandler:(DFURLSessionCompletionHandler)completionHandler;

@end


/*! The NSURLSessionDataTask wrapper. The NSURLSession flow with a custom delegate requires a lot of redirection. For more info on NSURLSession life cycle with custom delegates see the "URL Loading System Programming Guide" from Apple.
 */
@interface DFURLSessionOperation : DFOperation

@property (nonatomic) id<DFURLResponseDeserializing> deserializer;
@property (nonatomic) id<DFURLSessionOperationDelegate> delegate;
@property (nonatomic, copy) DFURLSessionProgressHandler progressHandler;

@property (nonatomic, readonly) NSURLRequest *request;
@property (nonatomic, readonly) NSURLResponse *response;
@property (nonatomic, readonly) NSData *data;
@property (nonatomic, readonly) id responseObject;
@property (nonatomic, readonly) NSError *error;

- (instancetype)initWithRequest:(NSURLRequest *)request NS_DESIGNATED_INITIALIZER;

@end


@interface DFURLSessionOperation (HTTP)

@property (nonatomic, readonly) NSHTTPURLResponse *HTTPResponse;

@end
