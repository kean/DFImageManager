// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageManaging.h"
#import <Foundation/Foundation.h>

/*! The DFCompositeImageManager is a dynamic dispatcher that constructs a tree of responsibility from multiple image managers and dynamically dispatch requests between them. 
 @note Each image manager defines which image requests it can handle. The DFCompositeImageManager dispatches image requests starting with the first image manager in a chain. If the image manager can't handle the request it is passes to the next image manager in the chain and so on.
 @note The DFCompositeImageManager also conforms to DFImageManaging protocol so that individual managers and compositions can be treated uniformly.
 */
@interface DFCompositeImageManager : NSObject <DFImageManaging>

/*! Initializes composite image manager with an array of image managers.
 */
- (nonnull instancetype)initWithImageManagers:(nonnull NSArray<id<DFImageManaging>> *)imageManagers;

/*! Adds image manager to the end of the chain.
 */
- (void)addImageManager:(nonnull id<DFImageManaging>)imageManager;

/*! Removes image manager from the chain.
 */
- (void)removeImageManager:(nonnull id<DFImageManaging>)imageManager;

@end
