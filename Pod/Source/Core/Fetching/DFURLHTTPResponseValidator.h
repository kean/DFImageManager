// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

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
@property (nullable, nonatomic, copy) NSSet<NSString *> *acceptableContentTypes;

@end
