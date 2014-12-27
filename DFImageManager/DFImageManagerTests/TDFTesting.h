//
//  TDFTesting.h
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 12/26/14.
//  Copyright (c) 2014 Alexander Grebenyuk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface TDFTesting : NSObject

+ (UIImage *)testImage;
+ (void)stubRequestWithURL:(NSString *)imageURL;

@end
