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

#import "DFCollectionViewPreheatingController.h"


@implementation DFCollectionViewPreheatingController {
    NSMutableSet *_preheatIndexPaths;
}

- (void)dealloc {
    [_collectionView removeObserver:self forKeyPath:@"contentOffset"];
}

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView {
    if (self = [super init]) {
        NSParameterAssert(collectionView);
        _collectionView = collectionView;
        [_collectionView addObserver:self forKeyPath:@"contentOffset" options:kNilOptions context:NULL];
        
        _preheatIndexPaths = [NSMutableSet new];
        _preheatRect = CGRectZero;
        _preheatRectRatio = 2.f;
        _preheatRectRevalidationRatio = 0.33f;
    }
    return self;
}

- (void)resetPreheatRect {
    [self.delegate collectionViewPreheatingController:self didUpdatePreheatRectWithAddedIndexPaths:nil removedIndexPaths:[_preheatIndexPaths allObjects]];
    [self _resetPreheatRect];
}

- (void)updatePreheatRect {
    [self _resetPreheatRect];
    [self _updatePreheatRect];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.collectionView) {
        [self _updatePreheatRect];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)_resetPreheatRect {
    [_preheatIndexPaths removeAllObjects];
    _preheatRect = CGRectZero;
}

- (void)_updatePreheatRect {
    NSAssert([self.collectionView.collectionViewLayout isKindOfClass:[UICollectionViewFlowLayout class]], @"Not suported collection view layout");
    BOOL isVertical = ((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).scrollDirection == UICollectionViewScrollDirectionVertical;
    
    // UIScrollView bounds works differently from UIView bounds. It adds the contentOffset to the rect.
    CGRect preheatRect = self.collectionView.bounds;
    CGFloat delta;
    BOOL isScrolledSignificantly;
    
    if (isVertical) {
        CGFloat inset = preheatRect.size.height - preheatRect.size.height * _preheatRectRatio;
        preheatRect = CGRectInset(preheatRect, 0.f, inset / 2.f);
        delta = CGRectGetMidY(preheatRect) - CGRectGetMidY(_preheatRect);
        isScrolledSignificantly = fabs(delta) > CGRectGetHeight(self.collectionView.bounds) * _preheatRectRevalidationRatio;
    } else {
        CGFloat inset = preheatRect.size.width - preheatRect.size.width * _preheatRectRatio;
        preheatRect = CGRectInset(preheatRect, inset / 2.f, 0.f);
        delta = CGRectGetMidX(preheatRect) - CGRectGetMidX(_preheatRect);
        isScrolledSignificantly = fabs(delta) > CGRectGetWidth(self.collectionView.bounds) * _preheatRectRevalidationRatio;
    }
    
    if (isScrolledSignificantly || CGRectEqualToRect(_preheatRect, CGRectZero)) {
        NSMutableSet *newIndexPaths = [NSMutableSet setWithArray:[self _indexPathsForElementsInRect:preheatRect]];
        
        NSMutableSet *oldIndexPaths = [NSMutableSet setWithSet:self.preheatIndexPaths];
        
        NSMutableSet *addedIndexPaths = [newIndexPaths mutableCopy];
        [addedIndexPaths minusSet:oldIndexPaths];
        
        NSMutableSet *removedIndexPaths = [oldIndexPaths mutableCopy];
        [removedIndexPaths minusSet:newIndexPaths];
        
        _preheatIndexPaths = newIndexPaths;

        // Sort added index paths.
        BOOL ascending = delta > 0.f || CGRectEqualToRect(_preheatRect, CGRectZero);
        NSArray *sortedAddedIndexPaths = [[addedIndexPaths allObjects] sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"section" ascending:ascending], [NSSortDescriptor sortDescriptorWithKey:@"item" ascending:ascending] ]];
        
        _preheatRect = preheatRect;
        
        [self.delegate collectionViewPreheatingController:self didUpdatePreheatRectWithAddedIndexPaths:sortedAddedIndexPaths removedIndexPaths:[removedIndexPaths allObjects]];
    }
}

- (NSArray *)_indexPathsForElementsInRect:(CGRect)rect {
    NSArray *allLayoutAttributes = [self.collectionView.collectionViewLayout layoutAttributesForElementsInRect:rect];
    NSMutableArray *indexPaths = [NSMutableArray new];
    for (UICollectionViewLayoutAttributes *attributes in allLayoutAttributes) {
        if (attributes.representedElementCategory == UICollectionElementCategoryCell) {
            [indexPaths addObject:attributes.indexPath];
        }
    }
    return indexPaths;
}

@end
