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

#import "DFURLResponseDeserializing.h"


@interface DFURLConnectionOperation : NSOperation

@property (nonatomic) id<DFURLResponseDeserializing> deserializer;
@property (nonatomic, readonly) NSURLSession *session;
@property (nonatomic, readonly) NSURLRequest *request;

@property (nonatomic, readonly) NSURLResponse *response;
@property (nonatomic, readonly) NSData *data;
@property (nonatomic, readonly) id responseObject;
@property (nonatomic, readonly) NSError *error;

- (instancetype)initWithRequest:(NSURLRequest *)request session:(NSURLSession *)session NS_DESIGNATED_INITIALIZER;

@end


@interface DFURLConnectionOperation (HTTP)

@property (nonatomic, readonly) NSHTTPURLResponse *HTTPResponse;

@end
