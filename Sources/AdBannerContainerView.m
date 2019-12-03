//
//  AdBannerContainerView.m
//
//  Copyright © 2019 CROP.network. All rights reserved.
//

#import "AdBannerContainerView.h"

@interface AdBannerContainerView ()
{
    UIView *m_child_ctrl_view;
    UIView *m_ad_view;
}

@end

@implementation AdBannerContainerView

- (void)placeContentView:(UIView *)in_view
{
    m_child_ctrl_view = in_view;
    [self addSubview:m_child_ctrl_view];
}

- (void)layoutSubviews
{
    CGSize content_sz = self.bounds.size;

    const BOOL adViewVisible = m_ad_view != nil && !m_ad_view.hidden;
    const CGSize adViewSize = m_ad_view.frame.size;

    // layout child controller view
    const CGFloat child_ctrl_view_height = adViewVisible ? (content_sz.height - adViewSize.height) : content_sz.height;
    m_child_ctrl_view.frame = CGRectMake(0, 0, content_sz.width, child_ctrl_view_height);

    // layout banner
    if (m_ad_view) {
        const CGFloat ad_x = (content_sz.width - adViewSize.width) / 2;
        const CGFloat ad_y = child_ctrl_view_height;
        m_ad_view.frame = CGRectMake(ad_x, ad_y, adViewSize.width, adViewSize.height);
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    CGRect r = newSuperview.bounds;
    self.frame = CGRectMake(0, 0, r.size.width, r.size.height);
}

- (void)placeBannerView:(UIView*)ad_view
{
    m_ad_view = ad_view;
    [self addSubview:m_ad_view]; // OK even if already added
    [self setNeedsLayout];
}

- (void)bannerViewWasRemoved
{
    m_ad_view = nil;
    [self setNeedsLayout];
}

@end
