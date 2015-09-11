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
    [[_manager imageTaskForResource:[TDFMockResource resourceWithID:@"ID01"] completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull completedTask) {
        XCTAssertNotNil(image);
        [expectation fulfill];
    }] resume];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testThatCanHandleRequestIsForwardedToFetcher {
    DFImageRequest *request = [DFImageRequest requestWithResource:[TDFMockResource resourceWithID:@"ID01"]];
    XCTAssertTrue([_fetcher canHandleRequest:request]);
    XCTAssertTrue([_manager canHandleRequest:request]);
    XCTAssertFalse([_fetcher canHandleRequest:[DFImageRequest requestWithResource:@"String"]]);
    XCTAssertFalse([_manager canHandleRequest:[DFImageRequest requestWithResource:@"String"]]);
}

- (void)testThatCompletedImageTaskHasCompletedState {
    XCTestExpectation *expectation = [self expectationWithDescription:@"request"];
    DFImageTask *__block task = [_manager imageTaskForResource:[TDFMockResource resourceWithID:@"ID01"] completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull completedTask) {
        XCTAssertTrue(task.state == DFImageTaskStateCompleted);
        [expectation fulfill];
    }];
    [task resume];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

#pragma mark - Completion Block

- (void)testThatCompletionBlockContainsImageTask {
    XCTestExpectation *expectation = [self expectationWithDescription:@"request"];
    DFImageTask *__block task = [_manager imageTaskForResource:[TDFMockResource resourceWithID:@"ID01"] completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull completedTask) {
        XCTAssertEqualObjects(completedTask, task);
        [expectation fulfill];
    }];
    [task resume];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

/*! Test that image manager response info contains error under DFImageInfoErrorKey key when request fails.
 */
- (void)testThatCompletionBlockContainsError {
    _fetcher.error = [NSError errorWithDomain:@"TDFErrorDomain" code:14 userInfo:nil];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"request"];
    [[_manager imageTaskForResource:[TDFMockResource resourceWithID:@"ID01"] completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull completedTask) {
        XCTAssertNotNil(error);
        XCTAssertTrue([error.domain isEqualToString:@"TDFErrorDomain"]);
        XCTAssertTrue(error.code == 14);
        [expectation fulfill];
    }] resume];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

/*! Test that image manager response info contains error under DFImageInfoErrorKey key when request fails.
 */
- (void)testThatCompletionBlockAndImageTaskContainError {
    _fetcher.error = [NSError errorWithDomain:@"TDFErrorDomain" code:14 userInfo:nil];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"request"];
    DFImageTask *task = [_manager imageTaskForResource:[TDFMockResource resourceWithID:@"ID01"] completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull completedTask) {
        XCTAssertNotNil(error);
        XCTAssertTrue([error.domain isEqualToString:@"TDFErrorDomain"]);
        XCTAssertTrue(error.code == 14);
        [expectation fulfill];
    }];
    [task resume];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    
    XCTAssertNotNil(task.error);
    XCTAssertTrue([task.error.domain isEqualToString:@"TDFErrorDomain"]);
    XCTAssertTrue(task.error.code == 14);
}

- (void)testThatFailedResponseAlwaysGeneratesError {
    _fetcher.data = nil;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"request"];
    DFImageTask *task = [_manager imageTaskForResource:[TDFMockResource resourceWithID:@"ID01"] completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull completedTask) {
        XCTAssertNotNil(error);
        XCTAssertTrue([error.domain isEqualToString:DFImageManagerErrorDomain]);
        XCTAssertTrue(error.code == DFImageManagerErrorUnknown);
        [expectation fulfill];
    }];
    [task resume];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    
    XCTAssertNotNil(task.error);
    XCTAssertTrue([task.error.domain isEqualToString:DFImageManagerErrorDomain]);
    XCTAssertTrue(task.error.code == DFImageManagerErrorUnknown);
}

- (void)testThatCompletionBlockContainsCustomUserInfo {
    _fetcher.data = nil;
    _fetcher.info = @{ @"TestKey" : @"TestValue" };
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"request"];
    [[_manager imageTaskForResource:[TDFMockResource resourceWithID:@"ID01"] completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull completedTask) {
        XCTAssertTrue([response.info[@"TestKey"] isEqualToString:@"TestValue"]);
        [expectation fulfill];
    }] resume];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

#pragma mark - Image Task

- (void)testThatImageTaskStateChangedOnCallersThread {
    DFImageTask *task = [_manager imageTaskForResource:[TDFMockResource resourceWithID:@"ID01"] completion:nil];
    XCTAssertEqual(task.state, DFImageTaskStateSuspended);
    [task resume];
    XCTAssertEqual(task.state, DFImageTaskStateRunning);
    [task cancel];
    XCTAssertEqual(task.state, DFImageTaskStateCancelled);
}

- (void)testThatImageTaskStateChangedOnCallersBackgroundThread {
    XCTestExpectation *expectation = [self expectationWithDescription:@"1"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        DFImageTask *task = [_manager imageTaskForResource:[TDFMockResource resourceWithID:@"ID01"] completion:nil];
        XCTAssertEqual(task.state, DFImageTaskStateSuspended);
        [task resume];
        XCTAssertEqual(task.state, DFImageTaskStateRunning);
        [task cancel];
        XCTAssertEqual(task.state, DFImageTaskStateCancelled);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

#pragma mark - Cancellation

- (void)testThatFetchOperationIsCancelledWhenTaskIs {
    _fetcher.queue.suspended = YES;
    DFImageTask *task = [_manager imageTaskForResource:[TDFMockResource resourceWithID:@"ID01"] completion:nil];
    [task resume];
    [self expectationForNotification:TDFMockFetchOperationWillCancelNotification object:nil handler:nil];
    [task cancel];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

/*! > Image manager cancels fetch operations only when there are no remaining image tasks registered with a given operation.
 */
- (void)testThatDoesntCancelFetchOperationWithRemainingHandlers {
    _fetcher.queue.suspended = YES;
    
    TDFMockResource *resource = [TDFMockResource resourceWithID:@"ID01"];
    DFImageTask *task = [_manager imageTaskForResource:resource completion:nil];
    [task resume];
    
    XCTestExpectation *expectThatOperationIsCancelled = [self expectationForNotification:TDFMockFetchOperationWillCancelNotification object:nil handler:nil];
    
    XCTestExpectation *expectSecondRequestToSucceed = [self expectationWithDescription:@"seconds_request"];
    [[_manager imageTaskForResource:resource completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull completedTask) {
        XCTAssertNotNil(image);
        [expectSecondRequestToSucceed fulfill];
        // Raises exception if fullfilled twice.
        [expectThatOperationIsCancelled fulfill];
    }] resume];
    
    [task cancel];
    
    _fetcher.queue.suspended = NO;
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testThatCancelsFetchOperationWithTwoHandlers {
    _fetcher.queue.suspended = YES;
    
    [self expectationForNotification:TDFMockFetchOperationWillCancelNotification object:nil handler:nil];
    
    TDFMockResource *resource = [TDFMockResource resourceWithID:@"ID01"];
    DFImageTask *task1 = [_manager imageTaskForResource:resource completion:nil];
    [task1 resume];
    DFImageTask *task2 = [_manager imageTaskForResource:resource completion:nil];
    [task2 resume];
    
    [task1 cancel];
    [task2 cancel];
    
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testThatCompletionHandlerForCancelledRequestIsCalledWithValidError {
    _fetcher.queue.suspended = YES;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    DFImageTask *task = [_manager imageTaskForResource:[TDFMockResource resourceWithID:@"ID01"] completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull completedTask) {
        XCTAssertNotNil(error);
        XCTAssertTrue([error.domain isEqualToString:DFImageManagerErrorDomain]);
        XCTAssertEqual(error.code, DFImageManagerErrorCancelled);
        [expectation fulfill];
    }];
    [task resume];
    [task cancel];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testThatCancelledImageTaskHasCancelledState {
    XCTestExpectation *expectation = [self expectationWithDescription:@"request"];
    DFImageTask *__block task = [_manager imageTaskForResource:[TDFMockResource resourceWithID:@"ID01"] completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull completedTask) {
        XCTAssertTrue(task.state == DFImageTaskStateCancelled);
        [expectation fulfill];
    }];
    [task resume];
    [task cancel];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

#pragma mark - Operation Reuse

- (void)testThatOperationsAreReused {
    // Start two requests. Image manager is initialized without a memory cache, so it will have to use fetcher and processor for both requests.
    
    _fetcher.queue.suspended = YES;
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"01"]; { DFImageRequest *request1 = [[DFImageRequest alloc] initWithResource:[TDFMockResource resourceWithID:@"ID01"] targetSize:CGSizeMake(150.f, 150.f) contentMode:DFImageContentModeAspectFill options:nil];
        [[_manager imageTaskForRequest:request1 completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull completedTask) {
            XCTAssertNotNil(image);
            [expectation1 fulfill];
        }] resume];
    }
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"02"]; {
        DFImageRequest *request2 = [[DFImageRequest alloc] initWithResource:[TDFMockResource resourceWithID:@"ID01"] targetSize:CGSizeMake(100.f, 100.f) contentMode:DFImageContentModeAspectFill options:nil];
        [[_manager imageTaskForRequest:request2 completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull completedTask) {
            XCTAssertNotNil(image);
            [expectation2 fulfill];
        }] resume];
    }
    
    XCTestExpectation *expectation3 = [self expectationWithDescription:@"04"]; {
        DFImageRequest *request3 = [[DFImageRequest alloc] initWithResource:[TDFMockResource resourceWithID:@"ID02"] targetSize:CGSizeMake(100.f, 100.f) contentMode:DFImageContentModeAspectFill options:nil];
        [[_manager imageTaskForRequest:request3 completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull completedTask) {
            XCTAssertNotNil(image);
            [expectation3 fulfill];
        }] resume];
    }
    
    _fetcher.queue.suspended = NO;
    
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError *error) {
        XCTAssertEqual(_fetcher.createdOperationCount, 2);
    }];
}

#pragma mark - Progress

- (void)testThatProgressObjectIsUpdated {
    DFImageRequest *request = [DFImageRequest requestWithResource:[TDFMockResource resourceWithID:@"1"]];
    DFImageTask *task = [_manager imageTaskForRequest:request completion:nil];
    
    NSProgress *progress = task.progress;
    XCTAssertNotNil(progress);
    XCTAssertTrue(progress.isIndeterminate);
    
    double __block fractionCompleted = 0;
    [self keyValueObservingExpectationForObject:progress keyPath:@"fractionCompleted" handler:^BOOL(NSProgress *observedObject, NSDictionary *change) {
        if (TDFSystemVersionGreaterThanOrEqualTo(@"8.0")) {
            fractionCompleted += 0.5;
            XCTAssertEqual(fractionCompleted, observedObject.fractionCompleted);
        } else {
            XCTAssertEqual(fractionCompleted, observedObject.fractionCompleted);
            fractionCompleted += 0.5;
        }
        return observedObject.fractionCompleted == 1;
    }];
    
    [task resume];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testThatProgressObjectCancelsTask {
    _fetcher.queue.suspended = YES;
    
    DFImageTask *task = [_manager imageTaskForResource:[TDFMockResource resourceWithID:@"ID01"] completion:nil];
    [task resume];
    [self expectationForNotification:TDFMockFetchOperationWillCancelNotification object:nil handler:nil];
    
    NSProgress *progress = task.progress;
    XCTAssertNotNil(progress);
    XCTAssertTrue(progress.isCancellable);
    [progress cancel];
    
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testThatImplicitProgressCompositionWorks {
    DFImageRequest *request = [DFImageRequest requestWithResource:[TDFMockResource resourceWithID:@"1"]];
    
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:100];
    [progress becomeCurrentWithPendingUnitCount:100];
    DFImageTask *task = [_manager imageTaskForRequest:request completion:nil];
    [task progress];
    [progress resignCurrent];
    
    BOOL __block _isHalfCompleted;
    [self keyValueObservingExpectationForObject:progress keyPath:@"fractionCompleted" handler:^BOOL(NSProgress *observedObject, NSDictionary *change) {
        if (!_isHalfCompleted) {
            XCTAssertEqual(observedObject.fractionCompleted, 0.5);
            _isHalfCompleted = YES;
        } else {
            XCTAssertEqual(observedObject.fractionCompleted, 1);
            return YES;
        }
        return NO;
    }];
    
    [task resume];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testThatImplicitProgressCompositionConstructsProgressTree {
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:100];
    
    [progress becomeCurrentWithPendingUnitCount:50];
    DFImageTask *task1 = [_manager imageTaskForRequest:[DFImageRequest requestWithResource:[TDFMockResource resourceWithID:@"1"]] completion:nil];
    [task1 progress];
    [progress resignCurrent];
    
    [progress becomeCurrentWithPendingUnitCount:50];
    DFImageTask *task2 = [_manager imageTaskForRequest:[DFImageRequest requestWithResource:[TDFMockResource resourceWithID:@"2"]] completion:nil];
    [task2 progress];
    [progress resignCurrent];
    
    double __block fractionCompleted = 0;
    [self keyValueObservingExpectationForObject:progress keyPath:@"fractionCompleted" handler:^BOOL(NSProgress *observedObject, NSDictionary *change) {
        fractionCompleted += 0.25;
        XCTAssertEqual(fractionCompleted, observedObject.fractionCompleted);
        return observedObject.fractionCompleted == 1;
    }];
    
    [task1 resume];
    [task2 resume];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

#pragma mark - Memory Cache

/*! Test that image manager calls completion block synchronously (default configuration).
 @see DFImageManager class reference
 */
- (void)testThatCompletionBlockIsCalledSynchronouslyForMemCachedImages {
    _cache.enabled = YES;
    
    TDFMockResource *resource = [TDFMockResource resourceWithID:@"ID01"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"request"];
    [[_manager imageTaskForResource:resource completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull completedTask) {
        XCTAssertNotNil(image);
        [expectation fulfill];
    }] resume];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    XCTAssertEqual(_cache.responses.count, 1);
    
    BOOL __block isCompletionHandlerCalled = NO;
    [[_manager imageTaskForResource:resource completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull completedTask) {
        XCTAssertNotNil(image);
        XCTAssertTrue([NSThread isMainThread]);
        isCompletionHandlerCalled = YES;
    }] resume];
    XCTAssertTrue(isCompletionHandlerCalled);
}

- (void)testThatMemoryCachingIsTransparentToTheClient {
    UIImage *initialImage = [TDFTesting testImage];
    NSDictionary *initialInfo = @{ @"TDFKey" : @"TDFValue" };
    _fetcher.data = [TDFTesting testImageData];
    _fetcher.info = initialInfo;
    
    _cache.enabled = YES;
    
    // 1. Fetch image and store it into memory cache
    TDFMockResource *resource = [TDFMockResource resourceWithID:@"ID01"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"request"];
    {
        DFImageTask *task = [_manager imageTaskForResource:resource completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull completedTask) {
            XCTAssertTrue(CGSizeEqualToSize(initialImage.size, image.size));
            XCTAssertEqual(initialInfo[@"TDFKey"], response.info[@"TDFKey"]);
            XCTAssertFalse(response.isFastResponse);
            XCTAssertTrue(completedTask.state == DFImageTaskStateCompleted);
            [expectation fulfill];
        }];
        XCTAssertNotNil(task);
        [task resume];
        [self waitForExpectationsWithTimeout:1.0 handler:nil];
    }
    XCTAssertEqual(_cache.responses.count, 1);
    
    // 2. Fetch image from the memory cache
    {
        BOOL __block isCompletionHandlerCalled = NO;
        DFImageTask *task = [_manager imageTaskForResource:resource completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull completedTask) {
            XCTAssertTrue(CGSizeEqualToSize(initialImage.size, image.size));
            XCTAssertEqual(initialInfo[@"TDFKey"], response.info[@"TDFKey"]);
            XCTAssertTrue(response.isFastResponse);
            XCTAssertTrue(completedTask.state == DFImageTaskStateCompleted);
            isCompletionHandlerCalled = YES;
        }];
        XCTAssertNotNil(task);
        [task resume];
        XCTAssertTrue(isCompletionHandlerCalled);
    }
}

/*! Test that callbacks are called on the main thread when the image is in memory cache and the request was made from background thread.
 @see DFImageManager class reference
 */
- (void)testThatCallbacksAreCalledOnTheMainThread {
    _cache.enabled = YES;
    
    TDFMockResource *resource = [TDFMockResource resourceWithID:@"ID01"];
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"request1"];
    [[_manager imageTaskForResource:resource completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull completedTask) {
        XCTAssertNotNil(image);
        [expectation1 fulfill];
    }] resume];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    XCTAssertTrue(_cache.responses.count == 1);
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"request2"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[_manager imageTaskForResource:resource completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull completedTask) {
            XCTAssertNotNil(image);
            XCTAssertTrue([NSThread isMainThread]);
            [expectation2 fulfill];
        }] resume];
    });
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
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
    [[manager1 imageTaskForResource:resource completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull completedTask) {
        XCTAssertNotNil(image);
        [expectation1 fulfill];
    }] resume];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    XCTAssertTrue(_cache.responses.count == 1);
    
    // 2. Test that first manager uses cached image
    UIImage *__block cachedImage = nil;
    [self expectationForNotification:TDFMockImageCacheWillReturnCachedImageNotification object:_cache handler:^BOOL(NSNotification *notification) {
        cachedImage = notification.userInfo[TDFMockImageCacheImageKey];
        return YES;
    }];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"lookup_first_manager"];
    [[manager1 imageTaskForResource:resource completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull completedTask) {
        XCTAssertEqual(image, cachedImage);
        [expectation2 fulfill];
    }] resume];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    
    // 3. Test that second manager can't access cached image
    XCTAssertTrue(manager2.configuration.cache == manager1.configuration.cache);
    XCTestExpectation *expectationThatSecondManagerTriggeredCache = [self expectationForNotification:TDFMockImageCacheWillReturnCachedImageNotification object:_cache handler:nil];
    XCTestExpectation *expectationThatSecondManagerHandledRequest = [self expectationWithDescription:@"request_on_second_manager"];
    [[manager2 imageTaskForResource:resource completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull completedTask) {
        // Raises exception if fullfilled twice.
        [expectationThatSecondManagerTriggeredCache fulfill];
        XCTAssertNotNil(image);
        [expectationThatSecondManagerHandledRequest fulfill];
    }] resume];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

#pragma mark - Processing

- (void)testThatImageIsProcessed {
    XCTestExpectation *expectation = [self expectationWithDescription:@"first_request"];
    [[_manager imageTaskForResource:[TDFMockResource resourceWithID:@"ID01"] completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull completedTask) {
        XCTAssertNotNil(image);
        XCTAssertTrue([image tdf_isImageProcessed]);
        [expectation fulfill];
    }] resume];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

#pragma mark - Priority

- (void)testThatPriorityIsChanged {
    _fetcher.queue.suspended = YES;
    
    DFMutableImageRequestOptions *options = [DFMutableImageRequestOptions new];
    options.priority = DFImageRequestPriorityHigh;
    DFImageRequest *request = [DFImageRequest requestWithResource:[TDFMockResource resourceWithID:@"ID"] targetSize:DFImageMaximumSize contentMode:DFImageContentModeAspectFill options:options.options];
    
    NSOperation *__block operation;
    [self expectationForNotification:TDFMockImageFetcherDidStartOperationNotification object:_fetcher handler:^BOOL(NSNotification *notification) {
        operation = notification.userInfo[TDFMockImageFetcherOperationKey];
        XCTAssert([operation isKindOfClass:[NSOperation class]]);
        XCTAssertNotNil(operation);
        return YES;
    }];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    DFImageTask *task = [_manager imageTaskForRequest:request completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull completedTask) {
        XCTAssertEqual(operation.queuePriority, NSOperationQueuePriorityLow);
        [expectation fulfill];
    }];
    XCTAssertEqual(task.priority, options.priority);
    [task resume];
    [NSThread sleepForTimeInterval:0.05]; // Wait till operation is created
    [task setPriority:DFImageRequestPriorityLow];
    XCTAssertEqual(task.priority, DFImageRequestPriorityLow);
    _fetcher.queue.suspended = NO;
    
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

#pragma mark - Preheating

- (void)testThatPreheatingRequestsHasLowerExecutionPrirorty {
    TDFMockResource *resource1 = [TDFMockResource resourceWithID:@"ID01"];
    DFImageRequest *request1 = [DFImageRequest requestWithResource:resource1];
    TDFMockResource *resource2 = [TDFMockResource resourceWithID:@"ID02"];
    
    BOOL __block isRequestForResource2Started = NO;
    [self expectationForNotification:TDFMockImageFetcherDidStartOperationNotification object:_fetcher handler:^BOOL(NSNotification *notification) {
        DFImageRequest *request = notification.userInfo[TDFMockImageFetcherRequestKey];
        XCTAssertNotNil(request);
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
    [[_manager imageTaskForResource:resource2 completion:nil] resume];
    
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testThatPreheatingRequestsAreStopped {
    _fetcher.queue.suspended = YES;
    
    DFImageRequest *request = [DFImageRequest requestWithResource:[TDFMockResource resourceWithID:@"ID01"]];
    
    [self expectationForNotification:TDFMockImageFetcherDidStartOperationNotification object:nil handler:nil];
    [_manager startPreheatingImagesForRequests:@[ request ]];
    // DFImageManager doesn't start preheating operations after a certain delay
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    
    [self expectationForNotification:TDFMockFetchOperationWillCancelNotification object:nil handler:nil];
    [_manager stopPreheatingImagesForRequests:@[ request ]];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testThatSimilarPreheatingRequestsAreStoppedWithSingleStopCall {
    _fetcher.queue.suspended = YES;
    
    DFImageRequest *request = [DFImageRequest requestWithResource:[TDFMockResource resourceWithID:@"ID01"]];
    
    [self expectationForNotification:TDFMockImageFetcherDidStartOperationNotification object:_fetcher handler:nil];
    [_manager startPreheatingImagesForRequests:@[ request, request ]];
    [_manager startPreheatingImagesForRequests:@[ request ]];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    
    [self expectationForNotification:TDFMockFetchOperationWillCancelNotification object:nil handler:nil];
    [_manager stopPreheatingImagesForRequests:@[ request ]];
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError *error) {
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
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    
    for (TDFMockFetchOperation *operation in operations) {
        [self expectationForNotification:TDFMockFetchOperationWillCancelNotification object:operation handler:nil];
    }
    [_manager stopPreheatingImagesForAllRequests];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testThatPreheatingRequestsAreExecutedInTheOrderTheyWereAdded {
    DFImageRequest *request1 = [DFImageRequest requestWithResource:[TDFMockResource resourceWithID:@"1"]];
    DFImageRequest *request2 = [DFImageRequest requestWithResource:[TDFMockResource resourceWithID:@"2"]];
    
    BOOL __block isRequest1Started = NO;
    BOOL __block isRequest2Started = NO;
    [self expectationForNotification:TDFMockImageFetcherDidStartOperationNotification object:nil handler:^BOOL(NSNotification *notification) {
        DFImageRequest *request = notification.userInfo[TDFMockImageFetcherRequestKey];
        XCTAssertNotNil(request);
        if ([request.resource isEqual:request1.resource]) {
            XCTAssertFalse(isRequest2Started);
            isRequest1Started = YES;
        } else if ([request.resource isEqual:request2.resource]) {
            XCTAssertTrue(isRequest1Started);
            isRequest2Started = YES;
        }
        return isRequest1Started && isRequest2Started;
    }];
    
    [_manager startPreheatingImagesForRequests:@[ request1, request2 ]];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testThatPreheatingRequestsAreExecutedInTheOrderTheyWereAddedSwitched {
    // Switch resources from the previous test.
    DFImageRequest *request1 = [DFImageRequest requestWithResource:[TDFMockResource resourceWithID:@"2"]];
    DFImageRequest *request2 = [DFImageRequest requestWithResource:[TDFMockResource resourceWithID:@"1"]];
    
    BOOL __block isRequest1Started = NO;
    BOOL __block isRequest2Started = NO;
    [self expectationForNotification:TDFMockImageFetcherDidStartOperationNotification object:nil handler:^BOOL(NSNotification *notification) {
        DFImageRequest *request = notification.userInfo[TDFMockImageFetcherRequestKey];
        XCTAssertNotNil(request);
        if ([request.resource isEqual:request1.resource]) {
            XCTAssertFalse(isRequest2Started);
            isRequest1Started = YES;
        } else if ([request.resource isEqual:request2.resource]) {
            XCTAssertTrue(isRequest1Started);
            isRequest2Started = YES;
        }
        return isRequest1Started && isRequest2Started;
    }];
    
    [_manager startPreheatingImagesForRequests:@[ request1, request2 ]];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

#pragma mark - Invalidation

- (void)testThatRequestsFinishWithoutAStrongReferenceToManager {
    DFImageManager *manager = [[DFImageManager alloc] initWithConfiguration:[DFImageManagerConfiguration configurationWithFetcher:[TDFMockImageFetcher new] processor:nil cache:nil]];
    @autoreleasepool {
        XCTestExpectation *expectation = [self expectationWithDescription:@"first_request"];
        [[manager imageTaskForResource:[TDFMockResource resourceWithID:@"ID01"] completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull completedTask) {
            XCTAssertNotNil(image);
            [expectation fulfill];
        }] resume];
        manager = nil;
    }
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testThatInvalidateAndCancelMethodCancelsOutstandingRequests {
    _fetcher.queue.suspended = YES;
    // More than 1 image task!
    [[_manager imageTaskForResource:[TDFMockResource resourceWithID:@"ID01"] completion:nil] resume];
    [[_manager imageTaskForResource:[TDFMockResource resourceWithID:@"ID02"] completion:nil] resume];
    NSInteger __block callbackCount = 0;
    [self expectationForNotification:TDFMockFetchOperationWillCancelNotification object:nil handler:^BOOL(NSNotification *notification) {
        callbackCount++;
        return callbackCount == 2;
    }];;
    [_manager invalidateAndCancel];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testThatInvalidatedManagerDoesntResumeTasks {
    DFImageTask *task = [_manager imageTaskForResource:[TDFMockResource resourceWithID:@"ID01"] completion:nil];
    [_manager invalidateAndCancel];
    [task resume];
    XCTAssertEqual(task.state, DFImageTaskStateSuspended);
    [task cancel];
    XCTAssertEqual(task.state, DFImageTaskStateSuspended);
}

#pragma mark - Fault Tolerance

- (void)testThatImageIsFetchedWhenCompletionHandlerIsNil {
    [self expectationForNotification:TDFMockImageFetcherDidStartOperationNotification object:nil handler:nil];
    [[_manager imageTaskForResource:[TDFMockResource resourceWithID:@"1"] completion:nil] resume];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

#pragma mark - Misc

- (void)testThatGetImageTasksReturnsAllTasks {
    _fetcher.queue.suspended = YES;
    
    DFImageTask *task1 = [_manager imageTaskForResource:[TDFMockResource resourceWithID:@"01"] completion:nil];
    DFImageTask *task2 = [_manager imageTaskForResource:[TDFMockResource resourceWithID:@"02"] completion:nil];
    
    [task2 resume];
    
    [_manager startPreheatingImagesForRequests:@[ [DFImageRequest requestWithResource:[TDFMockResource resourceWithID:@"03"]] ]];
    
    XCTestExpectation *expectTasks = [self expectationWithDescription:@"1"];
    
    [_manager getImageTasksWithCompletion:^(NSArray *tasks, NSArray *preheatingTasks) {
        XCTAssertTrue([NSThread isMainThread]);
        XCTAssertFalse([tasks containsObject:task1]);
        XCTAssertTrue([tasks containsObject:task2]);
        XCTAssertTrue(tasks.count == 1);
        XCTAssertTrue(preheatingTasks.count == 1);
        [expectTasks fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
