/*******************************************************************
 Filename: AdBannerProvider.h
   Author: Vitaliy Mostovy
  Company: Arkuda Digital LLC, Copyright 2010, All Rights Reserved
 *******************************************************************/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum {
    kAdBannerOrientationPortrait = 1,
    kAdBannerOrientationLandscape
} AdBannerOrientation;

@protocol AdBannerProviderDelegate;

@protocol AdBannerProvider <NSObject>

@property (assign, nonatomic) BOOL personalizationEnabled; // Default is NO
@property (weak, nonatomic) id<AdBannerProviderDelegate> delegate;

- (void)createViewForOrientation:(AdBannerOrientation)initialOrientation
                      controller:(UIViewController *)controller;
- (void)releaseBannerView;

 // May be nil if not yet created or already destroyed
- (UIView *)bannerView;
- (void)adjustToInterfaceOrientation:(AdBannerOrientation)orientation;

// Required by some implementations to present popup with
// ad destination.
- (void)setRootViewController:(UIViewController *)controller;

@end // @protocol AdBannerProvider

@protocol AdBannerProviderDelegate <NSObject>

@optional
- (void)adBannerProvider:(id<AdBannerProvider>)provider requestedLayoutForBanner:(UIView *)banner;

@optional
- (void)adBannerProviderFailedToReceiveAd:(id<AdBannerProvider>)provider;

@end // @protocol AdBannerProviderDelegate
