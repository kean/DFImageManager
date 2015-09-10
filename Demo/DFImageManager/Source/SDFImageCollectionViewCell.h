//
//  SDFImageCollectionViewCell.h
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 20/07/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DFImageView;
@class DFImageRequest;

@interface SDFImageCollectionViewCell : UICollectionViewCell

@property (nonatomic, readonly) DFImageView *imageView;

- (void)setImageWithURL:(NSURL *)imageURL;
- (void)setImageWithRequest:(DFImageRequest *)request;

@end
