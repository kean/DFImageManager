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

#import "DFURLCacheLookupOperation.h"
#import "DFImageResponse.h"


@implementation DFURLCacheLookupOperation {
    DFImageResponse *_response;
}

- (instancetype)initWithRequest:(NSURLRequest *)request cache:(NSURLCache *)cache {
    if (self = [super init]) {
        _request = request;
        _cache = cache;
    }
    return self;
}

- (void)main {
    NSCachedURLResponse *response = [self.cache cachedResponseForRequest:self.request];
    UIImage *image;
    if (response != nil) {
        image = [[UIImage alloc] initWithData:response.data scale:[UIScreen mainScreen].scale];
    }
    _response = [[DFImageResponse alloc] initWithImage:image];
}

#pragma mark - <DFImageManagerOperation>

- (DFImageResponse *)imageResponse {
    return _response;
}

@end
