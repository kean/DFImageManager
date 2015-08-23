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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class DFCollectionViewPreheatingController;

NS_ASSUME_NONNULL_BEGIN

@protocol DFCollectionViewPreheatingControllerDelegate <NSObject>

/*! Tells the delegate that the preheat window changed significantly.
 @param addedIndexPaths Index paths for items added to the preheat window. Index paths are sorted so that the items closest to the previous preheat window are in the beginning of the array; no matter whether user is scrolling forward of backward.
 @param removedIndexPaths Index paths for items there were removed from the preheat window.
 */
- (void)collectionViewPreheatingController:(DFCollectionViewPreheatingController *)controller didUpdatePreheatRectWithAddedIndexPaths:(NSArray *)addedIndexPaths removedIndexPaths:(NSArray *)removedIndexPaths;

@end


/*! Detects changes in collection view content offset and updates preheat window. The preheat window is a rect inside the collection view content which is bigger than the viewport of the collection view. Provides delegate with index paths for added and removed cells when the preheat window changes significantly.
 @note Supports UICollectionViewFlowLayout and it's subclasses with either vertical or horizontal scroll direction.
 */
@interface DFCollectionViewPreheatingController : NSObject

/*! The collection view the receiver was initializer with.
 */
@property (nonatomic, readonly) UICollectionView *collectionView;

/*! The delegate object for the receiver.
 */
@property (nullable, nonatomic, weak) id<DFCollectionViewPreheatingControllerDelegate> delegate;

/*! The proportion of the collection view bounds (either width or height depending on the scroll direction) that is used as a preheat window. Default value is 2.0.
 */
@property (nonatomic) CGFloat preheatRectRatio;

/*! Determines the offset of the preheat from the center of the collection view visible area. The default value is 0.33.
 @note The value of this property is the ratio of the collection view height for UICollectionViewScrollDirectionVertical and width for UICollectionViewScrollDirectionHorizontal.
 */
@property (nonatomic) CGFloat preheatRectOffset;

/*! Determines how far the user needs to scroll from the point where the current preheat rect was set to refresh it. Default value is 0.33.
 @note The value of this property is the ratio of the collection view height for UICollectionViewScrollDirectionVertical and width for UICollectionViewScrollDirectionHorizontal. 
 */
@property (nonatomic) CGFloat preheatRectUpdateRatio;

/*! Returns current preheat rect.
 */
@property (nonatomic, readonly) CGRect preheatRect;

/*! Returns current preheat indexes.
 */
@property (nonatomic, readonly) NSSet *preheatIndexPaths;

/*! Initializes preheating controller with a collection view.
 @param collectionView Collection view.
 */
- (instancetype)initWithCollectionView:(UICollectionView *)collectionView NS_DESIGNATED_INITIALIZER;

/*! Unavailable initializer, please use designated initializer.
 */
- (nullable instancetype)init NS_UNAVAILABLE;

/*! Resets preheat rect and calls delegate with removed index paths.
 */
- (void)resetPreheatRect;

/*! Updates current preheat rect and all items contained in it.
 */
- (void)updatePreheatRect;

@end

NS_ASSUME_NONNULL_END
