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

+ (id)testImage {
    return [[UIImage alloc] initWithData:[self _testImageData] scale:[UIScreen mainScreen].scale];
}

+ (NSURL *)testImageURL {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:@"Image" ofType:@"jpg"];
    return [NSURL fileURLWithPath:path];
}

+ (NSData *)_testImageData {
    return [NSData dataWithContentsOfURL:[self testImageURL]];
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
