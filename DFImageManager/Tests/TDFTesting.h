//
//  TDFTesting.h
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 12/26/14.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static inline BOOL
TDFSystemVersionGreaterThanOrEqualTo(NSString *version) {
    return [[[UIDevice currentDevice] systemVersion] compare:version options:NSNumericSearch] != NSOrderedAscending;
}

@interface TDFTesting : NSObject

+ (NSURL *)testImageURL;
+ (UIImage *)testImage;
+ (NSData *)testImageData;

+ (UIImage *)testImage2;
+ (NSData *)testImageData2;

+ (void)stubRequestWithURL:(NSURL *)imageURL;

@end
