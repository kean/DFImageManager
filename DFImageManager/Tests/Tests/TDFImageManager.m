//
//  TDFImageManager.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 12/26/14.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "DFImageManagerKit.h"
#import "TDFTestingKit.h"
#import <OHHTTPStubs/OHHTTPStubs.h>
#import "NSURL+DFPhotosKit.h"
#import <XCTest/XCTest.h>


/*! The TDFImageManager is a test suite for DFImageManager class. All tests are designed to test a single module (DFImageManager) without testing other dependencies and/or integration.
 */
@interface TDFImageManager : XCTestCase

@end

@implementation TDFImageManager {
    DFImageManager *_imageManager;
    
    TDFMockImageFetcher *_fetcher;
    TDFMockImageProcessor *_processor;
    TDFMockImageCache *_cache;
    DFImageManager *_manager;
}

- (void)setUp {
    [super setUp];
    
    _fetcher = [TDFMockImageFetcher new];
    _processor = [TDFMockImageProcessor new];
    _cache = [TDFMockImageCache new]; // Cache is disabled by default
    _manager = [[DFImageManager alloc] initWithConfiguration:[DFImageManagerConfiguration configurationWithFetcher:_fetcher processor:_processor cache:_cache]];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - Basics

- (void)testThatImageManagerFetchesImages {
    XCTestExpectation *expectation = [self expectationWithDescription:@"first_request"];
    [_manager requestImageForResource:[TDFMockResource resourceWithID:@"ID01"] completion:^(UIImage *image, NSDictionary *info) {
        XCTAssertNotNil(image);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

#pragma mark - Response Info

- (void)testThatImageManagerResponseInfoContainsRequestID {
    XCTestExpectation *expectation = [self expectationWithDescription:@"request"];
    DFImageRequestID *__block requestID = [_manager requestImageForResource:[TDFMockResource resourceWithID:@"ID01"] completion:^(UIImage *image, NSDictionary *info) {
        XCTAssertEqualObjects(info[DFImageInfoRequestIDKey], requestID);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

/*! Test that image manager response info contains error under DFImageInfoErrorKey key when request fails.
 */
- (void)testThatImageManagerResponseInfoContainsError {
    _fetcher.response = [[DFImageResponse alloc] initWithError:[NSError errorWithDomain:@"TDFErrorDomain" code:14 userInfo:nil]];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"request"];
    [_manager requestImageForResource:[TDFMockResource resourceWithID:@"ID01"] completion:^(UIImage *image, NSDictionary *info) {
        NSError *error = info[DFImageInfoErrorKey];
        XCTAssertTrue([error.domain isEqualToString:@"TDFErrorDomain"]);
        XCTAssertTrue(error.code == 14);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

- (void)testThatImageManagerResponseInfoContainsCustomUserInfo {
    DFMutableImageResponse *response = [TDFMockImageFetcher successfullResponse];
    response.userInfo = @{ @"TestKey" : @"TestValue" };
    _fetcher.response = response;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"request"];
    [_manager requestImageForResource:[TDFMockResource resourceWithID:@"ID01"] completion:^(UIImage *image, NSDictionary *info) {
        XCTAssertTrue([info[@"TestKey"] isEqualToString:@"TestValue"]);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

#pragma mark - Operation Reuse

- (void)testThatImageManagerReuseOperations {
    // Start two requests. Image manager is initialized without a memory cache, so it will have to use fetcher and processor for both requests.
    
    _fetcher.queue.suspended = YES;
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"01"]; { DFImageRequest *request1 = [[DFImageRequest alloc] initWithResource:[TDFMockResource resourceWithID:@"ID01"] targetSize:CGSizeMake(150.f, 150.f) contentMode:DFImageContentModeAspectFill options:nil];
        [_manager requestImageForRequest:request1 completion:^(UIImage *image, NSDictionary *info) {
            XCTAssertNotNil(image);
            [expectation1 fulfill];
        }];
    }
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"02"]; {
        DFImageRequest *request2 = [[DFImageRequest alloc] initWithResource:[TDFMockResource resourceWithID:@"ID01"] targetSize:CGSizeMake(150.f, 150.f) contentMode:DFImageContentModeAspectFill options:nil];
        [_manager requestImageForRequest:request2 completion:^(UIImage *image, NSDictionary *info) {
            XCTAssertNotNil(image);
            [expectation2 fulfill];
        }];
    }
    
    XCTestExpectation *expectation3 = [self expectationWithDescription:@"03"]; {
        DFImageRequest *request3 = [[DFImageRequest alloc] initWithResource:[TDFMockResource resourceWithID:@"ID01"] targetSize:CGSizeMake(100.f, 100.f) contentMode:DFImageContentModeAspectFill options:nil];
        [_manager requestImageForRequest:request3 completion:^(UIImage *image, NSDictionary *info) {
            XCTAssertNotNil(image);
            [expectation3 fulfill];
        }];
    }
    
    XCTestExpectation *expectation4 = [self expectationWithDescription:@"04"]; {
        DFImageRequest *request4 = [[DFImageRequest alloc] initWithResource:[TDFMockResource resourceWithID:@"ID02"] targetSize:CGSizeMake(100.f, 100.f) contentMode:DFImageContentModeAspectFill options:nil];
        [_manager requestImageForRequest:request4 completion:^(UIImage *image, NSDictionary *info) {
            XCTAssertNotNil(image);
            [expectation4 fulfill];
        }];
    }
    
    _fetcher.queue.suspended = NO;
    
    [self waitForExpectationsWithTimeout:3.0 handler:^(NSError *error) {
        XCTAssertEqual(_fetcher.createdOperationCount, 2);
        XCTAssertEqual(_processor.numberOfProcessedImageCalls, 3);
    }];
}

#pragma mark - Memory Cache

/*! Test that image manager calls completion block synchronously (default configuration).
 */
- (void)testThatImageManagerCallsCompletionBlockSynchonously {
    _cache.enabled = YES;
    
    TDFMockResource *resource = [TDFMockResource resourceWithID:@"ID01"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"request"];
    [_manager requestImageForResource:resource completion:^(UIImage *image, NSDictionary *info) {
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    
    BOOL __block isCompletionHandlerCalled = NO;
    [_manager requestImageForResource:resource completion:^(UIImage *image, NSDictionary *info) {
        XCTAssertNotNil(image);
        isCompletionHandlerCalled = YES;
    }];
    XCTAssertTrue(isCompletionHandlerCalled);
}

/*! Test that image manager calls completion block asynchronously with a specific configuration option.
 */
- (void)testThatImageManagerCallsCompletionBlockAsynchonously {
    DFImageManagerConfiguration *configuration = [_manager.configuration copy];
    configuration.allowsSynchronousCallbacks = NO;
    _manager = [[DFImageManager alloc] initWithConfiguration:configuration];
    
    _cache.enabled = YES;
    
    TDFMockResource *resource = [TDFMockResource resourceWithID:@"ID01"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"request"];
    [_manager requestImageForResource:resource completion:^(UIImage *image, NSDictionary *info) {
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"cache"];
    BOOL __block isCompletionHandlerCalled = NO;
    [_manager requestImageForResource:resource completion:^(UIImage *image, NSDictionary *info) {
        XCTAssertNotNil(image);
        isCompletionHandlerCalled = YES;
        [expectation2 fulfill];
    }];
    XCTAssertFalse(isCompletionHandlerCalled);
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

@end
