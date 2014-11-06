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

/*! Extended attributes extend the basic attributes associated with files and directories in the file system. They are stored as name:data pairs associated with file system objects (files, directories, symlinks, etc). See setxattr(2).
 */
@interface NSURL (DFExtendedFileAttributes)

/*! Sets encoded attribute value for the given key.
 @return 0 on success or error code on failure. For the list of errors see setxattr(2).
 */
- (int)setExtendedAttributeValue:(id<NSCoding>)value forKey:(NSString *)key;

/*! Associates key and data together as an attribute of the file.
 @discussion Follows symbolic links. Creates attribute if it doesn't exist. Replaces attribute if it already exists.
 @param data Attribute data.
 @param options For the list of available options see setxattr(2).
 @return 0 on success or error code on failure. For the list of errors see setxattr(2).
 */
- (int)setExtendedAttributeData:(NSData *)data forKey:(NSString *)key options:(int)options;

/*! Retrieves decoded attribute value for given key.
 @param error Error code is set on failure. You may specify NULL for this parameter. For the list of errors see getxattr(2).
 @throws Raises an NSInvalidArgumentException if data is not a valid archive.
 */
- (id)extendedAttributeValueForKey:(NSString *)key error:(int *)error;

/*! Retrieves data from the extended attribute identified by the given key.
 @param error Error code is set on failure. You may specify NULL for this parameter. For the list of errors see getxattr(2).
 @param options For the list of available options see getxattr(2).
 */
- (NSData *)extendedAttributeDataForKey:(NSString *)key error:(int *)error options:(int)options;

/*! Removes the extended attribute for the given key.
 @return 0 on success or error code on failure. For the list of errors see removexattr(2).
 */
- (int)removeExtendedAttributeForKey:(NSString *)key;

/*! Removes the extended attribute for the given key.
 @param options For the list of available options see removexattr(2).
 @return 0 on success or error code on failure. For the list of errors see removexattr(2).
 */
- (int)removeExtendedAttributeForKey:(NSString *)key options:(int)options;

/*! Retrieves a list of names of extended attributes.
 @param error Error code is set on failure. You may specify NULL for this parameter. For the list of errors see listxattr(2).
 */
- (NSArray *)extendedAttributesList:(int *)error;

/*! Retrieves a list of names of extended attributes.
 @param error Error code is set on failure. You may specify NULL for this parameter. For the list of errors see listxattr(2).
 @param options For the list of available options see listxattr(2).
 */
- (NSArray *)extendedAttributesList:(int *)error options:(int)options;

@end
