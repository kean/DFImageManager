# About DFCache 
[![Build Status](https://travis-ci.org/kean/DFCache.svg?branch=master)](https://travis-ci.org/kean/DFCache)

DFCache is an iOS and OS X library that provides composite in-memory and on-disk cache with LRU cleanup. It is implemented as a set of reusable classes and protocols with concise and extensible API.

### Key Features
 - Thoroughly tested and well-documented.
 - LRU cleanup (discards least recently used items first).
 - Metadata implemented on top on UNIX extended file attributes.
 - Builtin support for objects conforming to `<NSCoding>` protocol. Can be easily extended to support more protocols and classes.
 - First class `UIImage` support including background image decompression.
 - Batch methods to retrieve cached entries.

### Requirements
- iOS 6.0 or OS X 10.8

### NSCache on iOS 7.0
`NSCache` auto-removal policies have change with the release of iOS 7.0. Make sure that you use reasonable total cost limit or count limit. Or else `NSCache` won't be able to evict memory properly. Typically, the obvious cost is the size of the object in bytes. Keep in mind that `DFCache` automatically removes all object from memory cache on memory warning for you.

# Usage

### DFCache

#### Store, retrieve and remove object
```objective-c
DFCache *cache = [[DFCache alloc] initWithName:@"image_cache"];
NSString *key = @"http://..."; // Key can by any arbitrary string.
UIImage *image = ...; // Instead of UIImage you can use the same API for objects conforming to NSCoding protocol

// Store image
[cache storeObject:image forKey:key];
// [cache storeObject:image forKey:key data:data]; - you can store original image data

// Retrieve decompressed image
[cache cachedObjectForKey:key completion:^(id object) {
    // All disk IO operations are run on serial dispatch queue
    // which guarantees that the object is retrieved successfully.
    NSLog(@"Did retrieve cached object %@", object);
}];

[cache removeObjectForKey:key];
```

#### Set and read metadata
```objective-c
DFCache *cache = [[DFCache alloc] initWithName:@"sample_cache"];
NSDictionary *object = @{ @"key" : @"value" };
[cache storeObject:object forKey:@"key"];
[cache setMetadata:@{ @"revalidation_date" : [NSDate date] } forKey:@"key"];
NSDictionary *metadata = [cache metadataForKey:@"key"];
```

#### Value transformer and JSON

```objective-c
// Store JSON using builtin JSON serializer
id JSON = ...; // Any JSON object
[cache storeObject:JSON forKey:@"key" valueTransformer:[DFValueTransformerJSON new]];

// Value transformer is automatically associated with data into disk cache so there is no need to specify it when retrieving objects
id cachedJSON = [cache cachedObjectForKey:@"key"];
```

### DFCache (DFCacheExtended)

#### Retrieve batch of objects
```objective-c
DFCache *cache = ...;
[cache batchCachedObjectsForKeys:keys completion:^(NSDictionary *batch) {
    for (NSString *key in keys) {
        id object = batch[key];
        // Do something with an object.
    }
}];
```

### DFFileStorage

#### Write and read data
```objective-c
DFFileStorage *storage = [[DFFileStorage alloc] initWithPath:path error:nil];
[storage setData:data forKey:@"key"];
[storage dataForKey:@"key"];
```

#### Enumerate contents
```objective-c
DFFileStorage *storage = [[DFFileStorage alloc] initWithPath:path error:nil];
NSArray *resourceKeys = @[ NSURLContentModificationDateKey, NSURLFileAllocatedSizeKey ];
NSArray *contents = [storage contentsWithResourceKeys:resourceKeys];
for (NSURL *fileURL in contents) {
    // Use file URL and pre-fetched file attributes. 
}
```

### NSURL (DFExtendedFileAttributes)

#### Set and read extended file attributes
```objective-c
NSURL *fileURL = [NSURL fileURLWithPath:path];
[fileURL df_setExtendedAttributeValue:@"value" forKey:@"attr_key"];
NSString *value = [fileURL df_extendedAttributeValueForKey:@"attr_key" error:NULL];
[fileURL df_removeExtendedAttributeForKey];
```

# Classes
|Class|Description|
|---------|---------|
|[DFCache](https://github.com/kean/DFCache/blob/master/DFCache/DFCache.h)|Asynchronous composite in-memory and on-disk cache with LRU cleanup. Uses `NSCache` for in-memory caching and `DFDiskCache` for on-disk caching. Provides API for associating metadata with cache entries.|
|[\<DFValueTransforming\>](https://github.com/kean/DFCache/blob/master/DFCache/Transforming/DFValueTransformer.h)|Protocol for describing a way of encoding and decoding objects.|
|[\<DFValueTransformerFactory\>](https://github.com/kean/DFCache/blob/master/DFCache/Transforming/DFValueTransformerFactory.h)|Protocol for matching objects with value transformers.|
|[DFFileStorage](https://github.com/kean/DFCache/blob/master/DFCache/Key-Value%20File%20Storage/DFFileStorage.h)|Key-value file storage.|
|[DFDiskCache](https://github.com/kean/DFCache/blob/master/DFCache/DFDiskCache.h)|Disk cache extends file storage functionality by providing LRU (least recently used) cleanup.|
|[NSURL (DFExtendedFileAttributes)](https://github.com/kean/DFCache/blob/master/DFCache/Extended%20File%20Attributes/NSURL%2BDFExtendedFileAttributes.h)|Objective-c wrapper of UNIX extended file attributes. Extended attributes extend the basic attributes associated with files and directories in the file system. They are stored as name:data pairs associated with file system objects (files, directories, symlinks, etc). See setxattr(2).|
|[DFCache (DFCacheExtended)](https://github.com/kean/DFCache/blob/master/DFCache/DFCache%2BDFExtensions.h)|Set of methods that extend `DFCache` functionality by allowing you to retrieve cached entries in batches.|

# Installation

### Cocoapods
The recommended way to install `DFCache` is via [Cocoapods](http://cocoapods.org) package manager.
```ruby
# Podfile example
platform :ios, '6.0'
# platform :osx, '10.8'
pod 'DFCache', '~> 2.0'
```

# Migration from DFCache 1.0

`DFCache 2.0` interface is incompatible with previous versions. The main difference is a new family of protocols (`<DFValueTransforming>`, `<DFValueTransformerFactory>`) that is used instead of the encoding, decoding and cost calculating blocks from the previous versions. 

Persistence implementation is largely the same except for a new extended file attribute that is used to associate value transformers with data. Objects encoded by the previous versions of `DFCache` do not have this attribute, which means that you won't be able to retrieve them using new  `-(id)cachedObjectForKey:(NSString *)key;` API. You should provide a value transformer instead `-(id)cachedObjectForKey:(NSString *)key valueTransformer:(id<DFValueTransforming>)valueTransformer;`.

As an alternative you can start using new API and simply ignore old files. They will be ignored and deleted automatically by builtin LRU cleanup.

# Contacts
[Alexander Grebenyuk](https://github.com/kean)

# License
DFCache is available under the MIT license. See the LICENSE file for more info.
