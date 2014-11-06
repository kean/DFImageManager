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

#import "DFCachePrivate.h"
#import "DFDiskCache.h"

@implementation DFDiskCache

- (id)initWithPath:(NSString *)path error:(NSError *__autoreleasing *)error {
    if (self = [super initWithPath:path error:error]) {
        _capacity = 1024 * 1024 * 100; // 100 Mb
        _cleanupRate = 0.5f;
    }
    return self;
}

- (id)initWithName:(NSString *)name {
    NSString *directoryPath = [[DFDiskCache cachesDirectoryPath] stringByAppendingPathComponent:name];
    return [self initWithPath:directoryPath error:nil];
}

- (void)cleanup {
    if (_capacity == DFDiskCacheCapacityUnlimited) {
        return;
    }
    NSArray *resourceKeys = @[NSURLContentAccessDateKey, NSURLFileAllocatedSizeKey];
    NSArray *contents = [self contentsWithResourceKeys:resourceKeys];
    NSMutableDictionary *fileAttributes = [NSMutableDictionary dictionary];
    _dwarf_cache_bytes contentsSize = 0;
    for (NSURL *fileURL in contents) {
        NSDictionary *resourceValues = [fileURL resourceValuesForKeys:resourceKeys error:NULL];
        if (resourceValues) {
            fileAttributes[fileURL] = resourceValues;
            NSNumber *fileSize = resourceValues[NSURLFileAllocatedSizeKey];
            contentsSize += [fileSize unsignedLongLongValue];
        }
    }
    if (contentsSize < _capacity) {
        return;
    }
    const _dwarf_cache_bytes desiredSize = _capacity * _cleanupRate;
    NSArray *sortedFiles = [fileAttributes keysSortedByValueWithOptions:NSSortConcurrent usingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1[NSURLContentAccessDateKey] compare:obj2[NSURLContentAccessDateKey]];
    }];
    for (NSURL *fileURL in sortedFiles) {
        if (contentsSize < desiredSize) {
            break;
        }
        if ([[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil]) {
            NSNumber *fileSize = fileAttributes[fileURL][NSURLFileAllocatedSizeKey];
            contentsSize -= [fileSize unsignedLongLongValue];
        }
    }
}

+ (NSString *)cachesDirectoryPath {
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
}

#pragma mark - Miscellaneous

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@ %p> { capacity: %@; usage: %@; files: %lu }", [self class], self, _dwarf_bytes_to_str(self.capacity), _dwarf_bytes_to_str(self.contentsSize), (unsigned long)[self contentsWithResourceKeys:nil].count];
}

@end
