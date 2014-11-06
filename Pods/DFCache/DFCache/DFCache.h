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

#import "DFCacheBlocks.h"
#import "DFDiskCache.h"

/*! Extended attribute name used to store metadata (see NSURL+DFExtendedFileAttributes).
 */
extern NSString *const DFCacheAttributeMetadataKey;

/* DFCache key features:
 
 - Concise, extensible and well-documented API.
 - Thoroughly tested. Written for and used heavily in the iOS application with more than half a million active users.
 - LRU cleanup (discards least recently used items first).
 - Metadata implemented on top on UNIX extended file attributes.
 - Encoding and decoding implemented using blocks. Store any kind of Objective-C objects or manipulate data directly.
 - First class UIImage support including background image decompression.
 - Batch methods to retrieve cached entries.
 */

/*! Asynchronous composite in-memory and on-disk cache with LRU cleanup.
 @discussion Uses NSCache for in-memory caching and DFDiskCache for on-disk caching. Provides API for associating metadata with cache entries. Parts of the DFCache API (like first class UIImage support and batch read methods) are available through the categories. For more info see DFCacheExtended and DFImage categories.
 @note All disk IO operations (including operations that associate metadata with cache entries) are run on a serial dispatch queue. If you store the object using DFCache asynchronous API and then immediately try to retrieve it then you are guaranteed to get the object back.
 @note Default disk capacity is 100 Mb. Disk cleanup is implemented using LRU algorithm, the least recently used items are discarded first. Disk cleanup is automatically scheduled to run repeatedly.
 @note NSCache auto-removal policies have change with the release of iOS 7.0. Make sure that you use reasonable total cost limit or count limit. Or else NSCache won't be able to evict memory properly. Typically, the obvious cost is the size of the object in bytes. Keep in mind that DFCache automatically removes all object from memory cache on memory warning for you.
 */
@interface DFCache : NSObject

/*! Initializes and returns cache with provided disk and memory cache. Designated initializer.
 @param diskCache Disk cache. Raises NSInvalidArgumentException if disk cache is nil.
 @param memoryCache Memory cache. Pass nil to disable in-memory cache.
 */
- (id)initWithDiskCache:(DFDiskCache *)diskCache memoryCache:(NSCache *)memoryCache;

/*! Initializes cache by creating DFDiskCache instance with a given name and calling designated initializer.
 @param name Name used to initialize disk cache. Raises NSInvalidArgumentException if name length is 0.
 @param memoryCache Memory cache. Pass nil to disable in-memory cache.
 */
- (id)initWithName:(NSString *)name memoryCache:(NSCache *)memoryCache;

/*! Initializes cache by creating DFDiskCache instance with a given name and NSCache instance and calling designated initializer.
 @param name Name used to initialize disk cache. Raises NSInvalidArgumentException if name length is 0.
 */
- (id)initWithName:(NSString *)name;

/*! Returns disk cache used by receiver.
 */
@property (nonatomic, readonly) DFDiskCache *diskCache;

/*! Returns memory cache used by receiver. Memory cache might be nil.
 */
@property (nonatomic, readonly) NSCache *memoryCache;

/*! Serial dispatch queue used for all disk IO operations. If you store the object using DFCache asynchronous API and then immediately try to retrieve it then you are guaranteed to get the object back.
 */
@property (nonatomic) dispatch_queue_t ioQueue;

/*! Concurrent dispatch queue used for dispatching blocks that decode cached data.
 */
@property (nonatomic) dispatch_queue_t processingQueue;

#pragma mark - Read (Asynchronous)

/*! Reads object from either in-memory or on-disk cache. Refreshes object in memory cache it it was retrieved from disk. Computes the object cost in memory cache using given DFCacheCostBlock.
 @param key The unique key.
 @param decode Decoding block that returns object from given data.
 @param cost Cost block returning cost for memory cache. Might be nil.
 @param completion Completion block.
 */
- (void)cachedObjectForKey:(NSString *)key
                    decode:(DFCacheDecodeBlock)decode
                      cost:(DFCacheCostBlock)cost
                completion:(void (^)(id object))completion;

/*! Reads object from either in-memory or on-disk cache. Refreshes object in memory cache it it was retrieved from disk.
 @param key The unique key.
 @param decode Decoding block that returns object from given data.
 @param completion Completion block.
 */
- (void)cachedObjectForKey:(NSString *)key
                    decode:(DFCacheDecodeBlock)decode
                completion:(void (^)(id object))completion;

#pragma mark - Read (Synchronous)

/*! Returns object from either in-memory or on-disk cache synchronously. Refreshes object in memory cache it it was retrieved from disk.
 @param key The unique key.
 @param decode Decoding block that returns object from given data. Might be nil.
 @param cost Cost block returning cost for memory cache.
 */
- (id)cachedObjectForKey:(NSString *)key decode:(DFCacheDecodeBlock)decode cost:(DFCacheCostBlock)cost;

/*! Returns object from either in-memory or on-disk cache synchronously. Refreshes object in memory cache it it was retrieved from disk.
 @param key The unique key.
 @param decode Decoding block that returns object from given data.
 */
- (id)cachedObjectForKey:(NSString *)key decode:(DFCacheDecodeBlock)decode;

#pragma mark - Write

/*! Stores object into memory cache. Stores data into disk cache.
 @param object The object to store into memory cache.
 @param data Data to store into disk cache.
 @param key The unique key.
 @param cost The cost with which to associate the object (used by memory cache). Typically, the obvious cost is the size of the object in bytes.
 */
- (void)storeObject:(id)object
               data:(NSData *)data
             forKey:(NSString *)key
               cost:(NSUInteger)cost;

/*! Stores object into memory cache. Stores data into disk cache.
 @param object The object to store into memory cache.
 @param key The unique key.
 @param data Data to store into disk cache.
 */
- (void)storeObject:(id)object
               data:(NSData *)data
             forKey:(NSString *)key;

/*! Stores object into memory cache. Stores data representation provided by the DFCacheEncodeBlock into disk cache.
 @param object The object to store into memory cache.
 @param encode Block that returns data representation of the object.
 @param key The unique key.
 @param cost The cost with which to associate the object (used by memory cache). Typically, the obvious cost is the size of the object in bytes.
 */
- (void)storeObject:(id)object
             encode:(DFCacheEncodeBlock)encode
             forKey:(NSString *)key
               cost:(NSUInteger)cost;

/*! Stores object into memory cache. Stores data representation provided by the DFCacheEncodeBlock into disk cache.
 @param object The object to store into memory cache.
 @param encode Block that returns data representation of the object.
 @param key The unique key.
 */
- (void)storeObject:(id)object
             encode:(DFCacheEncodeBlock)encode
             forKey:(NSString *)key;

/*! Stores object into memory cache. Calculate cost using provided DFCacheCostBlock (if block is not nil).
 @param object The object to store into memory cache.
 @param key The unique key.
 @param cost The cost with which to associate the object (used by memory cache).
 */
- (void)storeObject:(id)object
             forKey:(NSString *)key
               cost:(DFCacheCostBlock)cost;

#pragma mark - Remove

/*! Removes objects from both disk and memory cache. Metadata is also removed.
 @param keys Array of strings.
 */
- (void)removeObjectsForKeys:(NSArray *)keys;

/*! Removes object from both disk and memory cache. Metadata is also removed.
 @param key The unique key.
 */
- (void)removeObjectForKey:(NSString *)key;

/*! Removes all objects both disk and memory cache. Metadata is also removed.
 */
- (void)removeAllObjects;

#pragma mark - Metadata

/*! Returns copy of metadata for provided key.
 @param key The unique key.
 @return Copy of metadata for key.
 */
- (NSDictionary *)metadataForKey:(NSString *)key;

/*! Sets metadata for provided key. 
 @warning Method will have no effect if there is no entry under the given key.
 @param metadata Dictionary with metadata.
 @param key The unique key.
 */
- (void)setMetadata:(NSDictionary *)metadata forKey:(NSString *)key;

/*! Sets metadata values for provided keys.
 @warning Method will have no effect if there is no entry under the given key.
 @param keyedValues Dictionary with metadata.
 @param key The unique key.
 */
- (void)setMetadataValues:(NSDictionary *)keyedValues forKey:(NSString *)key;

/*! Removes metadata for key.
 @param key The unique key.
 */
- (void)removeMetadataForKey:(NSString *)key;

#pragma mark - Cleanup

/*! Sets cleanup time interval and schedules cleanup timer with the given time interval. 
 @discussion Cleanup timer is scheduled only if automatic cleanup is enabled. Default value is 60 seconds.
 */
- (void)setCleanupTimerInterval:(NSTimeInterval)timeInterval;

/*! Enables or disables cleanup timer. Cleanup timer is enabled by default.
 */
- (void)setCleanupTimerEnabled:(BOOL)enabled;

/*! Cleanup disk cache asynchronously. For more info see DFDiskCache - (void)cleanup.
 */
- (void)cleanupDiskCache;

#pragma mark - Data

/*! Retrieves data from disk cache.
 @param key The unique key.
 @param completion Completion block.
 */
- (void)cachedDataForKey:(NSString *)key completion:(void (^)(NSData *data))completion;

/*! Reads data from disk cache synchronously.
 @param key The unique key.
 */
- (NSData *)cachedDataForKey:(NSString *)key;

/*! Stores data into disk cache asynchronously.
 @param data Data to be stored into disk cache.
 @param key The unique key.
 */
- (void)storeData:(NSData *)data forKey:(NSString *)key;

#pragma mark - Deprecated

/*! Deprecated method. Use -(void)storeObject:data:forKey:cost instead;
 @warning Deprecated in DFCache 1.3.0.
 */
- (void)storeObject:(id)object forKey:(NSString *)key cost:(NSUInteger)cost data:(NSData *)data DEPRECATED_ATTRIBUTE;

/*! Deprecated method. Use -(void)storeObject:encode:forKey:cost instead;
 @warning Deprecated in DFCache 1.3.0.
 */
- (void)storeObject:(id)object forKey:(NSString *)key cost:(NSUInteger)cost encode:(DFCacheEncodeBlock)encode DEPRECATED_ATTRIBUTE;

@end
