//
//  DFMomentHeaderCollectionReusableView.m
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 1/8/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "SDFStickyHeaderCollectionViewFlowLayout.h"
#import "SDFMomentHeaderCollectionReusableView.h"

@interface SDFMomentHeaderCollectionReusableView ()

@property (weak, nonatomic) UIVisualEffectView *visualEffectView;

@end

@implementation SDFMomentHeaderCollectionReusableView

- (void)awakeFromNib {
    self.labelBottomLeft.text = @"";
    self.labelBottomRight.text = @"";
    self.labelTopLeft.text = @"";
    
    if ([UIVisualEffectView class] != nil) {
        UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        blur.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(blur);
        [self insertSubview:blur atIndex:0];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[blur]|" options:kNilOptions metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[blur]|" options:kNilOptions metrics:nil views:views]];
        self.visualEffectView = blur;
    } else {
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6f];
    }
    
    self.labelTopLeftConstraintCenterVertically = [NSLayoutConstraint constraintWithItem:self.labelTopLeft attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.f constant:0.f];
    self.labelTopLeftConstraintCenterVertically.active = NO;
    [self addConstraint:self.labelTopLeftConstraintCenterVertically];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.visualEffectView.hidden = YES;
    self.labelBottomLeft.text = @"";
    self.labelBottomRight.text = @"";
    self.labelTopLeft.text = @"";
    self.labelTopLeftConstraintCenterVertically.active = NO;
    self.labelTopLeftConstraintTopSpacing.active = YES;
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    [super applyLayoutAttributes:layoutAttributes];
    BOOL hidden = layoutAttributes.zIndex != kStickyHeaderZIndex;
    if (self.visualEffectView.hidden != hidden) {
        self.visualEffectView.hidden = hidden;
    }
}

@end
