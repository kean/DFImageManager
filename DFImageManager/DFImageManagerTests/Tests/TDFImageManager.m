//
//  TDFImageManager.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 12/26/14.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
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

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.URLCache = nil;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    
    id<DFImageFetcher> fetcher = [[DFURLImageFetcher alloc] initWithSession:session];
    _imageManager = [[DFImageManager alloc] initWithImageFetcher:fetcher processor:nil cache:nil];
}

- (void)tearDown {
    [super tearDown];
    
    [OHHTTPStubs removeAllStubs];
}

#pragma mark - Smoke Tests

- (void)testThatImageManagerWorks {
    NSURL *imageURL = [NSURL URLWithString:@"http://imagemanager.com/image.jpg"];
    [TDFTesting stubRequestWithURL:imageURL];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"image_fetched"];
    XCTAssertTrue([_imageManager canHandleRequest:[[DFImageRequest alloc] initWithAsset:imageURL]]);
    
    [_imageManager requestImageForAsset:imageURL targetSize:DFImageManagerMaximumSize contentMode:DFImageContentModeDefault options:nil completion:^(UIImage *image, NSDictionary *info) {
        XCTAssertNotNil(image);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

- (void)testThatImageManagerHandlesErrors {
    NSURL *imageURL = [NSURL URLWithString:@"http://imagemanager.com/image.jpg"];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL isEqual:imageURL];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:nil]];
    }];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"fetch_failed"];
    
    XCTAssertTrue([_imageManager canHandleRequest:[[DFImageRequest alloc] initWithAsset:imageURL]]);
    
    [_imageManager requestImageForAsset:imageURL targetSize:DFImageManagerMaximumSize contentMode:DFImageContentModeDefault options:nil completion:^(UIImage *image, NSDictionary *info) {
        NSError *error = info[DFImageInfoErrorKey];
        XCTAssertTrue([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorNotConnectedToInternet);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

#pragma mark - DFURLImageFetcher

- (void)testThatURLFetcherSupportsFileSystemURL {
    NSURL *fileURL = [TDFTesting testImageURL];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"fetch_failed"];
    
    [_imageManager requestImageForAsset:fileURL targetSize:DFImageManagerMaximumSize contentMode:DFImageContentModeDefault options:nil completion:^(UIImage *image, NSDictionary *info) {
        XCTAssertNotNil(image);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

@end
