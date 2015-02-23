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

#import "DFImageRequestOptions.h"

/*! Image request options specific for URL loading system.
 @discussion In some cases, the policies defined in NSURLSessionConfiguration may be overridden by policies specified by an DFURLImageRequestOptions. Any policy specified on the request object is respected unless the session’s policy is more restrictive. For example, if the session configuration specifies that cellular networking should not be allowed, the NSURLRequest object cannot request cellular networking.
 */
@interface DFURLImageRequestOptions : DFImageRequestOptions

/*! The receiver’s cache policy. Default value is NSURLRequestUseProtocolCachePolicy.
 @note In order to completely ignore cached images you should also disable memory caching using memoryCachePolicy property.
 */
@property (nonatomic) NSURLRequestCachePolicy cachePolicy;

@end
