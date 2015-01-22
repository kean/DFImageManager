// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).
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

#import "DFImageManaging.h"
#import <Foundation/Foundation.h>

@class DFImageManagerConfiguration;


@interface DFImageManager : NSObject <DFImageManagingCore>

/*! A copy of the configuration object for this manager (read only). Changing mutable values within the configuration object has no effect on the current manager.
 */
@property (nonatomic, copy, readonly) DFImageManagerConfiguration *configuration;

/*! Creates image manager with a specified configuration.
 @param configuration A configuration object that specifies certain behaviors, such as fetching, processing, caching and more. Manager copies the configuration object.
 */
- (instancetype)initWithConfiguration:(DFImageManagerConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

#pragma mark Dependency Injectors

/*! Returns the iamge manager instancse shared by all clients of the current process. Unless set expilictly through a call to +setSharedManager: method, this method returns image manager created by +defaultManager method.
 */
+ (id<DFImageManaging>)sharedManager;

/*! Sets the image manager instance shared by all clients of the current process.
 */
+ (void)setSharedManager:(id<DFImageManaging>)manager;

@end


@interface DFImageManager (Convenience) <DFImageManaging>

@end


@interface DFImageManager (DefaultManager)

/*! Creates composite image manager that containts image managers with all built-in fetchers.
 */
+ (id<DFImageManaging>)defaultManager;

@end
