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

/*! Key-value file storage.
 @discussion File storage doesn't limit your access to the underlying storage directory.
 */
@interface DFFileStorage : NSObject

/*! Initializes and returns storage with the given directory path.
 @param path Storage directory path.
 @param error A pointer to an error object. If an error occurs while creating storage directory, the pointer is set to the file system error (see NSFileManager). You may specify nil for this parameter if you do not want the error information.
 */
- (id)initWithPath:(NSString *)path error:(NSError *__autoreleasing *)error;

/*! Returns storage directory path.
 */
@property (nonatomic, readonly) NSString *path;

/*! Returns the contents of the file for the given key.
 */
- (NSData *)dataForKey:(NSString *)key;

/*! Creates a file with the specified content for the given key.
 */
- (void)setData:(NSData *)data forKey:(NSString *)key;

/*! Removes the file for the given key.
 */
- (void)removeDataForKey:(NSString *)key;

/*! Removes all storage contents.
 */
- (void)removeAllData;

/*! Returns a boolean value that indicates whether a file exists for the given key.
 */
- (BOOL)containsDataForKey:(NSString *)key;

/*! Returns file name for the given key.
 */
- (NSString *)filenameForKey:(NSString *)key;

/*! Returns file path for the given key.
 */
- (NSString *)pathForKey:(NSString *)key;

/* Returns file URL for the given key.
 */
- (NSURL *)URLForKey:(NSString *)key;

/*! Returns the current size of the receiver contents, in bytes.
 */
- (unsigned long long)contentsSize;

/*! Returns URLs of items contained into storage.
 @param keys An array of keys that identify the file properties that you want pre-fetched for each item in the storage. For each returned URL, the specified properties are fetched and cached in the NSURL object. For a list of keys you can specify, see Common File System Resource Keys.
 */
- (NSArray *)contentsWithResourceKeys:(NSArray *)keys;

@end
