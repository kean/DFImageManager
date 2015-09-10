//
//  TDFURLImageFetcher.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 1/22/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "DFImageManagerKit.h"
#import "TDFTestingKit.h"
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

/*! The TDFURLImageFetcher is a test suite for DFURLImageFetcher class.
 */
@interface TDFURLImageFetcher : XCTestCase

@end

@implementation TDFURLImageFetcher {
    DFURLImageFetcher *_fetcher;
}

- (void)setUp {
    [super setUp];

    _fetcher = [[DFURLImageFetcher alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
}

- (void)tearDown {
    [super tearDown];
    
    [OHHTTPStubs removeAllStubs];
}

#pragma mark - Request Fetch Equivalence

- (void)testThatRequestsAreFetchEquivalentWithSameReloadCachePolicy {
    NSURL *URL = [NSURL URLWithString:@"http://path/resourse"];
    
    DFMutableImageRequestOptions *options1 = [DFMutableImageRequestOptions new];
    options1.userInfo = @{ DFURLRequestCachePolicyKey : @(NSURLRequestReloadIgnoringCacheData) };
    DFImageRequest *request1 = [DFImageRequest requestWithResource:URL targetSize:DFImageMaximumSize contentMode:DFImageContentModeAspectFill options:options1.options];
    
    DFMutableImageRequestOptions *options2 = [DFMutableImageRequestOptions new];
    options2.userInfo = @{ DFURLRequestCachePolicyKey : @(NSURLRequestReloadIgnoringCacheData) };
    DFImageRequest *request2 = [DFImageRequest requestWithResource:URL targetSize:DFImageMaximumSize contentMode:   DFImageContentModeAspectFill options:options2.options];
    XCTAssertTrue([_fetcher isRequestFetchEquivalent:request1 toRequest:request2]);
}

- (void)testThatRequestsAreFetchEquivalentWithDefaultCachePolicy {
    NSURL *URL = [NSURL URLWithString:@"http://path/resourse"];
    
    DFImageRequest *request1 = [DFImageRequest requestWithResource:URL targetSize:DFImageMaximumSize contentMode:DFImageContentModeAspectFill options:nil];
    
    DFMutableImageRequestOptions *options = [DFMutableImageRequestOptions new];
    options.userInfo = @{ DFURLRequestCachePolicyKey : @(NSURLRequestUseProtocolCachePolicy) };
    DFImageRequest *request2 = [DFImageRequest requestWithResource:URL targetSize:DFImageMaximumSize contentMode:   DFImageContentModeAspectFill options:options.options];
    XCTAssertTrue([_fetcher isRequestFetchEquivalent:request1 toRequest:request2]);
}

- (void)testThatRequestsAreNotFetchEquivalentWithDifferentReloadCachePolicy {
    NSURL *URL = [NSURL URLWithString:@"http://path/resourse"];
    
    DFMutableImageRequestOptions *options = [DFMutableImageRequestOptions new];
    options.userInfo = @{ DFURLRequestCachePolicyKey : @(NSURLRequestReloadIgnoringCacheData) };
    DFImageRequest *request1 = [DFImageRequest requestWithResource:URL targetSize:DFImageMaximumSize contentMode:DFImageContentModeAspectFill options:options.options];

    DFImageRequest *request2 = [DFImageRequest requestWithResource:URL targetSize:DFImageMaximumSize contentMode:   DFImageContentModeAspectFill options:nil];
    XCTAssertFalse([_fetcher isRequestFetchEquivalent:request1 toRequest:request2]);
}

#pragma mark - Request Cache Equivalence

- (void)testThatRequestsWithTheSameURLAreCacheEquivalent {
    DFImageRequest *request1 = [DFImageRequest requestWithResource:[NSURL URLWithString:@"http://path/resourse"]];
    DFImageRequest *request2 = [DFImageRequest requestWithResource:[NSURL URLWithString:@"http://path/resourse"]];
    XCTAssertTrue([_fetcher isRequestCacheEquivalent:request1 toRequest:request2]);
}

- (void)testThatRequestsWithDifferentURLsAreNotCacheEquivalent {
    DFImageRequest *request1 = [DFImageRequest requestWithResource:[NSURL URLWithString:@"http://path/resourse_01"]];
    DFImageRequest *request2 = [DFImageRequest requestWithResource:[NSURL URLWithString:@"http://path/resourse_02"]];
    XCTAssertFalse([_fetcher isRequestCacheEquivalent:request1 toRequest:request2]);
}

#pragma mark - Schemes

/*! Test 'file' scheme
 */
- (void)testThatURLFetcherSupportsFileSystemURL {
    NSURL *fileURL = [TDFTesting testImageURL];
    
    DFImageRequest *request = [DFImageRequest requestWithResource:fileURL];
    XCTAssertTrue([_fetcher canHandleRequest:request]);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"fetch_completed"];
    [_fetcher startOperationWithRequest:request progressHandler:nil completion:^(NSData *__nullable data, NSDictionary *__nullable info, NSError *__nullable error) {
        XCTAssertNotNil(data);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

/*! Test 'data' scheme
 */
- (void)testThatURLImageFetcherSupportsDataScheme {
    NSData *imgData = [TDFTesting testImageData];
    NSString *dataFormatString = @"data:image/png;base64,%@";
    NSString *dataString = [NSString stringWithFormat:dataFormatString, [imgData base64EncodedStringWithOptions:0]];
    NSURL *dataURL = [NSURL URLWithString:dataString];
    
    DFImageRequest *request = [DFImageRequest requestWithResource:dataURL];
    XCTAssertTrue([_fetcher canHandleRequest:request]);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"fetch_completed"];
    [_fetcher startOperationWithRequest:request progressHandler:nil completion:^(NSData *__nullable data, NSDictionary *__nullable info, NSError *__nullable error) {
        XCTAssertNotNil(data);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

@end
