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

/*! The DFCompositeImageManager is a dynamic dispatcher that constructs a chain of responsibility from multiple image manager. Each image manager added to the composite defines which image requests it can handle. The DFCompositeImageManager dispatches image requests starting with the first image manager in a chain. If the image manager can't handle the request it is passes to the next image manager in the chain and so on.
 @note Composite image manager itself conforms to DFImageManaging protocol and can be added to other composite image managers, forming a tree structure.
 */
@interface DFCompositeImageManager : NSObject <DFImageManaging>

/*! Initializes composite image manager with an array of image managers.
 */
- (nonnull instancetype)initWithImageManagers:(nonnull NSArray /* id<DFImageManaging> */ *)imageManagers;

/*! Adds image manager to the end of the chain.
 */
- (void)addImageManager:(nonnull id<DFImageManaging>)imageManager;

/*! Adds image managers to the end of the chain.
 */
- (void)addImageManagers:(nonnull NSArray /* <DFImageManaging> */ *)imageManagers;

/*! Removes image manager from the chain.
 */
- (void)removeImageManager:(nonnull id<DFImageManaging>)imageManager;

/*! Removes image managers from the chain.
 */
- (void)removeImageManagers:(nonnull NSArray /* <DFImageManaging> */ *)imageManagers;

@end
