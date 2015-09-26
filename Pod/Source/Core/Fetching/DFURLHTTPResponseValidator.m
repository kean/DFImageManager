// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFURLHTTPResponseValidator.h"

@implementation DFURLHTTPResponseValidator

- (nonnull instancetype)init {
    if (self = [super init]) {
        _acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    }
    return self;
}

- (BOOL)isValidResponse:(nullable NSHTTPURLResponse *)response data:(nullable NSData *)data error:(NSError * __nullable __autoreleasing * __nullable)error {
    if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
        return NO;
    }
    if (self.acceptableStatusCodes != nil && ![self.acceptableStatusCodes containsIndex:(NSUInteger)response.statusCode]) {
        if (error != nil) {
            *error = [NSError errorWithDomain:DFURLValidationErrorDomain code:NSURLErrorBadServerResponse userInfo:[self _errorInfoWithResponse:response]];
        }
        return NO;
    }
    if (self.acceptableContentTypes != nil && ![self.acceptableContentTypes containsObject:response.MIMEType]) {
        if (error != nil) {
            *error = [NSError errorWithDomain:DFURLValidationErrorDomain code:NSURLErrorCannotDecodeContentData userInfo:[self _errorInfoWithResponse:response]];
        }
        return NO;
    }
    return YES;
}

- (nonnull NSDictionary *)_errorInfoWithResponse:(nonnull NSURLResponse *)response {
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    userInfo[DFURLErrorInfoURLResponseKey] = response;
    if (response.URL != nil) {
        userInfo[NSURLErrorFailingURLErrorKey] = response.URL;
    }
    return [userInfo copy];
}

@end
