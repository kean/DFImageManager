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

#import "DFCache.h"

/* Set of methods extending DFCache functionality. API to retrieve cached data or objects in batches.
*/
@interface DFCache (DFCacheExtended)

#pragma mark - Read (Batch)

/*! Retrieves batch of NSData instances for the given keys.
 @param keys Array of the unique keys.
 @param completion Completion block. Batch dictionary contains key:data pairs.
 */
- (void)batchCachedDataForKeys:(NSArray *)keys completion:(void (^)(NSDictionary *batch))completion;

/*! Returns dictionary with NSData instances that correspond to the given keys.
 @param keys Array of the unique keys.
 @return NSDictionary instance with key:data pairs.
 */
- (NSDictionary *)batchCachedDataForKeys:(NSArray *)keys;

/*! Retrieves batch of objects that correspond to the given keys.
 @param keys Array of the unique keys.
 @param completion Completion block. Batch dictionary contains key : object pairs retrieved from receiver.
 */
- (void)batchCachedObjectsForKeys:(NSArray *)keys completion:(void (^)(NSDictionary *batch))completion;

/*! Returns batch of objects that correspond to the given keys.
 @param keys Array of the unique keys.
 @return NSDictionary instance with key:data pairs.
 */
- (NSDictionary *)batchCachedObjectsForKeys:(NSArray *)keys;

/*! Retrieves first found object for the given keys.
 @param key The unique key.
 @param completion Completion block.
 */
- (void)firstCachedObjectForKeys:(NSArray *)keys completion:(void (^)(id object, NSString *key))completion;

@end
