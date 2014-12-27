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

- (instancetype)initWithImageManager:(id<DFImageManager>)imageManager operationID:(NSString *)operationID handlerID:(NSString *)handlerID {
    if (self = [super init]) {
        NSParameterAssert(operationID);
        NSParameterAssert(handlerID);
        _imageManager = imageManager;
        _operationID = operationID;
        _handlerID = handlerID;
    }
    return self;
}

- (instancetype)initWithImageManager:(id<DFImageManager>)imageManager operationID:(NSString *)operationID {
    return [self initWithImageManager:imageManager operationID:operationID ?: [[NSUUID UUID] UUIDString] handlerID:[[NSUUID UUID] UUIDString]];
}

- (void)cancel {
    [self.imageManager cancelRequestWithID:self];
}

- (void)setPriority:(DFImageRequestPriority)priority {
    [self.imageManager setPriority:priority forRequestWithID:self];
}

- (NSUInteger)hash {
    return [self.operationID hash];
}

- (BOOL)isEqual:(id)object {
    if (object == self) {
        return YES;
    }
    if ([object class] != [self class]) {
        return NO;
    }
    DFImageRequestID *other = object;
    return ([other.imageManager isEqual:self.imageManager] &&
            [other.operationID isEqualToString:self.operationID] &&
            [other.handlerID isEqualToString:self.handlerID]);
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p> { imageManager = %@, operationID = %@, handlerID = %@ }", [self class], self, self.imageManager, self.operationID, self.handlerID];
}

@end
