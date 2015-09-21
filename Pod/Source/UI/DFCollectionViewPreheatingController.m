// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFCollectionViewPreheatingController.h"
#import "DFImageManagerDefines.h"

@implementation DFCollectionViewPreheatingController {
    NSMutableSet *_preheatIndexPaths;
    CGPoint _preheatContentOffset;
}

- (void)dealloc {
    [_collectionView removeObserver:self forKeyPath:@"contentOffset"];
}

DF_INIT_UNAVAILABLE_IMPL

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView {
    if (self = [super init]) {
        NSParameterAssert(collectionView);
        _collectionView = collectionView;
        [_collectionView addObserver:self forKeyPath:@"contentOffset" options:kNilOptions context:NULL];
        
        _preheatIndexPaths = [NSMutableSet new];
        _preheatRect = CGRectZero;
        _preheatContentOffset = CGPointZero;
        _preheatRectRatio = 2.f;
        _preheatRectOffset = 0.33f;
        _preheatRectUpdateRatio = 0.33f;
    }
    return self;
}

- (void)resetPreheatRect {
    [self.delegate collectionViewPreheatingController:self didUpdatePreheatRectWithAddedIndexPaths:@[] removedIndexPaths:_preheatIndexPaths.allObjects];
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
    _preheatContentOffset = CGPointZero;
}

- (void)_updatePreheatRect {
    NSAssert([self.collectionView.collectionViewLayout isKindOfClass:[UICollectionViewFlowLayout class]], @"%@ is not supported", self.collectionView.collectionViewLayout);
    BOOL isVertical = ((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).scrollDirection == UICollectionViewScrollDirectionVertical;
    
    CGPoint offset = self.collectionView.contentOffset;
    CGFloat delta = isVertical ? _preheatContentOffset.y - offset.y : _preheatContentOffset.x - offset.x;
    CGFloat margin = isVertical ? CGRectGetHeight(self.collectionView.bounds) * _preheatRectUpdateRatio : CGRectGetWidth(self.collectionView.bounds) * _preheatRectUpdateRatio;
    
    if (fabs(delta) > margin || CGPointEqualToPoint(_preheatContentOffset, CGPointZero)) {
        BOOL isScrollingForward = (isVertical ? offset.y >= _preheatContentOffset.y : offset.x >= _preheatContentOffset.x) || CGPointEqualToPoint(_preheatContentOffset, CGPointZero);
        
        _preheatContentOffset = offset;
        
        CGRect preheatRect = [self _preheatRectForScrollingForward:isScrollingForward];
        
        NSMutableSet *newIndexPaths = [NSMutableSet setWithArray:[self _indexPathsForElementsInRect:preheatRect]];
        
        NSMutableSet *oldIndexPaths = [NSMutableSet setWithSet:self.preheatIndexPaths];
        
        NSMutableSet *addedIndexPaths = [newIndexPaths mutableCopy];
        [addedIndexPaths minusSet:oldIndexPaths];
        
        NSMutableSet *removedIndexPaths = [oldIndexPaths mutableCopy];
        [removedIndexPaths minusSet:newIndexPaths];
        
        _preheatIndexPaths = newIndexPaths;
        
        NSArray<NSIndexPath *> *sortedAddedIndexPaths = [addedIndexPaths.allObjects sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"section" ascending:isScrollingForward], [NSSortDescriptor sortDescriptorWithKey:@"item" ascending:isScrollingForward] ]];
        
        _preheatRect = preheatRect;
        
        [self.delegate collectionViewPreheatingController:self didUpdatePreheatRectWithAddedIndexPaths:sortedAddedIndexPaths removedIndexPaths:removedIndexPaths.allObjects];
    }
}

- (CGRect)_preheatRectForScrollingForward:(BOOL)forward {
    BOOL isVertical = ((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).scrollDirection == UICollectionViewScrollDirectionVertical;
    
    // UIScrollView bounds works differently from UIView bounds. It adds the contentOffset to the rect.
    CGRect viewport = self.collectionView.bounds;
    CGRect preheatRect;
    if (isVertical) {
        CGFloat inset = viewport.size.height - viewport.size.height * _preheatRectRatio;
        preheatRect = CGRectInset(viewport, 0.f, inset / 2.f);
        CGFloat offset = _preheatRectOffset * CGRectGetHeight(self.collectionView.bounds);
        preheatRect = CGRectOffset(preheatRect, 0.f, forward ? offset : -offset);
    } else {
        CGFloat inset = viewport.size.width - viewport.size.width * _preheatRectRatio;
        preheatRect = CGRectInset(viewport, inset / 2.f, 0.f);
        CGFloat offset = _preheatRectOffset * CGRectGetWidth(self.collectionView.bounds);
        preheatRect = CGRectOffset(preheatRect, forward ? offset : -offset, 0.f);
    }
    return CGRectIntegral(preheatRect);
}

- (NSArray<NSIndexPath *> *)_indexPathsForElementsInRect:(CGRect)rect {
    NSArray<UICollectionViewLayoutAttributes *> *allLayoutAttributes = [self.collectionView.collectionViewLayout layoutAttributesForElementsInRect:rect];
    NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray new];
    for (UICollectionViewLayoutAttributes *attributes in allLayoutAttributes) {
        if (attributes.representedElementCategory == UICollectionElementCategoryCell) {
            [indexPaths addObject:attributes.indexPath];
        }
    }
    return indexPaths;
}

@end
