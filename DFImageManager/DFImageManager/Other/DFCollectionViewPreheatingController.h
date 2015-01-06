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


@protocol DFCollectionViewPreheatingControllerDelegate <NSObject>

- (void)collectionViewPreheatingController:(DFCollectionViewPreheatingController *)controller didUpdatePreheatRectWithAddedIndexPaths:(NSArray *)addedIndexPaths removedIndexPaths:(NSArray *)removedIndexPaths;

@end


@interface DFCollectionViewPreheatingController : NSObject

@property (nonatomic, readonly) UICollectionView *collectionView;

@property (nonatomic, weak) id<DFCollectionViewPreheatingControllerDelegate> delegate;

/*! The proportion of the collection view bounds (either width or height depending on the scroll direction) that is used as a preheat window. Default value is 2.0.
 */
@property (nonatomic) CGFloat preheatRectRatio;

/*! How far the user need to scroll from the current preheat rect to revalidate it. Default value is 0.33.
 */
@property (nonatomic) CGFloat preheatRectRevalidationRatio;

@property (nonatomic, readonly) CGRect preheatRect;
@property (nonatomic, readonly) NSSet *preheatIndexPaths;

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView;

- (void)resetPreheatRect;
- (void)updatePreheatRect;

@end
