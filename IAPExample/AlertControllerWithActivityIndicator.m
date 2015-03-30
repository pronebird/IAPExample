//
//  AlertControllerWithActivityIndicator.m
//  IAPExample
//
//  Created by pronebird on 3/30/15.
//  Copyright (c) 2015 pronebird. All rights reserved.
//

#import "AlertControllerWithActivityIndicator.h"

@implementation AlertControllerWithActivityIndicator

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    UIView *scrollView = [self findViewByClassPrefix:@"_UIAlertControllerShadowedScrollView" inView:self.view];
    UIView *containerView = [scrollView.subviews firstObject];
    UILabel *titleLabel = containerView.subviews.firstObject;
    
    if(!titleLabel) {
        return;
    }
    
    if(!self.indicatorView) {
        self.indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.indicatorView.translatesAutoresizingMaskIntoConstraints = NO;
        [containerView addSubview:self.indicatorView];
        NSDictionary *views = @{ @"text": titleLabel, @"indicator": self.indicatorView };
        
        NSArray *constraints = [scrollView constraintsAffectingLayoutForAxis:UILayoutConstraintAxisVertical];
        for(NSLayoutConstraint *constraint in constraints) {
            if(constraint.firstItem == containerView && constraint.secondItem == titleLabel && constraint.firstAttribute == NSLayoutAttributeBottom) {
                constraint.active = NO;
            }
        }
        
        [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[text]-[indicator]-24-|" options:0 metrics:nil views:views]];
        [containerView addConstraint:[NSLayoutConstraint constraintWithItem:self.indicatorView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        
        [self.indicatorView startAnimating];
    }
}

- (UIView *)findViewByClassPrefix:(NSString *)prefix inView:(UIView *)view {
    for(UIView *subview in view.subviews) {
        if([NSStringFromClass(subview.class) hasPrefix:prefix]) {
            return subview;
        }
        
        UIView *child = [self findViewByClassPrefix:prefix inView:subview];
        if(child) {
            return child;
        }
    }
    return nil;
}

@end
