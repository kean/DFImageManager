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

#import "DFURLResponseValidating.h"

/*! The DFURLHTTPResponseValidator performs response validation based on HTTP status code and content type.
 */
@interface DFURLHTTPResponseValidator : NSObject <DFURLResponseValidating>

/*! The acceptable HTTP status codes for responses. For more info see the HTTP specification http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
 @note All status codes are acceptable in case acceptableStatusCodes is nil.
 */
@property (nullable, nonatomic, copy) NSIndexSet *acceptableStatusCodes;

/*! The acceptable MIME types for responses. Default value is nil so that all content types are supported. Image initialization never crashes when provided with an invalid data.
 @note All content types are acceptable in case acceptableContentTypes is nil.
 */
@property (nullable, nonatomic, copy) NSSet *acceptableContentTypes;

@end
