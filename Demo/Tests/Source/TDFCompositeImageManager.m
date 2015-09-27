//
//  TDFCompositeImageManager.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 3/1/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "DFImageManagerKit.h"
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>


@interface _TDFMockImageTask : DFImageTask

@property (nonatomic) BOOL preheating;

@end

@implementation _TDFMockImageTask

- (DFImageTask *)resume {
    return self;
}

- (void)cancel {
    // Do nothing
}

- (void)setPriority:(DFImageRequestPriority)priority {
    // Do nothing
}

@end


@interface _TDFMockImageManagerForComposite : NSObject <DFImageManaging>

@property (nonatomic) NSString *supportedResource;
@property (nonatomic, readonly) NSArray *imageTasks;

@end

@implementation _TDFMockImageManagerForComposite {
    NSMutableArray *_imageTasks;
}

- (instancetype)init {
    if (self = [super init]) {
        _imageTasks = [NSMutableArray new];
    }
    return self;
}

- (BOOL)canHandleRequest:(nonnull DFImageRequest *)request {
    return [self.supportedResource isEqualToString:request.resource];
}

- (nonnull DFImageTask *)imageTaskForResource:(nonnull id)resource completion:(nullable DFImageTaskCompletion)completion {
    return [self imageTaskForRequest:[DFImageRequest requestWithResource:resource] completion:completion];
}

- (nonnull DFImageTask *)imageTaskForRequest:(nonnull DFImageRequest *)request completion:(nullable DFImageTaskCompletion)completion {
    _TDFMockImageTask *task = [_TDFMockImageTask new];
    [_imageTasks addObject:task];
    return task;
}

- (nullable DFImageTask *)requestImageForResource:(nonnull id)resource completion:(nullable DFImageTaskCompletion)completion {
    return [self requestImageForRequest:[DFImageRequest requestWithResource:resource] completion:completion];
}

- (nullable DFImageTask *)requestImageForRequest:(nonnull DFImageRequest *)request completion:(nullable DFImageTaskCompletion)completion {
    return [self imageTaskForRequest:request completion:completion];
}

- (void)getImageTasksWithCompletion:(void (^)(NSArray<DFImageTask *> * _Nonnull, NSArray<DFImageTask *> * _Nonnull))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableSet *tasks = [NSMutableSet new];
        NSMutableSet *preheatingTasks = [NSMutableSet new];
        for (_TDFMockImageTask *task in _imageTasks) {
            if (task.preheating) {
                [preheatingTasks addObject:task];
            } else {
                [tasks addObject:task];
            }
        }
        completion([tasks allObjects], [preheatingTasks allObjects]);
    });
}

- (void)invalidateAndCancel {
    // Do nothing
}

- (void)startPreheatingImagesForRequests:(NSArray *)requests {
    for (DFImageRequest *request in requests) {
        _TDFMockImageTask *task = (id)[self imageTaskForRequest:request completion:nil];
        task.preheating = YES;
        [task resume];
    }
}

- (void)stopPreheatingImagesForRequests:(NSArray *)requests {
    // Do nothing
}

- (void)stopPreheatingImagesForAllRequests {
    // Do nothing
}

- (void)removeAllCachedImages {
    // Do nothing
}

@end


/*! Test suite for DFCompositeImageManager class.
 */
@interface TDFCompositeImageManager : XCTestCase

@end

@implementation TDFCompositeImageManager

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testThatRequestsAreForwarded {
    NSString *resource1 = @"01";
    NSString *resource2 = @"02";
    
    _TDFMockImageManagerForComposite *manager1 = [_TDFMockImageManagerForComposite new];
    manager1.supportedResource = resource1;
    
    _TDFMockImageManagerForComposite *manager2 = [_TDFMockImageManagerForComposite new];
    manager2.supportedResource = resource2;
    
    DFCompositeImageManager *composite = [[DFCompositeImageManager alloc] initWithImageManagers:@[ manager1, manager2 ]];
    
    DFImageRequest *request1 = [DFImageRequest requestWithResource:resource1];
    DFImageRequest *request2 = [DFImageRequest requestWithResource:resource2];
    
    XCTAssertTrue([composite canHandleRequest:request1]);
    XCTAssertTrue([composite canHandleRequest:request2]);
    
    DFImageTask *task1 = [composite imageTaskForRequest:request1 completion:nil];
    DFImageTask *task2 = [composite imageTaskForRequest:request2 completion:nil];
    
    XCTAssertTrue(manager1.imageTasks.count == 1);
    XCTAssertTrue([manager1.imageTasks containsObject:task1]);
    XCTAssertTrue(manager2.imageTasks.count == 1);
    XCTAssertTrue([manager2.imageTasks containsObject:task2]);
}

- (void)testThatCompositesCanFormATreeStructure {
    NSString *resource1 = @"01";
    NSString *resource2 = @"02";
    
    _TDFMockImageManagerForComposite *manager1 = [_TDFMockImageManagerForComposite new];
    manager1.supportedResource = resource1;
    
    _TDFMockImageManagerForComposite *manager2 = [_TDFMockImageManagerForComposite new];
    manager2.supportedResource = resource2;
    
    DFCompositeImageManager *composite = [[DFCompositeImageManager alloc] initWithImageManagers:@[ manager1, [[DFCompositeImageManager alloc] initWithImageManagers:@[ manager2 ]] ]];
    
    DFImageRequest *request1 = [DFImageRequest requestWithResource:resource1];
    DFImageRequest *request2 = [DFImageRequest requestWithResource:resource2];
    
    XCTAssertTrue([composite canHandleRequest:request1]);
    XCTAssertTrue([composite canHandleRequest:request2]);
    
    DFImageTask *task1 = [composite imageTaskForRequest:request1 completion:nil];
    DFImageTask *task2 = [composite imageTaskForRequest:request2 completion:nil];
    
    XCTAssertTrue(manager1.imageTasks.count == 1);
    XCTAssertTrue([manager1.imageTasks containsObject:task1]);
    XCTAssertTrue(manager2.imageTasks.count == 1);
    XCTAssertTrue([manager2.imageTasks containsObject:task2]);
}

- (void)testThatIfTheRequestCantBeHandledTheExceptionIsThrown {
    _TDFMockImageManagerForComposite *manager = [_TDFMockImageManagerForComposite new];
    manager.supportedResource = @"resourse_01";
    DFCompositeImageManager *compisite = [[DFCompositeImageManager alloc] initWithImageManagers:@[ manager ]];
    XCTAssertThrows([compisite imageTaskForRequest:[DFImageRequest requestWithResource:@"resourse_02"] completion:nil]);
}

- (void)testThatGetImageTasksWithCompletionIsForwarded {
    NSString *resource1 = @"01";
    NSString *resource2 = @"02";
    
    _TDFMockImageManagerForComposite *manager1 = [_TDFMockImageManagerForComposite new];
    manager1.supportedResource = resource1;
    
    _TDFMockImageManagerForComposite *manager2 = [_TDFMockImageManagerForComposite new];
    manager2.supportedResource = resource2;
    
    DFCompositeImageManager *composite = [[DFCompositeImageManager alloc] initWithImageManagers:@[ manager1, manager2 ]];
    
    DFImageRequest *request1 = [DFImageRequest requestWithResource:resource1];
    DFImageRequest *request2 = [DFImageRequest requestWithResource:resource2];
    
    DFImageTask *task1 = [composite imageTaskForRequest:request1 completion:nil];
    DFImageTask *task2 = [composite imageTaskForRequest:request2 completion:nil];
    
    [composite startPreheatingImagesForRequests:@[ [DFImageRequest requestWithResource:@"02" ] ]];
    
    XCTestExpectation *expectTasks = [self expectationWithDescription:@"1"];
    
    [composite getImageTasksWithCompletion:^(NSArray *tasks, NSArray *preheatingTasks) {
        XCTAssertTrue([NSThread isMainThread]);
        XCTAssertTrue(tasks.count == 2);
        XCTAssertTrue([tasks containsObject:task1]);
        XCTAssertTrue([tasks containsObject:task2]);
        XCTAssertTrue(preheatingTasks.count == 1);
        [expectTasks fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
