//
//  DFMomentHeaderCollectionReusableView.h
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 1/8/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DFMomentHeaderCollectionReusableView;

@protocol DFMomentHeaderCollectionReusableViewDelegate <NSObject>

- (void)momentHeader:(DFMomentHeaderCollectionReusableView *)header didPressButton:(UIButton *)button;

@end

@interface DFMomentHeaderCollectionReusableView : UICollectionReusableView

@property (weak, nonatomic) IBOutlet UILabel *labelTopLeft;
@property (weak, nonatomic) IBOutlet UILabel *labelBottomLeft;
@property (weak, nonatomic) IBOutlet UILabel *labelBottomRight;

@property (nonatomic) NSLayoutConstraint *labelTopLeftConstraintCenterVertically;
@property (nonatomic) IBOutlet NSLayoutConstraint *labelTopLeftConstraintTopSpacing;

@property (nonatomic, weak) id<DFMomentHeaderCollectionReusableViewDelegate> delegate;

@end
