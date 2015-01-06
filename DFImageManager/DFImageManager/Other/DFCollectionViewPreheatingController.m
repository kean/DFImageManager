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
   [_preheatIndexPaths removeAllObjects];
   _preheatRect = CGRectZero;
}

- (void)updatePreheatRect {
   [self _updatePreheatRect];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
   if (object == self.collectionView) {
      [self _updatePreheatRect];
   } else {
      [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
   }
}

static inline CGFloat _SMPointDistance(CGPoint point0, CGPoint point1) {
   CGFloat dx = point1.x - point0.x;
   CGFloat dy = point1.y - point0.y;
   return sqrt(dx * dx + dy * dy);
}

- (void)_updatePreheatRect {
   // UIScrollView bounds works differently from UIView bounds. It adds the contentOffset to the rect.
   CGRect preheatRect = self.collectionView.bounds;
   CGFloat inset = preheatRect.size.height - preheatRect.size.height * _preheatRectRatio;
   preheatRect = CGRectInset(preheatRect, 0.f, inset / 2.f);
   
   // If scrolled by a "reasonable" amount...
   CGFloat delta = ABS(CGRectGetMidY(preheatRect) - CGRectGetMidY(_preheatRect));
   if (delta > CGRectGetHeight(self.collectionView.bounds) * _preheatRectRevalidationRatio) {
      
      NSMutableDictionary *allAttributes = [NSMutableDictionary new];
      NSMutableSet *addedIndexPaths = [NSMutableSet new];
      NSMutableSet *removedIndexPaths = [NSMutableSet new];
      [self computeDifferenceBetweenRect:_preheatRect andRect:preheatRect removedHandler:^(CGRect removedRect) {
         NSDictionary *attributes = [self _indexPathsForElementsInRect:removedRect];
         [removedIndexPaths addObjectsFromArray:[attributes allKeys]];
         [allAttributes addEntriesFromDictionary:attributes];
      } addedHandler:^(CGRect addedRect) {
         NSDictionary *attributes = [self _indexPathsForElementsInRect:addedRect];
         [addedIndexPaths addObjectsFromArray:[attributes allKeys]];
         [allAttributes addEntriesFromDictionary:attributes];
      }];
      
      // Get rid of all the duplicates.
      [addedIndexPaths minusSet:_preheatIndexPaths];
      [removedIndexPaths intersectSet:_preheatIndexPaths];
      
      [_preheatIndexPaths unionSet:addedIndexPaths];
      [_preheatIndexPaths minusSet:removedIndexPaths];
      
      // Sort added index paths
      CGPoint preheatCenter = CGPointMake(CGRectGetMidX(preheatRect), CGRectGetMidY(preheatRect));
      NSArray *sortedAddedIndexPaths = [[addedIndexPaths allObjects] sortedArrayUsingComparator:^NSComparisonResult(NSIndexPath *obj1, NSIndexPath *obj2) {
         UICollectionViewLayoutAttributes *attr1 = allAttributes[obj1];
         UICollectionViewLayoutAttributes *attr2 = allAttributes[obj2];
         CGPoint point1 = CGPointMake(CGRectGetMidX(attr1.frame), CGRectGetMidY(attr1.frame));
         CGPoint point2 = CGPointMake(CGRectGetMidX(attr2.frame), CGRectGetMidY(attr2.frame));
         CGFloat distance1 = _SMPointDistance(point1, preheatCenter);
         CGFloat distance2 = _SMPointDistance(point2, preheatCenter);
         if (distance1 > distance2) {
            return NSOrderedDescending;
         } else if (distance1 < distance2) {
            return NSOrderedAscending;
         }
         return NSOrderedSame;
      }];
      
      _preheatRect = preheatRect;
      
      [self.delegate collectionViewPreheatingController:self didUpdatePreheatRectWithAddedIndexPaths:sortedAddedIndexPaths removedIndexPaths:[removedIndexPaths allObjects]];
   }
}

- (NSDictionary *)_indexPathsForElementsInRect:(CGRect)rect {
   NSArray *allLayoutAttributes = [self.collectionView.collectionViewLayout layoutAttributesForElementsInRect:rect];
   if (allLayoutAttributes.count == 0) {
      return nil;
   }
   NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:allLayoutAttributes.count];
   for (UICollectionViewLayoutAttributes *layoutAttributes in allLayoutAttributes) {
      if (layoutAttributes.representedElementCategory == UICollectionElementCategoryCell) {
         NSIndexPath *indexPath = layoutAttributes.indexPath;
         attributes[indexPath] = layoutAttributes;
      }
   }
   return attributes;
}

- (void)computeDifferenceBetweenRect:(CGRect)oldRect andRect:(CGRect)newRect removedHandler:(void (^)(CGRect removedRect))removedHandler addedHandler:(void (^)(CGRect addedRect))addedHandler {
   if (CGRectIntersectsRect(newRect, oldRect)) {
      CGFloat oldMaxY = CGRectGetMaxY(oldRect);
      CGFloat oldMinY = CGRectGetMinY(oldRect);
      CGFloat newMaxY = CGRectGetMaxY(newRect);
      CGFloat newMinY = CGRectGetMinY(newRect);
      if (newMaxY > oldMaxY) {
         CGRect rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY));
         addedHandler(rectToAdd);
      }
      if (oldMinY > newMinY) {
         CGRect rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY));
         addedHandler(rectToAdd);
      }
      if (newMaxY < oldMaxY) {
         CGRect rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY));
         removedHandler(rectToRemove);
      }
      if (oldMinY < newMinY) {
         CGRect rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY));
         removedHandler(rectToRemove);
      }
   } else {
      addedHandler(newRect);
      removedHandler(oldRect);
   }
}

@end
