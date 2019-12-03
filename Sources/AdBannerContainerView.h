//
//  AdBannerContainerView.h
//
//  Copyright © 2019 CROP.network. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AdBannerContainerView : UIView

- (void)placeContentView:(UIView *)view;
- (void)placeBannerView:(UIView *)view;
- (void)bannerViewWasRemoved;

@end
