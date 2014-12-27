//
//  TDFImageManager.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 12/26/14.
//  Copyright (c) 2014 Alexander Grebenyuk. All rights reserved.
//

#import "DFImageManagerKit.h"
#import "TDFTesting.h"
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <XCTest/XCTest.h>


@interface TDFImageManager : XCTestCase

@end

@implementation TDFImageManager {
    id<DFImageManager> _imageManager;
}

- (void)setUp {
    [super setUp];

    id<DFImageManagerConfiguration> configuration = [[DFNetworkImageManagerConfiguration alloc] initWithCache:nil];
    _imageManager = [[DFImageManager alloc] initWithConfiguration:configuration imageProcessingManager:nil];
}

- (void)tearDown {
    [super tearDown];
    
}

#pragma mark - Smoke Tests

- (void)testThatImageManagerWorks {
    UIImage *testImage = [TDFTesting testImage];
    NSData *data = UIImageJPEGRepresentation(testImage, 1.0);
    
    NSString *imageURL = @"test://imagemanager.com/image.jpg";
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString isEqualToString:imageURL];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [[OHHTTPStubsResponse alloc] initWithData:data statusCode:200 headers:nil];
    }];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"image_fetched"];
    
    [_imageManager requestImageForAsset:imageURL targetSize:DFImageManagerMaximumSize contentMode:DFImageContentModeDefault options:nil completion:^(UIImage *image, NSDictionary *info) {
        XCTAssertNotNil(image);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

@end
