// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <Foundation/Foundation.h>

@protocol DFImageDecoding;

/*! Decodes received data at given thresholds. It would produce less decoded images if it can't keep up with the rate at which it receives data.
 @note Thread safe.
 */
@interface DFProgressiveImageDecoder : NSObject

- (nonnull instancetype)initWithQueue:(nonnull NSOperationQueue *)queue decoder:(nonnull id<DFImageDecoding>)decoder;

@property (nonatomic) float threshold;
@property (nonatomic) int64_t totalByteCount;

- (void)appendData:(nullable NSData *)data;

/*! Resumes decoding, safe to call multiple times.
 */
- (void)resume;
- (void)invalidate;

@property (nullable, atomic, copy) void (^handler)(UIImage *__nonnull image);

@end
