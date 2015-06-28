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

#import "DFURLHTTPImageDeserializer.h"


@implementation DFURLHTTPImageDeserializer

- (instancetype)init {
    if (self = [super init]) {
        _acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
        _acceptableContentTypes = nil;
    }
    return self;
}

- (id)objectFromResponse:(NSHTTPURLResponse *)response data:(NSData *)data error:(NSError **)error {
    if (![self isValidResponse:response error:error]) {
        return nil;
    } else {
        return [super objectFromResponse:response data:data error:error];
    }
}

- (BOOL)isValidResponse:(NSHTTPURLResponse *)response error:(NSError **)error {
    NSParameterAssert(response);
    NSAssert([response isKindOfClass:[NSHTTPURLResponse class]], @"Invalid response");
    if (self.acceptableStatusCodes != nil && ![self.acceptableStatusCodes containsIndex:(NSUInteger)response.statusCode]) {
        if (error != nil) {
            NSDictionary *userInfo = [self _errorInfoWithResponse:response];
            *error = [NSError errorWithDomain:DFURLDeserializationErrorDomain code:NSURLErrorBadServerResponse userInfo:[userInfo copy]];
        }
        return NO;
    }
    if (self.acceptableContentTypes != nil && ![self.acceptableContentTypes containsObject:[response MIMEType]]) {
        if (error != nil) {
            NSDictionary *userInfo = [self _errorInfoWithResponse:response];
            *error = [NSError errorWithDomain:DFURLDeserializationErrorDomain code:NSURLErrorCannotDecodeContentData userInfo:[userInfo copy]];
        }
        return NO;
    }
    return YES;
}

- (NSMutableDictionary *)_errorInfoWithResponse:(NSURLResponse *)response {
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    if (response.URL != nil) {
        userInfo[NSURLErrorFailingURLErrorKey] = response.URL;
    }
    if (response != nil) {
        userInfo[DFURLErrorInfoURLResponseKey] = response;
    }
    return userInfo;
}

@end
