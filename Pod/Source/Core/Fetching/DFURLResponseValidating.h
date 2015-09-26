// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*! Validation error domain.
 */
static NSString *const DFURLValidationErrorDomain = @"DFURLValidationErrorDomain";

/*! A URL response (NSURLResponse).
 */
static NSString *const DFURLErrorInfoURLResponseKey = @"DFURLErrorInfoURLResponseKey";

/*! The DFURLResponseValidating protocol is adopted by an object that validates image response.
*/
@protocol DFURLResponseValidating <NSObject>

/*! Validates response and data associated with it.
 */
- (BOOL)isValidResponse:(nullable NSURLResponse *)response data:(nullable NSData *)data error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
