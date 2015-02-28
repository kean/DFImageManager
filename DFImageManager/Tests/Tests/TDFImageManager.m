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
#import "NSURL+DFPhotosKit.h"
#import <XCTest/XCTest.h>


/*! The TDFImageManager is a test suite for DFImageManager class.
 */
@interface TDFImageManager : XCTestCase

@end

@implementation TDFImageManager {
    DFImageManager *_imageManager;
}

- (void)setUp {
    [super setUp];
    
    // Simple configuration without processor and cache.
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    id<DFImageFetching> fetcher = [[DFURLImageFetcher alloc] initWithSessionConfiguration:configuration];
    _imageManager = [[DFImageManager alloc] initWithConfiguration:[[DFImageManagerConfiguration alloc] initWithFetcher:fetcher]];
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
    XCTAssertTrue([_imageManager canHandleRequest:[[DFImageRequest alloc] initWithResource:imageURL]]);
    
    [_imageManager requestImageForResource:imageURL targetSize:DFImageMaximumSize contentMode:DFImageContentModeAspectFill options:nil completion:^(UIImage *image, NSDictionary *info) {
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
    
    XCTAssertTrue([_imageManager canHandleRequest:[[DFImageRequest alloc] initWithResource:imageURL]]);
    
    [_imageManager requestImageForResource:imageURL targetSize:DFImageMaximumSize contentMode:DFImageContentModeAspectFill options:nil completion:^(UIImage *image, NSDictionary *info) {
        NSError *error = info[DFImageInfoErrorKey];
        XCTAssertTrue([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorNotConnectedToInternet);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

#pragma mark - Operation Reuse

- (void)testThatImageManagerReusesFetchOperationsForSameURLs {
    // Start two requests. Image manager is initialized without a memory cache, so it will have to use fetcher for both requests.
    
    NSUInteger __block countOfResponses = 0;
    
    NSData *data = [TDFTesting testImageData];
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL isEqual:[NSURL URLWithString:@"http://imagemanager.com/image.jpg"]];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        countOfResponses++;
        return [[OHHTTPStubsResponse alloc] initWithData:data statusCode:200 headers:nil];
    }];
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"first_fetch_complete"];
    [_imageManager requestImageForResource:[NSURL URLWithString:@"http://imagemanager.com/image.jpg"] completion:^(UIImage *image, NSDictionary *info) {
        XCTAssertNotNil(image);
        [expectation1 fulfill];
    }];
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"second_fetch_complete"];
    [_imageManager requestImageForResource:[NSURL URLWithString:@"http://imagemanager.com/image.jpg"] completion:^(UIImage *image, NSDictionary *info) {
        XCTAssertNotNil(image);
        [expectation2 fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:^(NSError *error) {
        XCTAssertTrue(countOfResponses == 1);
    }];
}

#pragma mark - DFURLImageFetcher

- (void)testThatURLFetcherSupportsFileSystemURL {
    NSURL *fileURL = [TDFTesting testImageURL];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"fetch_failed"];
    
    [_imageManager requestImageForResource:fileURL targetSize:DFImageMaximumSize contentMode:DFImageContentModeAspectFill options:nil completion:^(UIImage *image, NSDictionary *info) {
        XCTAssertNotNil(image);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

@end
