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

#import "DFImageHandlerDictionary.h"
#import "DFImageRequestID+Protected.h"


@implementation DFImageHandlerDictionary {
   NSMutableDictionary *_handlers;
}

- (instancetype)init {
   if (self = [super init]) {
      _handlers = [NSMutableDictionary new];
   }
   return self;
}

- (void)addHandler:(id)handler forRequestID:(DFImageRequestID *)requestID {
   NSMutableDictionary *handlers = _handlers[requestID.operationID];
   if (!handlers) {
      handlers = [NSMutableDictionary new];
      _handlers[requestID.operationID] = handlers;
   }
   [handlers setObject:handler forKey:requestID.handlerID];
}

- (id)handlerForRequestID:(DFImageRequestID *)requestID {
   return _handlers[requestID.operationID][requestID.handlerID];
}

- (void)removeHandlerForRequestID:(DFImageRequestID *)requestID {
   NSMutableDictionary *handlers = _handlers[requestID.operationID];
   [handlers removeObjectForKey:requestID.handlerID];
}

- (NSArray *)handlersForOperationID:(NSString *)key {
   return [_handlers[key] allValues];
}

- (void)removeAllHandlersForOperationID:(NSString *)operationID {
   [_handlers removeObjectForKey:operationID];
}

- (NSDictionary *)allHandlers {
   return [_handlers copy];
}

@end