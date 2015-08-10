//
//  TDFTesting.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 12/26/14.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "TDFTesting.h"
#import <OHHTTPStubs.h>

@implementation TDFTesting

+ (UIImage *)testImage {
    return [[UIImage alloc] initWithData:[self testImageData] scale:[UIScreen mainScreen].scale];
}

+ (NSURL *)testImageURL {
    return [self _testImageURLForName:@"Image"];
}

+ (NSURL *)_testImageURLForName:(NSString *)name {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:name ofType:@"jpg"];
    return [NSURL fileURLWithPath:path];
}

+ (NSData *)testImageData {
    return [NSData dataWithContentsOfURL:[self testImageURL]];
}

+ (UIImage *)testImage2 {
    return [[UIImage alloc] initWithData:[self testImageData2] scale:[UIScreen mainScreen].scale];
}

+ (NSData *)testImageData2 {
    return [NSData dataWithContentsOfURL:[self _testImageURLForName:@"Image2"]];
}

+ (void)stubRequestWithURL:(NSURL *)imageURL {
    UIImage *testImage = [TDFTesting testImage];
    NSData *data = UIImageJPEGRepresentation(testImage, 1.0);
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL isEqual:imageURL];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [[OHHTTPStubsResponse alloc] initWithData:data statusCode:200 headers:nil];
    }];
}

@end
