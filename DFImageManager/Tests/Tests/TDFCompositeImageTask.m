//
//  TDFCompositeImageTask.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 11/07/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "DFImageManagerKit.h"
#import "TDFTestingKit.h"
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>


@interface TDFCompositeImageTask : XCTestCase

@end

@implementation TDFCompositeImageTask {
    TDFMockFetcher *_fetcher;
    DFImageManager *_manager;
}

- (void)setUp {
    [super setUp];
    
    _fetcher = [TDFMockFetcher new];
    _manager = [[DFImageManager alloc] initWithConfiguration:[DFImageManagerConfiguration configurationWithFetcher:_fetcher]];
    [DFImageManager setSharedManager:_manager];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - Image Handler (Single Request)

- (void)testThatSingleSuccessfullRequestIsHandled {
    UIImage *originalImage = [TDFTesting testImage];
    [_fetcher setResponse:[TDFMockResponse mockWithImage:originalImage] forResource:@"resource"];
    
    XCTestExpectation *expectImageHandler = [self expectationWithDescription:@"1"];
    XCTestExpectation *expectCompletionHandler = [self expectationWithDescription:@"2"];
    
    DFImageRequest *originalRequest = [DFImageRequest requestWithResource:@"resource"];
    BOOL __block isImageHandlerCalled = NO;
    DFCompositeImageTask *task = [DFCompositeImageTask compositeImageTaskWithRequests:@[originalRequest] imageHandler:^(UIImage *image, NSDictionary *info, DFCompositeImageTask *compositeTask) {
        isImageHandlerCalled = YES;
        DFImageTask *completedTask = info[DFImageInfoTaskKey];
        XCTAssertNotNil(completedTask);
        XCTAssertTrue([completedTask.request.resource isEqualToString:originalRequest.resource]);
        XCTAssertEqualObjects(image, originalImage);
        XCTAssertTrue(compositeTask.isFinished);
        [expectImageHandler fulfill];
    } completionHandler:^(DFCompositeImageTask *compositeTask) {
        XCTAssertTrue(isImageHandlerCalled);
        XCTAssertTrue(compositeTask.isFinished);
        [expectCompletionHandler fulfill];
    }];
    XCTAssertFalse(task.isFinished);
    [task resume];
    XCTAssertFalse(task.isFinished);
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

#pragma mark - Image Handler (Two Requests: First Task Finishes First)

/*! 1s, 2s -> 1s, 2s
 */
- (void)testThatHandlerCalledTwiceWhenFirstTaskSucceededThenSecondSucceedes {
    UIImage *image1 = [UIImage new];
    [_fetcher setResponse:[TDFMockResponse mockWithImage:image1 elapsedTime:0] forResource:@"resource1"];
    UIImage *image2 = [TDFTesting testImage];
    [_fetcher setResponse:[TDFMockResponse mockWithImage:image2 elapsedTime:0.05] forResource:@"resource2"];
    
    XCTestExpectation *expectFirstImage = [self expectationWithDescription:@"1"];
    XCTestExpectation *expectSecondImage = [self expectationWithDescription:@"2"];
    XCTestExpectation *expectCompletion = [self expectationWithDescription:@"3"];
    
    DFImageRequest *request1 = [DFImageRequest requestWithResource:@"resource1"];
    DFImageRequest *request2 = [DFImageRequest requestWithResource:@"resource2"];
    
    DFCompositeImageTask *task = [DFCompositeImageTask compositeImageTaskWithRequests:@[ request1, request2 ] imageHandler:^(UIImage *image, NSDictionary *info, DFCompositeImageTask *compositeTask) {
        DFImageTask *completedTask = info[DFImageInfoTaskKey];
        if ([completedTask.request.resource isEqualToString:request1.resource]) {
            XCTAssertEqualObjects(image, image1);
            XCTAssertFalse(compositeTask.isFinished);
            [expectFirstImage fulfill];
        }
        if ([completedTask.request.resource isEqualToString:request2.resource]) {
            XCTAssertEqualObjects(image, image2);
            XCTAssertTrue(compositeTask.isFinished);
            [expectSecondImage fulfill];
        }
    } completionHandler:^(DFCompositeImageTask *compositeTask) {
        XCTAssertTrue(compositeTask.isFinished);
        [expectCompletion fulfill];
    }];
    XCTAssertFalse(task.isFinished);
    [task resume];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

/*! 1s, 2f -> 1s
 */
- (void)testThatHandlerCalledOnceWhenFirstTaskSucceedesThenSecondFails {
    UIImage *image1 = [UIImage new];
    [_fetcher setResponse:[TDFMockResponse mockWithImage:image1 elapsedTime:0] forResource:@"resource1"];
    [_fetcher setResponse:[TDFMockResponse mockWithImage:nil elapsedTime:0.05] forResource:@"resource2"];
    
    XCTestExpectation *expectFirstImage = [self expectationWithDescription:@"1"];
    XCTestExpectation *expectSecondImage = [self expectationWithDescription:@"2"];
    XCTestExpectation *expectCompletion = [self expectationWithDescription:@"3"];
    
    DFImageRequest *request1 = [DFImageRequest requestWithResource:@"resource1"];
    DFImageRequest *request2 = [DFImageRequest requestWithResource:@"resource2"];
    
    DFCompositeImageTask *task = [DFCompositeImageTask compositeImageTaskWithRequests:@[ request1, request2 ] imageHandler:^(UIImage *image, NSDictionary *info, DFCompositeImageTask *compositeTask) {
        DFImageTask *completedTask = info[DFImageInfoTaskKey];
        if ([completedTask.request.resource isEqualToString:request1.resource]) {
            XCTAssertEqualObjects(image, image1);
            [expectFirstImage fulfill];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [expectSecondImage fulfill];
            });
        }
        if ([completedTask.request.resource isEqualToString:request2.resource]) {
            XCTFail(@"Unexpected callback");
        }
    } completionHandler:^(DFCompositeImageTask *compositeTask) {
        XCTAssertTrue(compositeTask.isFinished);
        [expectCompletion fulfill];
    }];
    [task resume];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

/*! 1f, 2s -> 2s
 */
- (void)testThatHandlerCalledOnceWhenFirstTaskFailsThenSecondSucceedes {
    [_fetcher setResponse:[TDFMockResponse mockWithImage:nil elapsedTime:0] forResource:@"resource1"];
    UIImage *image2 = [TDFTesting testImage];
    [_fetcher setResponse:[TDFMockResponse mockWithImage:image2 elapsedTime:0.05] forResource:@"resource2"];
    
    XCTestExpectation *expectFirstImage = [self expectationWithDescription:@"1"];
    XCTestExpectation *expectSecondImage = [self expectationWithDescription:@"2"];
    XCTestExpectation *expectCompletion = [self expectationWithDescription:@"3"];
    
    DFImageRequest *request1 = [DFImageRequest requestWithResource:@"resource1"];
    DFImageRequest *request2 = [DFImageRequest requestWithResource:@"resource2"];
    
    DFCompositeImageTask *task = [DFCompositeImageTask compositeImageTaskWithRequests:@[ request1, request2 ] imageHandler:^(UIImage *image, NSDictionary *info, DFCompositeImageTask *compositeTask) {
        DFImageTask *completedTask = info[DFImageInfoTaskKey];
        if ([completedTask.request.resource isEqualToString:request1.resource]) {
            XCTFail(@"Unexpected callback");
        }
        if ([completedTask.request.resource isEqualToString:request2.resource]) {
            XCTAssertEqualObjects(image, image2);
            XCTAssertTrue(compositeTask.isFinished);
            [expectSecondImage fulfill];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [expectFirstImage fulfill];
            });
        }
    } completionHandler:^(DFCompositeImageTask *compositeTask) {
        XCTAssertTrue(compositeTask.isFinished);
        [expectCompletion fulfill];
    }];
    [task resume];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

/*! 1f, 2f -> [no callback]
 */
- (void)testThatHandlerNotCalledWhenFirstTaskFailsThenSecondFails {
    [_fetcher setResponse:[TDFMockResponse mockWithImage:nil elapsedTime:0] forResource:@"resource1"];
    [_fetcher setResponse:[TDFMockResponse mockWithImage:nil elapsedTime:0.05] forResource:@"resource2"];
    
    XCTestExpectation *expectFirstImage = [self expectationWithDescription:@"1"];
    XCTestExpectation *expectSecondImage = [self expectationWithDescription:@"2"];
    XCTestExpectation *expectCompletion = [self expectationWithDescription:@"3"];
    
    DFImageRequest *request1 = [DFImageRequest requestWithResource:@"resource1"];
    DFImageRequest *request2 = [DFImageRequest requestWithResource:@"resource2"];
    
    DFCompositeImageTask *task = [DFCompositeImageTask compositeImageTaskWithRequests:@[ request1, request2 ] imageHandler:^(UIImage *image, NSDictionary *info, DFCompositeImageTask *compositeTask) {
        XCTFail(@"Unexpected callback");
    } completionHandler:^(DFCompositeImageTask *compositeTask) {
        XCTAssertTrue(compositeTask.isFinished);
        [expectCompletion fulfill];
    }];
    [task resume];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectFirstImage fulfill];
        [expectSecondImage fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

#pragma mark - Image Handler (Two Requests: Second Task Finishes First)

/*! 2s -> 2s [1st cancelled]
 */
- (void)testThatHandlerCalledOnceAndFirstTaskCancelledWhenSecondSuccedes {
    UIImage *image1 = [UIImage new];
    [_fetcher setResponse:[TDFMockResponse mockWithImage:image1 elapsedTime:0.05] forResource:@"resource1"];
    UIImage *image2 = [TDFTesting testImage];
    [_fetcher setResponse:[TDFMockResponse mockWithImage:image2 elapsedTime:0] forResource:@"resource2"];
    
    [self expectationForNotification:TDFMockFetchOperationWillCancelNotification object:nil handler:nil];
    XCTestExpectation *expectSecondImage = [self expectationWithDescription:@"1"];
    XCTestExpectation *expectCompletion = [self expectationWithDescription:@"2"];
    
    DFImageRequest *request1 = [DFImageRequest requestWithResource:@"resource1"];
    DFImageRequest *request2 = [DFImageRequest requestWithResource:@"resource2"];
    
    DFCompositeImageTask *task = [DFCompositeImageTask compositeImageTaskWithRequests:@[ request1, request2 ] imageHandler:^(UIImage *image, NSDictionary *info, DFCompositeImageTask *compositeTask) {
        DFImageTask *completedTask = info[DFImageInfoTaskKey];
        if ([completedTask.request.resource isEqualToString:request1.resource]) {
            XCTFail(@"Callback should get called once");
        }
        if ([completedTask.request.resource isEqualToString:request2.resource]) {
            XCTAssertEqualObjects(image, image2);
            [expectSecondImage fulfill];
        }
    } completionHandler:^(DFCompositeImageTask *compositeTask) {
        XCTAssertTrue(compositeTask.isFinished);
        [expectCompletion fulfill];
    }];
    [task resume];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

/*! 2f, 1s -> 1s
 */
- (void)testThatHandlerCalledOnceWhenSecondTaskFailesThenFirstSucceedes {
    UIImage *image1 = [UIImage new];
    [_fetcher setResponse:[TDFMockResponse mockWithImage:image1 elapsedTime:0.05] forResource:@"resource1"];
    [_fetcher setResponse:[TDFMockResponse mockWithImage:nil elapsedTime:0] forResource:@"resource2"];
    
    XCTestExpectation *expectFirstImage = [self expectationWithDescription:@"1"];
    XCTestExpectation *expectSecondImage = [self expectationWithDescription:@"2"];
    XCTestExpectation *expectCompletion = [self expectationWithDescription:@"3"];
    
    DFImageRequest *request1 = [DFImageRequest requestWithResource:@"resource1"];
    DFImageRequest *request2 = [DFImageRequest requestWithResource:@"resource2"];
    
    DFCompositeImageTask *task = [DFCompositeImageTask compositeImageTaskWithRequests:@[ request1, request2 ] imageHandler:^(UIImage *image, NSDictionary *info, DFCompositeImageTask *compositeTask) {
        DFImageTask *completedTask = info[DFImageInfoTaskKey];
        if ([completedTask.request.resource isEqualToString:request1.resource]) {
            XCTAssertEqualObjects(image, image1);
            [expectFirstImage fulfill];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [expectSecondImage fulfill];
            });
        }
        if ([completedTask.request.resource isEqualToString:request2.resource]) {
            XCTFail(@"Unexpected callback");
        }
    } completionHandler:^(DFCompositeImageTask *compositeTask) {
        XCTAssertTrue(compositeTask.isFinished);
        [expectCompletion fulfill];
    }];
    [task resume];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

/*! 2f, 1f -> [no callback]
 */
- (void)testThatHandlerCalledOnceWhenSecondTaskFailesThenFirstSuccedes {
    [_fetcher setResponse:[TDFMockResponse mockWithImage:nil elapsedTime:0.05] forResource:@"resource1"];
    [_fetcher setResponse:[TDFMockResponse mockWithImage:nil elapsedTime:0] forResource:@"resource2"];
    
    XCTestExpectation *expectFirstImage = [self expectationWithDescription:@"1"];
    XCTestExpectation *expectSecondImage = [self expectationWithDescription:@"2"];
    XCTestExpectation *expectCompletion = [self expectationWithDescription:@"3"];
    
    DFImageRequest *request1 = [DFImageRequest requestWithResource:@"resource1"];
    DFImageRequest *request2 = [DFImageRequest requestWithResource:@"resource2"];
    
    DFCompositeImageTask *task = [DFCompositeImageTask compositeImageTaskWithRequests:@[ request1, request2 ] imageHandler:^(UIImage *image, NSDictionary *info, DFCompositeImageTask *compositeTask) {
        XCTFail(@"Unexpected callback");
    } completionHandler:^(DFCompositeImageTask *compositeTask) {
        XCTAssertTrue(compositeTask.isFinished);
        [expectCompletion fulfill];
    }];
    [task resume];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectFirstImage fulfill];
        [expectSecondImage fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

#pragma mark - Multiple Requests

/*! 3s, 2f, 4s -> 3s, 4s, [1st cancelled]
 */
- (void)testThatMultipleRequestsDontBreakTask {
    [_fetcher setResponse:[TDFMockResponse mockWithImage:nil elapsedTime:0.15] forResource:@"resource1"];
    
    [_fetcher setResponse:[TDFMockResponse mockWithImage:nil elapsedTime:0.05] forResource:@"resource2"];
    
    UIImage *image3 = [UIImage new];
    [_fetcher setResponse:[TDFMockResponse mockWithImage:image3 elapsedTime:0.0] forResource:@"resource3"];
    
    UIImage *image4 = [UIImage new];
    [_fetcher setResponse:[TDFMockResponse mockWithImage:image4 elapsedTime:0.1] forResource:@"resource4"];
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"1"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"2"];
    XCTestExpectation *expectation3 = [self expectationWithDescription:@"3"];
    XCTestExpectation *expectation4 = [self expectationWithDescription:@"4"];
    XCTestExpectation *expectCompletion = [self expectationWithDescription:@"5"];
    
    DFImageRequest *request1 = [DFImageRequest requestWithResource:@"resource1"];
    DFImageRequest *request2 = [DFImageRequest requestWithResource:@"resource2"];
    DFImageRequest *request3 = [DFImageRequest requestWithResource:@"resource3"];
    DFImageRequest *request4 = [DFImageRequest requestWithResource:@"resource4"];
    
    [self expectationForNotification:TDFMockFetchOperationWillCancelNotification object:nil handler:^BOOL(NSNotification *notification) {
        TDFMockFetchOperation *operation = notification.object;
        XCTAssertTrue([operation.request.resource isEqualToString:request1.resource]);
        return YES;
    }];
    
    BOOL __block isThirdCallbackCalled;
    DFCompositeImageTask *task = [DFCompositeImageTask compositeImageTaskWithRequests:@[ request1, request2, request3, request4 ] imageHandler:^(UIImage *image, NSDictionary *info, DFCompositeImageTask *compositeTask) {
        DFImageTask *completedTask = info[DFImageInfoTaskKey];
        if ([completedTask.request.resource isEqualToString:request3.resource]) {
            XCTAssertEqualObjects(image, image3);
            XCTAssertFalse(compositeTask.isFinished);
            isThirdCallbackCalled = YES;
            [expectation3 fulfill];
        }
        if ([completedTask.request.resource isEqualToString:request1.resource] || [completedTask.request.resource isEqualToString:request2.resource]) {
            XCTFail(@"Unexpected callback");
        }
        if ([completedTask.request.resource isEqualToString:request4.resource]) {
            XCTAssertTrue(isThirdCallbackCalled);
            XCTAssertTrue(compositeTask.isFinished);
            XCTAssertEqualObjects(image, image4);
            [expectation4 fulfill];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [expectation1 fulfill];
                [expectation2 fulfill];
            });
        }
    } completionHandler:^(DFCompositeImageTask *compositeTask) {
        XCTAssertTrue(compositeTask.isFinished);
        [expectCompletion fulfill];
    }];
    
    XCTAssertFalse(task.isFinished);
    [task resume];
    XCTAssertFalse(task.isFinished);
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

#pragma mark - Cancellation

- (void)testThatCancelledTaskRemovesImageHandlerAndCompletionHandler {
    DFCompositeImageTask *task = [DFCompositeImageTask compositeImageTaskWithRequests:@[[DFImageRequest requestWithResource:@"resource"]] imageHandler:^(UIImage *image, NSDictionary *info, DFCompositeImageTask *compositeTask) {
        // Do nothing
    } completionHandler:^(DFCompositeImageTask *compositeTask) {
        // Do nothing
    }];
    
    XCTAssertNotNil(task.imageHandler);
    XCTAssertNotNil(task.completionHandler);
    
    [task cancel];
    
    XCTAssertNil(task.imageHandler);
    XCTAssertNil(task.completionHandler);
}

- (void)testThatCancelMethodCancellsAllTasks {
    [_fetcher setResponse:[TDFMockResponse mockWithImage:[UIImage new] elapsedTime:0.5] forResource:@"resource1"];
    [_fetcher setResponse:[TDFMockResponse mockWithImage:[UIImage new] elapsedTime:0.5] forResource:@"resource2"];
    
    DFCompositeImageTask *task = [DFCompositeImageTask compositeImageTaskWithRequests:@[[DFImageRequest requestWithResource:@"resource1"], [DFImageRequest requestWithResource:@"resource2"]] imageHandler:^(UIImage *image, NSDictionary *info, DFCompositeImageTask *compositeTask) {
        XCTFail(@"Invalid callback");
    } completionHandler:^(DFCompositeImageTask *compositeTask) {
        XCTFail(@"Invalid callback");
    }];
    
    
    NSInteger __block numberOfStartedTasks = 0;
    [self expectationForNotification:TDFMockFetcherDidStartOperationNotification object:nil handler:^BOOL(NSNotification *notification) {
        numberOfStartedTasks++;
        return numberOfStartedTasks == 2;
    }];
    
    [task resume];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    
    NSInteger __block numberOfCancelledTasks = 0;
    [self expectationForNotification:TDFMockFetchOperationWillCancelNotification object:nil handler:^BOOL(NSNotification *notification) {
        numberOfCancelledTasks++;
        return numberOfCancelledTasks == 2;
    }];
    
    [task cancel];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

#pragma mark - Misc

/*! 2s, 1f -> 2s, 1f
 */
- (void)testThatAllowsObsoleteRequestPropertyDisablesSpecialHandling {
    [_fetcher setResponse:[TDFMockResponse mockWithError:[NSError errorWithDomain:@"ErrorDomain" code:-154 userInfo:nil] elapsedTime:0.05] forResource:@"resource1"];
    UIImage *image2 = [TDFTesting testImage];
    [_fetcher setResponse:[TDFMockResponse mockWithImage:image2 elapsedTime:0] forResource:@"resource2"];
    
    XCTestExpectation *expectFistImage = [self expectationWithDescription:@"1"];
    XCTestExpectation *expectSecondImage = [self expectationWithDescription:@"2"];
    XCTestExpectation *expectCompletion = [self expectationWithDescription:@"3"];
    
    DFImageRequest *request1 = [DFImageRequest requestWithResource:@"resource1"];
    DFImageRequest *request2 = [DFImageRequest requestWithResource:@"resource2"];
    
    BOOL __block isFirstTaskFinished = NO;
    BOOL __block isSecondTaskFinished = NO;
    DFCompositeImageTask *task = [DFCompositeImageTask compositeImageTaskWithRequests:@[ request1, request2 ] imageHandler:^(UIImage *image, NSDictionary *info, DFCompositeImageTask *compositeTask) {
        DFImageTask *completedTask = info[DFImageInfoTaskKey];
        if ([completedTask.request.resource isEqualToString:request1.resource]) {
            isFirstTaskFinished = YES;
            XCTAssertTrue(isSecondTaskFinished);
            XCTAssertNil(image);
            NSError *error = info[DFImageInfoErrorKey];
            XCTAssertNotNil(error);
            XCTAssertEqualObjects(error.domain, @"ErrorDomain");
            XCTAssertEqual(error.code, -154);
            [expectFistImage fulfill];
        }
        if ([completedTask.request.resource isEqualToString:request2.resource]) {
            isSecondTaskFinished = YES;
            XCTAssertFalse(isFirstTaskFinished);
            XCTAssertEqualObjects(image, image2);
            [expectSecondImage fulfill];
        }
    } completionHandler:^(DFCompositeImageTask *compositeTask) {
        XCTAssertTrue(compositeTask.isFinished);
        XCTAssertTrue(isFirstTaskFinished);
        XCTAssertTrue(isSecondTaskFinished);
        [expectCompletion fulfill];
    }];
    
    XCTAssertTrue(task.allowsObsoleteRequests);
    task.allowsObsoleteRequests = NO;
    XCTAssertFalse(task.allowsObsoleteRequests);
    
    [task resume];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testThatImageTaskHandlerIsNotOverriden {
    UIImage *originalImage = [TDFTesting testImage];
    [_fetcher setResponse:[TDFMockResponse mockWithImage:originalImage] forResource:@"resource"];
    
    XCTestExpectation *expectOriginalImageHandler = [self expectationWithDescription:@"1"];
    XCTestExpectation *expectCompositeImageHandler = [self expectationWithDescription:@"2"];
    XCTestExpectation *expectCompletionHandler = [self expectationWithDescription:@"3"];
    
    DFImageRequest *originalRequest = [DFImageRequest requestWithResource:@"resource"];
    BOOL __block isCompositeImageHandlerCalled = NO;
    
    DFImageTask *task = [[DFImageManager sharedManager] imageTaskForRequest:originalRequest completion:^(UIImage *image, NSDictionary *info) {
        XCTAssertNotNil(info);
        XCTAssertNotNil(info[DFImageInfoTaskKey]);
        XCTAssertEqualObjects(image, originalImage);
        [expectOriginalImageHandler fulfill];
    }];
    
    DFCompositeImageTask *compositeTask = [[DFCompositeImageTask alloc] initWithImageTasks:@[task] imageHandler:^(UIImage *image, NSDictionary *info, DFCompositeImageTask *innerCompositeTask) {
        isCompositeImageHandlerCalled = YES;
        DFImageTask *completedTask = info[DFImageInfoTaskKey];
        XCTAssertNotNil(completedTask);
        XCTAssertTrue([completedTask.request.resource isEqualToString:originalRequest.resource]);
        XCTAssertEqualObjects(image, originalImage);
        XCTAssertTrue(innerCompositeTask.isFinished);
        [expectCompositeImageHandler fulfill];
    } completionHandler:^(DFCompositeImageTask *compositeTask) {
        XCTAssertTrue(isCompositeImageHandlerCalled);
        XCTAssertTrue(compositeTask.isFinished);
        [expectCompletionHandler fulfill];
    }];
    XCTAssertFalse(compositeTask.isFinished);
    [compositeTask resume];
    XCTAssertFalse(compositeTask.isFinished);
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testThatHandlersAreCalledOnTheMainThread {
    [_fetcher setResponse:[TDFMockResponse mockWithImage:[UIImage new]] forResource:@"resource"];
    
    XCTestExpectation *expectImageHandler = [self expectationWithDescription:@"1"];
    XCTestExpectation *expectCompletionHandler = [self expectationWithDescription:@"2"];
    
    DFCompositeImageTask *task = [DFCompositeImageTask compositeImageTaskWithRequests:@[[DFImageRequest requestWithResource:@"resource"]] imageHandler:^(UIImage *image, NSDictionary *info, DFCompositeImageTask *compositeTask) {
        XCTAssertTrue([NSThread isMainThread]);
        [expectImageHandler fulfill];
    } completionHandler:^(DFCompositeImageTask *compositeTask) {
        XCTAssertTrue([NSThread isMainThread]);
        [expectCompletionHandler fulfill];
    }];
    [task resume];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

#pragma mark - Fault Tolerence

- (void)testThatImageHandlerIsNullable {
    [_fetcher setResponse:[TDFMockResponse mockWithImage:[UIImage new]] forResource:@"resource"];
    
    XCTestExpectation *expectCompletionHandler = [self expectationWithDescription:@"2"];
    
    DFCompositeImageTask *task = [DFCompositeImageTask compositeImageTaskWithRequests:@[[DFImageRequest requestWithResource:@"resource"]] imageHandler:nil completionHandler:^(DFCompositeImageTask *compositeTask) {
        XCTAssertTrue(compositeTask.isFinished);
        [expectCompletionHandler fulfill];
    }];
    [task resume];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testThatCompletionHandlerIsNullable {
    [_fetcher setResponse:[TDFMockResponse mockWithImage:[UIImage new]] forResource:@"resource"];
    
    XCTestExpectation *expectImageHandler = [self expectationWithDescription:@"1"];
    
    DFCompositeImageTask *task = [DFCompositeImageTask compositeImageTaskWithRequests:@[[DFImageRequest requestWithResource:@"resource"]] imageHandler:^(UIImage *image, NSDictionary *info, DFCompositeImageTask *compositeTask) {
        XCTAssertTrue(compositeTask.isFinished);
        [expectImageHandler fulfill];
    } completionHandler:nil];
    [task resume];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testThatExpectionIsRaisedWhenTaskIsInitializedWithEmptyArray {
    XCTAssertThrows([[DFCompositeImageTask alloc] initWithImageTasks:@[] imageHandler:nil completionHandler:nil]);
}

@end
