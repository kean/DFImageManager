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

#import "DFDiskCache.h"
#import "DFValueTransformer.h"
#import "DFValueTransformerFactory.h"

/*! Extended attribute name used to store metadata (see NSURL+DFExtendedFileAttributes).
 */
extern NSString *const DFCacheAttributeMetadataKey;


/* DFCache key features:
 
 - Concise, extensible and well-documented API.
 - Thoroughly tested. Written for and used heavily in the iOS application with more than half a million active users.
 - LRU cleanup (discards least recently used items first).
 - Metadata implemented on top on UNIX extended file attributes.
 - First class UIImage support including background image decompression.
 - Builtin support for objects conforming to <NSCoding> protocol. Can be extended to support more protocols and classes.
 - Batch methods to retrieve cached entries.
 */

/*! Asynchronous composite in-memory and on-disk cache with LRU cleanup.
 @discussion Uses NSCache for in-memory caching and DFDiskCache for on-disk caching. Provides API for associating metadata with cache entries.
 @note Encoding and decoding is implemented using id<DFValueTransforming> protocol. DFCache has several builtin value transformers that support object conforming to <NSCoding> protocol and images (UIImage). Use value transformer factory (id<DFValueTransformerFactory>) to extend cache functionality.
 @note All disk IO operations (including operations that associate metadata with cache entries) are run on a serial dispatch queue. If you store the object using DFCache asynchronous API and then immediately retrieve it you are guaranteed to get the object back.
 @note Default disk capacity is 100 Mb. Disk cleanup is implemented using LRU algorithm, the least recently used items are discarded first. Disk cleanup is automatically scheduled to run repeatedly.
 @note NSCache auto-removal policies have change with the release of iOS 7.0. Make sure that you use reasonable total cost limit or count limit. Or else NSCache won't be able to evict memory properly. Typically, the obvious cost is the size of the object in bytes. Keep in mind that DFCache automatically removes all object from memory cache on memory warning for you.
 */
@interface DFCache : NSObject

/*! Initializes and returns cache with provided disk and memory cache.
 @param diskCache Disk cache. Pass nil to disable on-disk caching.
 @param memoryCache Memory cache. Pass nil to disable in-memory caching.
 */
- (instancetype)initWithDiskCache:(DFDiskCache *)diskCache memoryCache:(NSCache *)memoryCache NS_DESIGNATED_INITIALIZER;

/*! Initializes cache by creating DFDiskCache instance with a given name and calling designated initializer.
 @param name Name used to initialize disk cache. Raises NSInvalidArgumentException if name length is 0.
 @param memoryCache Memory cache. Pass nil to disable in-memory cache.
 */
- (instancetype)initWithName:(NSString *)name memoryCache:(NSCache *)memoryCache;

/*! Initializes cache by creating DFDiskCache instance with a given name and NSCache instance and calling designated initializer.
 @param name Name used to initialize disk cache. Raises NSInvalidArgumentException if name length is 0.
 */
- (instancetype)initWithName:(NSString *)name;

/*! The transformer factory used by cache. Cache is initialized with a default value transformer factory. For more info see DFValueTransformerFactory declaration.
 */
@property (nonatomic) id<DFValueTransformerFactory> valueTransfomerFactory;

/*! Returns disk cache used by receiver.
 */
@property (nonatomic, readonly) DFDiskCache *diskCache;

/*! Returns memory cache used by receiver. Memory cache might be nil.
 */
@property (nonatomic, readonly) NSCache *memoryCache;

#pragma mark - Read

/*! Reads object from either in-memory or on-disk cache. Refreshes object in memory cache it it was retrieved from disk. Uses value transformer provided by value transformer factory.
 @param key The unique key.
 @param completion Completion block.
 */
- (void)cachedObjectForKey:(NSString *)key completion:(void (^)(id object))completion;

/*! Returns object from either in-memory or on-disk cache. Refreshes object in memory cache it it was retrieved from disk. Uses value transformer provided by value transformer factory.
 @param key The unique key.
 @param completion Completion block.
 */
- (id)cachedObjectForKey:(NSString *)key;

#pragma mark - Write

/*! Stores object into memory cache. Retrieves value transformer from factory, encodes object and stores data into disk cache. Value transformer gets associated with data.
 @param object The object to store into memory cache.
 @param key The unique key.
 */
- (void)storeObject:(id)object forKey:(NSString *)key;

/*! Stores object into memory cache. Stores data into disk cache. Retrieves value transformer from factory and  associates it with data.
 @param object The object to store into memory cache.
 @param key The unique key.
 @param data Data to store into disk cache.
 */
- (void)storeObject:(id)object forKey:(NSString *)key data:(NSData *)data;

/*! Stores object into memory cache. Retrieves value transformer from factory and uses it to calculate object cost.
 @param object The object to store into memory cache.
 */
- (void)setObject:(id)object forKey:(NSString *)key;

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

@end


#if (__IPHONE_OS_VERSION_MIN_REQUIRED)
@interface DFCache (UIImage)

- (void)setAllowsImageDecompression:(BOOL)allowsImageDecompression;

@end
#endif
