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

- (void)testThatSingleSuccessfullRequestIsHandled {
    UIImage *originalImage = [TDFTesting testImage];
    [_fetcher setResponse:[TDFMockResponse mockWithResponse:[DFImageResponse responseWithImage:originalImage]] forResource:@"resource"];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"test"];
    DFImageRequest *originalRequest = [DFImageRequest requestWithResource:@"resource"];
    DFCompositeImageTask *task = [[DFCompositeImageTask alloc] initWithRequest:originalRequest handler:^(UIImage *image, NSDictionary *info, DFImageRequest *request) {
        XCTAssertNotNil(info[DFImageInfoTaskKey]);
        XCTAssertEqualObjects(image, originalImage);
        XCTAssertEqualObjects(request, originalRequest);
        [expectation fulfill];
    }];
    [task start];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

#pragma mark - First Task Finishes First

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
    
    DFCompositeImageTask *task = [[DFCompositeImageTask alloc] initWithRequests:@[ request1, request2 ] handler:^(UIImage *image, NSDictionary *info, DFImageRequest *request) {
        if (request == request1) {
            XCTAssertEqualObjects(image, image1);
            [expectation1 fulfill];
        }
        if (request == request2) {
            XCTAssertEqualObjects(image, image2);
            [expectation2 fulfill];
        }
    }];
    [task start];
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
    
    DFCompositeImageTask *task = [[DFCompositeImageTask alloc] initWithRequests:@[ request1, request2 ] handler:^(UIImage *image, NSDictionary *info, DFImageRequest *request) {
        if (request == request1) {
            XCTAssertEqualObjects(image, image1);
            [expectation1 fulfill];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [expectation2 fulfill];
            });
        }
        if (request == request2) {
            XCTFail(@"Unexpected callback");
        }
    }];
    [task start];
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
    
    DFCompositeImageTask *task = [[DFCompositeImageTask alloc] initWithRequests:@[ request1, request2 ] handler:^(UIImage *image, NSDictionary *info, DFImageRequest *request) {
        if (request == request1) {
            XCTFail(@"Unexpected callback");
        }
        if (request == request2) {
            XCTAssertEqualObjects(image, image2);
            [expectation2 fulfill];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [expectation1 fulfill];
            });
        }
    }];
    [task start];
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
    
    DFCompositeImageTask *task = [[DFCompositeImageTask alloc] initWithRequests:@[ request1, request2 ] handler:^(UIImage *image, NSDictionary *info, DFImageRequest *request) {
        if (request == request1) {
            XCTFail(@"Unexpected callback");
        }
        if (request == request2) {
            XCTAssertNil(image);
            [expectation2 fulfill];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [expectation1 fulfill];
            });
        }
    }];
    [task start];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

#pragma mark - Second Task Finishes First

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
    
    DFCompositeImageTask *task = [[DFCompositeImageTask alloc] initWithRequests:@[ request1, request2 ] handler:^(UIImage *image, NSDictionary *info, DFImageRequest *request) {
        if (request == request1) {
            XCTFail(@"Callback should get called once");
        }
        if (request == request2) {
            XCTAssertEqualObjects(image, image2);
            [expectation2 fulfill];
        }
    }];
    [task start];
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
    
    DFCompositeImageTask *task = [[DFCompositeImageTask alloc] initWithRequests:@[ request1, request2 ] handler:^(UIImage *image, NSDictionary *info, DFImageRequest *request) {
        if (request == request1) {
            XCTAssertEqualObjects(image, image1);
            [expectation1 fulfill];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [expectation2 fulfill];
            });
        }
        if (request == request2) {
            XCTFail(@"Unexpected callback");
        }
    }];
    [task start];
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
    
    DFCompositeImageTask *task = [[DFCompositeImageTask alloc] initWithRequests:@[ request1, request2 ] handler:^(UIImage *image, NSDictionary *info, DFImageRequest *request) {
        if (request == request1) {
            XCTAssertNil(image);
            [expectation1 fulfill];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [expectation2 fulfill];
            });
        }
        if (request == request2) {
            XCTFail(@"Unexpected callback");
        }
    }];
    [task start];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
