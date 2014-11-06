# About DFCache 
[![Build Status](https://travis-ci.org/kean/DFCache.svg?branch=master)](https://travis-ci.org/kean/DFCache)

DFCache is an iOS and OS X library that provides composite in-memory and on-disk cache with LRU cleanup. It is implemented as a set of reusable classes with concise and extensible API.



### Key Features
 - Thoroughly tested and well-documented.
 - LRU cleanup (discards least recently used items first).
 - Metadata implemented on top on UNIX extended file attributes.
 - Encoding and decoding implemented using blocks. Store any kind of Objective-C objects or manipulate data directly.
 - First class `UIImage` support including background image decompression.
 - Batch methods to retrieve cached entries.

### Requirements
- iOS 6.0 or OS X 10.8

### NSCache on iOS 7.0
`NSCache` auto-removal policies have change with the release of iOS 7.0. Make sure that you use reasonable total cost limit or count limit. Or else `NSCache` won't be able to evict memory properly. Typically, the obvious cost is the size of the object in bytes. Keep in mind that `DFCache` automatically removes all object from memory cache on memory warning for you.

# Classes
|Class|Description|
|---------|---------|
|[DFCache](https://github.com/kean/DFCache/blob/master/DFCache/DFCache.h)|Asynchronous composite in-memory and on-disk cache with LRU cleanup. Uses `NSCache` for in-memory caching and `DFDiskCache` for on-disk caching. Provides API for associating metadata with cache entries.|
|[DFCache (DFImage)](https://github.com/kean/DFCache/blob/master/DFCache/DFCache%2BDFImage.h)|First class UIImage support including background image decompression.|
|[DFCache (DFCacheExtended)](https://github.com/kean/DFCache/blob/master/DFCache/DFCache%2BDFExtensions.h)|Set of methods that extend `DFCache` functionality by allowing you to retrieve cached entries in batches.|
|[DFFileStorage](https://github.com/kean/DFCache/blob/master/DFCache/Key-Value%20File%20Storage/DFFileStorage.h)|Key-value file storage.|
|[DFDiskCache](https://github.com/kean/DFCache/blob/master/DFCache/DFDiskCache.h)|Disk cache extends file storage functionality by providing LRU (least recently used) cleanup.|
|[NSURL (DFExtendedFileAttributes)](https://github.com/kean/DFCache/blob/master/DFCache/Extended%20File%20Attributes/NSURL%2BDFExtendedFileAttributes.h)|Objective-c wrapper of UNIX extended file attributes. Extended attributes extend the basic attributes associated with files and directories in the file system. They are stored as name:data pairs associated with file system objects (files, directories, symlinks, etc). See setxattr(2).|

# Usage

### DFCache

#### Store, retrieve and remove JSON
```objective-c
DFCache *cache = [[DFCache alloc] initWithName:@"sample_cache"];
NSString *key = @"http://..."; // Key can by any arbitrary string.
NSData *data = ...; // Original JSON data.
id JSON = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];

// Store object into memory cache and data into disk cache.
[cache storeObject:JSON data:data forKey:key];

// Retrieve object be decoding it using built-in DFCacheDecodeJSON block.
[cache cachedObjectForKey:key decode:DFCacheDecodeJSON completion:^(id object) {
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
[cache storeObject:object encode:DFCacheDecodeNSCoding forKey:@"key"];
[cache setMetadata:@{ @"revalidation_date" : [NSDate date] } forKey:@"key"];
NSDictionary *metadata = [cache metadataForKey:@"key"];
```

### DFCache (DFCacheExtended)

#### Retrieve batch of objects
```objective-c
DFCache *cache = ...;
[cache batchCachedObjectsForKeys:keys decode:DFCacheDecodeNSCoding cost:nil completion:^(NSDictionary *batch) {
    for (NSString *key in keys) {
        id object = batch[key];
        // Do something with object.
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

#### Set and read extended file attribute.
```objective-c
NSURL *fileURL = [NSURL fileURLWithPath:path];
[fileURL setExtendedAttributeValue:@"value" forKey:@"attr_key"];
NSString *value = [fileURL extendedAttributeValueForKey:@"attr_key" error:NULL];
```

# Installation

### Cocoapods
The recommended way to install `DFCache` is via [Cocoapods](http://cocoapods.org) package manager.
```ruby
# Podfile example
platform :ios, '6.0'
# platform :osx, '10.8'
pod 'DFCache', '~> 1.0'
```

# Contacts
[Alexander Grebenyuk](https://github.com/kean)

# License
DFCache is available under the MIT license. See the LICENSE file for more info.
