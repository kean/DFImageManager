// The MIT License (MIT)
//
// Copyright (c) 2014 Alexander Grebenyuk (github.com/kean).
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "DFImageManagerProtocol.h"
#import "DFImageRequestID.h"


@interface DFImageRequestID ()

@property (nonatomic, weak, readonly) id<DFImageManager> imageManager;
@property (nonatomic, readonly) NSString *operationID;
@property (nonatomic, readonly) NSString *handlerID;

@end

@implementation DFImageRequestID

- (instancetype)initWithImageManager:(id<DFImageManager>)imageManager {
    if (self = [super init]) {
        _imageManager = imageManager;
    }
    return self;
}

+ (DFImageRequestID *)requestIDWithImageManager:(id<DFImageManager>)imageManager operationID:(NSString *)operationID handlerID:(NSString *)handlerID {
    DFImageRequestID *requestID = [[DFImageRequestID alloc] initWithImageManager:imageManager];
    [requestID setOperationID:operationID handlerID:handlerID];
    return requestID;
}

- (void)setOperationID:(NSString *)operationID handlerID:(NSString *)handlerID {
    if (_operationID != nil ||
        _handlerID != nil) {
        [NSException raise:NSInternalInconsistencyException format:@"Attempting to rewrite image request state"];
    }
    _operationID = operationID;
    _handlerID = handlerID;
}

- (void)cancel {
    [self.imageManager cancelRequestWithID:self];
}

- (void)setPriority:(DFImageRequestPriority)priority {
    [self.imageManager setPriority:priority forRequestWithID:self];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p> { imageManager = %@, operationID = %@, handlerID = %@ }", [self class], self, self.imageManager, self.operationID, self.handlerID];
}

@end
