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

#import "DFImageRequestID.h"


@interface DFImageRequestID ()

@property (nonatomic, readonly) NSString *requestID;
@property (nonatomic, readonly) NSString *handlerID;

@end

@implementation DFImageRequestID

- (instancetype)initWithRequestID:(NSString *)requestID handlerID:(NSString *)handlerID {
   if (self = [super init]) {
      NSParameterAssert(requestID);
      NSParameterAssert(handlerID);
      _requestID = requestID;
      _handlerID = handlerID;
   }
   return self;
}

- (instancetype)initWithRequestID:(NSString *)requestID {
   return [self initWithRequestID:requestID ?: [[NSUUID UUID] UUIDString] handlerID:[[NSUUID UUID] UUIDString]];
}

- (NSString *)description {
   return [NSString stringWithFormat:@"<%@ %p> { requestID = %@, handlerID = %@ }", [self class], self, self.requestID, self.handlerID];
}

@end
