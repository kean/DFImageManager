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
    [_fetcher setResponse:[TDFMockResponse mockWithResponse:[DFImageResponse responseWithImage:originalImage]] forResource:@"resource"];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"test"];
    DFImageRequest *originalRequest = [DFImageRequest requestWithResource:@"resource"];
    DFCompositeImageTask *task = [DFCompositeImageTask compositeImageTaskWithRequests:@[originalRequest] imageHandler:^(UIImage *image, NSDictionary *info, DFImageRequest *request, DFCompositeImageTask *innerTask) {
        XCTAssertNotNil(info[DFImageInfoTaskKey]);
        XCTAssertEqualObjects(image, originalImage);
        XCTAssertTrue([request.resource isEqualToString:originalRequest.resource]);
        XCTAssertTrue(innerTask.isFinished);
        [expectation fulfill];
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
    [_fetcher setResponse:[TDFMockResponse mockWithResponse:[DFImageResponse responseWithImage:image1] elapsedTime:0] forResource:@"resource1"];
    UIImage *image2 = [TDFTesting testImage];
    [_fetcher setResponse:[TDFMockResponse mockWithResponse:[DFImageResponse responseWithImage:image2] elapsedTime:0.05] forResource:@"resource2"];
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"test1"];
    DFImageRequest *request1 = [DFImageRequest requestWithResource:@"resource1"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"test2"];
    DFImageRequest *request2 = [DFImageRequest requestWithResource:@"resource2"];
    
    DFCompositeImageTask *task = [DFCompositeImageTask compositeImageTaskWithRequests:@[ request1, request2 ] imageHandler:^(UIImage *image, NSDictionary *info, DFImageRequest *request, DFCompositeImageTask *innerTask) {
        if ([request.resource isEqualToString:request1.resource]) {
            XCTAssertEqualObjects(image, image1);
            XCTAssertFalse(innerTask.isFinished);
            [expectation1 fulfill];
        }
        if ([request.resource isEqualToString:request2.resource]) {
            XCTAssertEqualObjects(image, image2);
            XCTAssertTrue(innerTask.isFinished);
            [expectation2 fulfill];
        }
    }];
    XCTAssertFalse(task.isFinished);
    [task resume];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

/*! 1s, 2f -> 1s
 */
- (void)testThatHandlerCalledOnceWhenFirstTaskSucceedesThenSecondFails {
    UIImage *image1 = [UIImage new];
    [_fetcher setResponse:[TDFMockResponse mockWithResponse:[DFImageResponse responseWithImage:image1] elapsedTime:0] forResource:@"resource1"];
    [_fetcher setResponse:[TDFMockResponse mockWithResponse:[DFImageResponse responseWithImage:nil] elapsedTime:0.05] forResource:@"resource2"];
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"test1"];
    DFImageRequest *request1 = [DFImageRequest requestWithResource:@"resource1"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"test2"];
    DFImageRequest *request2 = [DFImageRequest requestWithResource:@"resource2"];
    
    DFCompositeImageTask *task = [DFCompositeImageTask compositeImageTaskWithRequests:@[ request1, request2 ] imageHandler:^(UIImage *image, NSDictionary *info, DFImageRequest *request, DFCompositeImageTask *innerTask) {
        if ([request.resource isEqualToString:request1.resource]) {
            XCTAssertEqualObjects(image, image1);
            [expectation1 fulfill];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [expectation2 fulfill];
            });
        }
        if ([request.resource isEqualToString:request2.resource]) {
            XCTFail(@"Unexpected callback");
        }
    }];
    [task resume];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

/*! 1f, 2s -> 2s
 */
- (void)testThatHandlerCalledOnceWhenFirstTaskFailsThenSecondSucceedes {
    [_fetcher setResponse:[TDFMockResponse mockWithResponse:[DFImageResponse responseWithImage:nil] elapsedTime:0] forResource:@"resource1"];
    UIImage *image2 = [TDFTesting testImage];
    [_fetcher setResponse:[TDFMockResponse mockWithResponse:[DFImageResponse responseWithImage:image2] elapsedTime:0.05] forResource:@"resource2"];
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"test1"];
    DFImageRequest *request1 = [DFImageRequest requestWithResource:@"resource1"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"test2"];
    DFImageRequest *request2 = [DFImageRequest requestWithResource:@"resource2"];
    
    DFCompositeImageTask *task = [DFCompositeImageTask compositeImageTaskWithRequests:@[ request1, request2 ] imageHandler:^(UIImage *image, NSDictionary *info, DFImageRequest *request, DFCompositeImageTask *innerTask) {
        if ([request.resource isEqualToString:request1.resource]) {
            XCTFail(@"Unexpected callback");
        }
        if ([request.resource isEqualToString:request2.resource]) {
            XCTAssertEqualObjects(image, image2);
            XCTAssertTrue(innerTask.isFinished);
            [expectation2 fulfill];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [expectation1 fulfill];
            });
        }
    }];
    [task resume];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

/*! 1f, 2f -> 2f
 */
- (void)testThatHandlerCalledOnceWhenFirstTaskFailsThenSecondFails {
    [_fetcher setResponse:[TDFMockResponse mockWithResponse:[DFImageResponse responseWithImage:nil] elapsedTime:0] forResource:@"resource1"];
    [_fetcher setResponse:[TDFMockResponse mockWithResponse:[DFImageResponse responseWithImage:nil] elapsedTime:0.05] forResource:@"resource2"];
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"test1"];
    DFImageRequest *request1 = [DFImageRequest requestWithResource:@"resource1"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"test2"];
    DFImageRequest *request2 = [DFImageRequest requestWithResource:@"resource2"];
    
    DFCompositeImageTask *task = [DFCompositeImageTask compositeImageTaskWithRequests:@[ request1, request2 ] imageHandler:^(UIImage *image, NSDictionary *info, DFImageRequest *request, DFCompositeImageTask *innerTask) {
        XCTFail(@"Unexpected callback");
    }];
    [task resume];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation1 fulfill];
        [expectation2 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

#pragma mark - Image Handler (Two Requests: Second Task Finishes First)

/*! 2s -> 2s [1st cancelled]
 */
- (void)testThatHandlerCalledOnceAndFirstTaskCancelledWhenSecondSuccedes {
    UIImage *image1 = [UIImage new];
    [_fetcher setResponse:[TDFMockResponse mockWithResponse:[DFImageResponse responseWithImage:image1] elapsedTime:0.05] forResource:@"resource1"];
    UIImage *image2 = [TDFTesting testImage];
    [_fetcher setResponse:[TDFMockResponse mockWithResponse:[DFImageResponse responseWithImage:image2] elapsedTime:0] forResource:@"resource2"];
    
    [self expectationForNotification:TDFMockFetchOperationWillCancelNotification object:nil handler:nil];
    DFImageRequest *request1 = [DFImageRequest requestWithResource:@"resource1"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"test2"];
    DFImageRequest *request2 = [DFImageRequest requestWithResource:@"resource2"];
    
    DFCompositeImageTask *task = [DFCompositeImageTask compositeImageTaskWithRequests:@[ request1, request2 ] imageHandler:^(UIImage *image, NSDictionary *info, DFImageRequest *request, DFCompositeImageTask *innerTask) {
        if ([request.resource isEqualToString:request1.resource]) {
            XCTFail(@"Callback should get called once");
        }
        if ([request.resource isEqualToString:request2.resource]) {
            XCTAssertEqualObjects(image, image2);
            [expectation2 fulfill];
        }
    }];
    [task resume];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

/*! 2f, 1s -> 1s
 */
- (void)testThatHandlerCalledOnceWhenSecondTaskFailesThenFirstSucceedes {
    UIImage *image1 = [UIImage new];
    [_fetcher setResponse:[TDFMockResponse mockWithResponse:[DFImageResponse responseWithImage:image1] elapsedTime:0.05] forResource:@"resource1"];
    [_fetcher setResponse:[TDFMockResponse mockWithResponse:[DFImageResponse responseWithImage:nil] elapsedTime:0] forResource:@"resource2"];
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"test1"];
    DFImageRequest *request1 = [DFImageRequest requestWithResource:@"resource1"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"test2"];
    DFImageRequest *request2 = [DFImageRequest requestWithResource:@"resource2"];
    
    DFCompositeImageTask *task = [DFCompositeImageTask compositeImageTaskWithRequests:@[ request1, request2 ] imageHandler:^(UIImage *image, NSDictionary *info, DFImageRequest *request, DFCompositeImageTask *innerTask) {
        if ([request.resource isEqualToString:request1.resource]) {
            XCTAssertEqualObjects(image, image1);
            [expectation1 fulfill];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [expectation2 fulfill];
            });
        }
        if ([request.resource isEqualToString:request2.resource]) {
            XCTFail(@"Unexpected callback");
        }
    }];
    [task resume];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

/*! 2f, 1f -> 1f
 */
- (void)testThatHandlerCalledOnceWhenSecondTaskFailesThenFirstSuccedes {
    [_fetcher setResponse:[TDFMockResponse mockWithResponse:[DFImageResponse responseWithImage:nil] elapsedTime:0.05] forResource:@"resource1"];
    [_fetcher setResponse:[TDFMockResponse mockWithResponse:[DFImageResponse responseWithImage:nil] elapsedTime:0] forResource:@"resource2"];
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"test1"];
    DFImageRequest *request1 = [DFImageRequest requestWithResource:@"resource1"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"test2"];
    DFImageRequest *request2 = [DFImageRequest requestWithResource:@"resource2"];
    
    DFCompositeImageTask *task = [DFCompositeImageTask compositeImageTaskWithRequests:@[ request1, request2 ] imageHandler:^(UIImage *image, NSDictionary *info, DFImageRequest *request, DFCompositeImageTask *innerTask) {
        if ([request.resource isEqualToString:request1.resource]) {
            XCTAssertNil(image);
            [expectation1 fulfill];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [expectation2 fulfill];
            });
        }
        if ([request.resource isEqualToString:request2.resource]) {
            XCTFail(@"Unexpected callback");
        }
    }];
    [task resume];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

#pragma mark - Multiple Requests

/*! 3s, 2f, 4s -> 3s, 4s, [1st cancelled]
 */
- (void)testThatMultipleRequestsDontBreakTask {
    [_fetcher setResponse:[TDFMockResponse mockWithResponse:[DFImageResponse responseWithImage:nil] elapsedTime:0.15] forResource:@"resource1"];
    
    [_fetcher setResponse:[TDFMockResponse mockWithResponse:[DFImageResponse responseWithImage:nil] elapsedTime:0.05] forResource:@"resource2"];
    
    UIImage *image3 = [UIImage new];
    [_fetcher setResponse:[TDFMockResponse mockWithResponse:[DFImageResponse responseWithImage:image3] elapsedTime:0.0] forResource:@"resource3"];
    
    UIImage *image4 = [UIImage new];
    [_fetcher setResponse:[TDFMockResponse mockWithResponse:[DFImageResponse responseWithImage:image4] elapsedTime:0.1] forResource:@"resource4"];
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"test1"];
    DFImageRequest *request1 = [DFImageRequest requestWithResource:@"resource1"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"test2"];
    DFImageRequest *request2 = [DFImageRequest requestWithResource:@"resource2"];
    XCTestExpectation *expectation3 = [self expectationWithDescription:@"test3"];
    DFImageRequest *request3 = [DFImageRequest requestWithResource:@"resource3"];
    XCTestExpectation *expectation4 = [self expectationWithDescription:@"test4"];
    DFImageRequest *request4 = [DFImageRequest requestWithResource:@"resource4"];
    
    [self expectationForNotification:TDFMockFetchOperationWillCancelNotification object:nil handler:^BOOL(NSNotification *notification) {
        TDFMockFetchOperation *operation = notification.object;
        XCTAssertTrue([operation.request.resource isEqualToString:request1.resource]);
        return YES;
    }];
    
    BOOL __block isThirdCallbackCalled;
    DFCompositeImageTask *task = [DFCompositeImageTask compositeImageTaskWithRequests:@[ request1, request2, request3, request4 ] imageHandler:^(UIImage *image, NSDictionary *info, DFImageRequest *request, DFCompositeImageTask *innerTask) {
        if ([request.resource isEqualToString:request3.resource]) {
            XCTAssertEqualObjects(image, image3);
            XCTAssertFalse(innerTask.isFinished);
            isThirdCallbackCalled = YES;
            [expectation3 fulfill];
        }
        if ([request.resource isEqualToString:request1.resource] || [request.resource isEqualToString:request2.resource]) {
            XCTFail(@"Unexpected callback");
        }
        if ([request.resource isEqualToString:request4.resource]) {
            XCTAssertTrue(isThirdCallbackCalled);
            XCTAssertTrue(innerTask.isFinished);
            XCTAssertEqualObjects(image, image4);
            [expectation4 fulfill];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [expectation1 fulfill];
                [expectation2 fulfill];
            });
        }
    }];
    
    XCTAssertFalse(task.isFinished);
    [task resume];
    XCTAssertFalse(task.isFinished);
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
