//
//  DFStickyHeaderCollectionViewFlowLayout.m
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 1/8/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "SDFStickyHeaderCollectionViewFlowLayout.h"


@implementation SDFStickyHeaderCollectionViewFlowLayout

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
   return YES;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
   NSMutableArray *allItems = [[super layoutAttributesForElementsInRect:rect] mutableCopy];
   
   NSMutableDictionary *headers = [NSMutableDictionary new];
   NSMutableDictionary *lastCells = [NSMutableDictionary new];
   
   [allItems enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *attributes, NSUInteger idx, BOOL *stop) {
      if ([[attributes representedElementKind] isEqualToString:UICollectionElementKindSectionHeader]) {
         headers[@(attributes.indexPath.section)] = attributes;
      } else if ([[attributes representedElementKind] isEqualToString:UICollectionElementKindSectionFooter]) {
         // Not implemeneted
      } else {
         UICollectionViewLayoutAttributes *currentAttribute = lastCells[@(attributes.indexPath.section)];
         
         // Get the bottom most cell of that section
         if ( ! currentAttribute || attributes.indexPath.row > currentAttribute.indexPath.row) {
            lastCells[@(attributes.indexPath.section)] = attributes;
         }
      }
      
      // For iOS 7.0, the cell zIndex should be above sticky section header
      attributes.zIndex = 1;
   }];
   
   [lastCells enumerateKeysAndObjectsUsingBlock:^(id key, UICollectionViewLayoutAttributes *attributes, BOOL *stop) {
      NSNumber *indexPathKey = @(attributes.indexPath.section);
      
      UICollectionViewLayoutAttributes *header = headers[indexPathKey];
      // CollectionView automatically removes headers not in bounds
      if ( ! header) {
         header = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:attributes.indexPath.section]];
         if (header != nil) {
            [allItems addObject:header];
         }
      }
      [self _updateHeaderAttributes:header lastCellAttributes:lastCells[indexPathKey]];
   }];
   
   return allItems;
}

- (void)_updateHeaderAttributes:(UICollectionViewLayoutAttributes *)attributes lastCellAttributes:(UICollectionViewLayoutAttributes *)lastCellAttributes {
   CGRect currentBounds = self.collectionView.bounds;
   
   CGPoint origin = attributes.frame.origin;
   
   CGFloat sectionMaxY = CGRectGetMaxY(lastCellAttributes.frame) - attributes.frame.size.height;
   CGFloat y = CGRectGetMaxY(currentBounds) - currentBounds.size.height + self.collectionView.contentInset.top;
   
   CGFloat maxY = MIN(MAX(y, attributes.frame.origin.y), sectionMaxY);
    
   if (origin.y != maxY) {
      origin.y = maxY;
      attributes.zIndex = kStickyHeaderZIndex;
   }
   
   attributes.frame = (CGRect){
      origin,
      attributes.frame.size
   };
}

@end
