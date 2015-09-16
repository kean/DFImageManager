// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

/*! Defines methods for image decoding.
 */
@protocol DFImageDecoding <NSObject>

/*! Creates and returns an image object that uses the specified image data.
 */
- (nullable UIImage *)imageWithData:(nonnull NSData *)data partial:(BOOL)partial;

@end
