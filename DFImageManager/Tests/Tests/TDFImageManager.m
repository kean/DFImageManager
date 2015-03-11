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

- (void)testThatImageRequestIsFulfilled {
    XCTestExpectation *expectation = [self expectationWithDescription:@"first_request"];
    [_manager requestImageForResource:[TDFMockResource resourceWithID:@"ID01"] completion:^(UIImage *image, NSDictionary *info) {
        XCTAssertNotNil(image);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

- (void)testThatCanHandleRequestIsForwardedToFetcher {
    DFImageRequest *request = [[DFImageRequest alloc] initWithResource:[TDFMockResource resourceWithID:@"ID01"]];
    XCTAssertTrue([_fetcher canHandleRequest:request]);
    XCTAssertTrue([_manager canHandleRequest:request]);
}

#pragma mark - Response Info

- (void)testThatResponseInfoContainsRequestID {
    XCTestExpectation *expectation = [self expectationWithDescription:@"request"];
    DFImageRequestID *__block requestID = [_manager requestImageForResource:[TDFMockResource resourceWithID:@"ID01"] completion:^(UIImage *image, NSDictionary *info) {
        XCTAssertEqualObjects(info[DFImageInfoRequestIDKey], requestID);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

/*! Test that image manager response info contains error under DFImageInfoErrorKey key when request fails.
 */
- (void)testThatResponseInfoContainsError {
    _fetcher.response = [DFImageResponse responseWithError:[NSError errorWithDomain:@"TDFErrorDomain" code:14 userInfo:nil]];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"request"];
    [_manager requestImageForResource:[TDFMockResource resourceWithID:@"ID01"] completion:^(UIImage *image, NSDictionary *info) {
        NSError *error = info[DFImageInfoErrorKey];
        XCTAssertTrue([error.domain isEqualToString:@"TDFErrorDomain"]);
        XCTAssertTrue(error.code == 14);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

- (void)testThatResponseInfoContainsCustomUserInfo {
    _fetcher.response = [[DFImageResponse alloc] initWithImage:nil error:nil userInfo:@{ @"TestKey" : @"TestValue" }];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"request"];
    [_manager requestImageForResource:[TDFMockResource resourceWithID:@"ID01"] completion:^(UIImage *image, NSDictionary *info) {
        XCTAssertTrue([info[@"TestKey"] isEqualToString:@"TestValue"]);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

#pragma mark - Cancellation

- (void)testThatCancelsFetchOperationUsingRequestID {
    _fetcher.queue.suspended = YES;
    DFImageRequestID *requestID = [_manager requestImageForResource:[TDFMockResource resourceWithID:@"ID01"] completion:nil];
    [self expectationForNotification:TDFMockFetchOperationWillCancelNotification object:nil handler:nil];
    [requestID cancel];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

- (void)testThatCancelsFetchOperationUsingManager {
    _fetcher.queue.suspended = YES;
    DFImageRequestID *requestID = [_manager requestImageForResource:[TDFMockResource resourceWithID:@"ID01"] completion:nil];
    [self expectationForNotification:TDFMockFetchOperationWillCancelNotification object:nil handler:nil];
    [_manager cancelRequestWithID:requestID];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

/*! > Image manager cancels managed operations only when there are no remaining handlers.
 */
- (void)testThatDoesntCancelFetchOperationWithRemainingHandlers {
    _fetcher.queue.suspended = YES;
    
    TDFMockResource *resource = [TDFMockResource resourceWithID:@"ID01"];
    DFImageRequestID *requestID1 = [_manager requestImageForResource:resource completion:nil];
    
    XCTestExpectation *expectThatOperationIsCancelled = [self expectationForNotification:TDFMockFetchOperationWillCancelNotification object:nil handler:nil];
    
    XCTestExpectation *expectSecondRequestToSucceed = [self expectationWithDescription:@"seconds_request"];
    [_manager requestImageForResource:resource completion:^(UIImage *image, NSDictionary *info) {
        XCTAssertNotNil(image);
        [expectSecondRequestToSucceed fulfill];
        // Raises exception if fullfilled twice.
        [expectThatOperationIsCancelled fulfill];
    }];
    
    [requestID1 cancel];
    
    _fetcher.queue.suspended = NO;
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

- (void)testThatCancelsFetchOperationWithTwoHandlers {
    _fetcher.queue.suspended = YES;
    
    [self expectationForNotification:TDFMockFetchOperationWillCancelNotification object:nil handler:nil];
    
    TDFMockResource *resource = [TDFMockResource resourceWithID:@"ID01"];
    DFImageRequestID *requestID1 = [_manager requestImageForResource:resource completion:nil];
    DFImageRequestID *requestID2 = [_manager requestImageForResource:resource completion:nil];
    
    [requestID1 cancel];
    [requestID2 cancel];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

#pragma mark - Operation Reuse

- (void)testThatOperationsAreReused {
    // Start two requests. Image manager is initialized without a memory cache, so it will have to use fetcher and processor for both requests.
    
    _fetcher.queue.suspended = YES;
    _processor.processingTime = 0.05; // Add some processing time so that the processing request doesn't cancel too early
    
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
        XCTAssertEqual(_processor.numberOfProcessedImageCalls, 4);
    }];
}

#pragma mark - Memory Cache

/*! Test that image manager calls completion block synchronously (default configuration).
 @see DFImageManager class reference
 */
- (void)testThatCompletionBlockIsCalledSynchronouslyForMemCachedImages {
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
 @see DFImageManager class reference
 */
- (void)testThatSynchronousCallbacksCanBeDisabled {
    DFImageManagerConfiguration *configuration = [_manager.configuration copy];
    configuration.allowsSynchronousMemoryCacheLookup = NO;
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

/*! Test that callbacks are called on the main thread when the image is in memory cache and the request was made from background thread.
 @see DFImageManager class reference
 */
- (void)testThatCallbacksAreCalledOnTheMainThread {
    _cache.enabled = YES;
    
    TDFMockResource *resource = [TDFMockResource resourceWithID:@"ID01"];
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"request1"];
    [_manager requestImageForResource:resource completion:^(UIImage *image, NSDictionary *info) {
        [expectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    XCTAssertTrue(_cache.images.count == 1);
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"request2"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_manager requestImageForResource:resource completion:^(UIImage *image, NSDictionary *info) {
            XCTAssertNotNil(image);
            XCTAssertTrue([NSThread isMainThread]);
            [expectation2 fulfill];
        }];
    });
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

/*! Test first memory caching rule:
 
 > First, image manager can't use cached images stored by other managers if they share the same cache instance (which makes all the sense).
 */
- (void)testThatCacheEntriesCantBeSharedBetweenManagers {
    _cache.enabled = YES;
    DFImageManagerConfiguration *conf = _manager.configuration;
    
    DFImageManager *manager1 = [[DFImageManager alloc] initWithConfiguration:conf];
    DFImageManager *manager2 = [[DFImageManager alloc] initWithConfiguration:conf];
    
    // 1. Store image in cache
    TDFMockResource *resource = [TDFMockResource resourceWithID:@"ID01"];
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"request"];
    [manager1 requestImageForResource:resource completion:^(UIImage *image, NSDictionary *info) {
        XCTAssertNotNil(image);
        [expectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    XCTAssertTrue(_cache.images.count == 1);
    
    // 2. Test that first manager uses cached image
    UIImage *__block cachedImage = nil;
    [self expectationForNotification:TDFMockImageCacheWillReturnCachedImageNotification object:_cache handler:^BOOL(NSNotification *notification) {
        cachedImage = notification.userInfo[TDFMockImageCacheImageKey];
        return YES;
    }];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"lookup_first_manager"];
    [manager1 requestImageForResource:resource completion:^(UIImage *image, NSDictionary *info) {
        XCTAssertTrue(image == cachedImage);
        [expectation2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];

    // 3. Test that second manager can't access cached image
    XCTAssertTrue(manager2.configuration.cache == manager1.configuration.cache);
    XCTestExpectation *expectationThatSecondManagerTriggeredCache = [self expectationForNotification:TDFMockImageCacheWillReturnCachedImageNotification object:_cache handler:nil];
    XCTestExpectation *expectationThatSecondManagerHandledRequest = [self expectationWithDescription:@"request_on_second_manager"];
    [manager2 requestImageForResource:resource completion:^(UIImage *image, NSDictionary *info) {
        // Raises exception if fullfilled twice.
        [expectationThatSecondManagerTriggeredCache fulfill];
        XCTAssertNotNil(image);
        [expectationThatSecondManagerHandledRequest fulfill];
    }];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

#pragma mark - Preheating

/*! Test documented feature:
 
 > There is also certain (very small) delay when manager runs out of non-preheating requests and starts executing preheating requests. Given that fact, clients don't need to worry about the order in which they start their requests (preheating or not), which comes really handy when you, for example, reload collection view's data and start preheating and requesting multiple images at the same time.
 */
- (void)testThatPreheatingRequestsHasLowerExecutionPrirorty {
    TDFMockResource *resource1 = [TDFMockResource resourceWithID:@"ID01"];
    DFImageRequest *request1 = [[DFImageRequest alloc] initWithResource:resource1];
    
    TDFMockResource *resource2 = [TDFMockResource resourceWithID:@"ID02"];
    
    BOOL __block isRequestForResource2Started = NO;
    [self expectationForNotification:TDFMockImageFetcherDidStartOperationNotification object:_fetcher handler:^BOOL(NSNotification *notification) {
        DFImageRequest *request = notification.userInfo[TDFMockImageFetcherRequestKey];
        if ([request.resource isEqual:resource2]) {
            isRequestForResource2Started = YES;
            return NO;
        } else {
            XCTAssertTrue(isRequestForResource2Started);
            return YES;
        }
    }];
    
    [_manager startPreheatingImagesForRequests:@[ request1 ]];
    
    // Start request after the preheating request, but it always must execute first
    [_manager requestImageForResource:resource2 completion:nil];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

- (void)testThatPreheatingRequestsAreStopped {
    _fetcher.queue.suspended = YES;
    
    DFImageRequest *request = [DFImageRequest requestWithResource:[TDFMockResource resourceWithID:@"ID01"]];
    
    [self expectationForNotification:TDFMockImageFetcherDidStartOperationNotification object:nil handler:nil];
    [_manager startPreheatingImagesForRequests:@[ request ]];
    // DFImageManager doesn't start preheating operations after a certain delay
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    
    [self expectationForNotification:TDFMockFetchOperationWillCancelNotification object:nil handler:nil];
    [_manager stopPreheatingImagesForRequests:@[ request ]];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

- (void)testThatSimilarPreheatingRequestsAreStoppedWithSingleStopCall {
    _fetcher.queue.suspended = YES;
    
    DFImageRequest *request = [DFImageRequest requestWithResource:[TDFMockResource resourceWithID:@"ID01"]];
    
    [self expectationForNotification:TDFMockImageFetcherDidStartOperationNotification object:_fetcher handler:nil];
    [_manager startPreheatingImagesForRequests:@[ request, request ]];
    [_manager startPreheatingImagesForRequests:@[ request ]];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    
    [self expectationForNotification:TDFMockFetchOperationWillCancelNotification object:nil handler:nil];
    [_manager stopPreheatingImagesForRequests:@[ request ]];
    [self waitForExpectationsWithTimeout:3.0 handler:^(NSError *error) {
        XCTAssertEqual(_fetcher.queue.operationCount, 1);
    }];
}

- (void)testThatAllPreheatingRequestsAreStopped {
    _fetcher.queue.suspended = YES;
    
    NSMutableArray *operations = [NSMutableArray new];
    [self expectationForNotification:TDFMockImageFetcherDidStartOperationNotification object:_fetcher handler:^BOOL(NSNotification *notification) {
        TDFMockFetchOperation *operation = notification.userInfo[TDFMockImageFetcherOperationKey];
        [operations addObject:operation];
        return operations.count == 2;
    }];
    [_manager startPreheatingImagesForRequests:@[ [DFImageRequest requestWithResource:[TDFMockResource resourceWithID:@"ID01"]], [DFImageRequest requestWithResource:[TDFMockResource resourceWithID:@"ID02"]] ]];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    
    for (TDFMockFetchOperation *operation in operations) {
        [self expectationForNotification:TDFMockFetchOperationWillCancelNotification object:operation handler:nil];
    }
    [_manager stopPreheatingImagesForAllRequests];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

@end
