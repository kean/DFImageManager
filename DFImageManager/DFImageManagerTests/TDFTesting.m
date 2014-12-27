//
//  TDFTesting.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 12/26/14.
//  Copyright (c) 2014 Alexander Grebenyuk. All rights reserved.
//

#import "TDFTesting.h"


@implementation TDFTesting

+ (id)testImage {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:@"Image" ofType:@"jpg"];
    return [UIImage imageWithContentsOfFile:path];
}

@end
