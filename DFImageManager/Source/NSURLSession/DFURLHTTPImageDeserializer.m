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

#import "DFURLHTTPResponseValidator.h"

@implementation DFURLHTTPResponseValidator

- (nonnull instancetype)init {
    if (self = [super init]) {
        _acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
        _acceptableContentTypes = nil;
    }
    return self;
}

- (BOOL)isValidResponse:(nullable NSHTTPURLResponse *)response data:(nullable NSData *)data error:(NSError * __nullable __autoreleasing * __nullable)error {
    if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
        return NO;
    }
    if (self.acceptableStatusCodes != nil && ![self.acceptableStatusCodes containsIndex:(NSUInteger)response.statusCode]) {
        if (error != nil) {
            NSDictionary *userInfo = [self _errorInfoWithResponse:response];
            *error = [NSError errorWithDomain:DFURLValidationErrorDomain code:NSURLErrorBadServerResponse userInfo:[userInfo copy]];
        }
        return NO;
    }
    if (self.acceptableContentTypes != nil && ![self.acceptableContentTypes containsObject:[response MIMEType]]) {
        if (error != nil) {
            NSDictionary *userInfo = [self _errorInfoWithResponse:response];
            *error = [NSError errorWithDomain:DFURLValidationErrorDomain code:NSURLErrorCannotDecodeContentData userInfo:[userInfo copy]];
        }
        return NO;
    }
    return YES;
}

- (nonnull NSMutableDictionary *)_errorInfoWithResponse:(nonnull NSURLResponse *)response {
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    userInfo[DFURLErrorInfoURLResponseKey] = response;
    if (response.URL != nil) {
        userInfo[NSURLErrorFailingURLErrorKey] = response.URL;
    }
    return userInfo;
}

@end
