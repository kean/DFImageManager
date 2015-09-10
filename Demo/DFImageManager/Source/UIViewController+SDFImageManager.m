//
//  UIViewController+SDFImageManager.m
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 1/5/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "UIViewController+SDFImageManager.h"

@implementation UIViewController (SDFImageManager)

- (UIActivityIndicatorView *)df_showActivityIndicatorView {
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    indicator.translatesAutoresizingMaskIntoConstraints = NO;
    [indicator startAnimating];
    [self.view addSubview:indicator];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:indicator attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.f constant:0.f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:indicator attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.f constant:0.f]];
    return indicator;
}

@end
