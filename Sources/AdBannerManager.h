/*******************************************************************
 Filename: AdBannerManager.h
   Author: Vitaliy Mostovy
  Company: Arkuda Digital LLC, Copyright 2010, All Rights Reserved
 *******************************************************************/

#import "AdBannerProvider.h"
#import "AdNetworkController.h"

static NSTimeInterval adBannerManagerPreferredBannerCheckInterval = 5 * 60;

@protocol AdBannerContainer;

@interface AdBannerManager : NSObject <AdBannerProviderDelegate>

+ (AdBannerManager*)sharedInstance;

- (void)addBannerProvider:(id<AdBannerProvider>)provider;
- (void)addNetworkController:(id<AdNetworkController>)controller;

- (void)continueWithoutPrivacyConsent;
@property (assign, nonatomic) AdNetworkPrivacyConsent privacyConsent; // Default is None

// Set nil to remove preferred provider. Manager will switch
// to the preferred provider every adBannerManagerPreferredBannerCheckInterval
// seconds.
@property (weak, nonatomic) id<AdBannerProvider> preferredBannerProvider;
@property (assign, nonatomic) NSUInteger preferredBannerProviderIndex; // NSNotFound if no preferred provider

// messages from visible view controller, which holds the banner
- (void)adContainerWillAppear:(UIViewController<AdBannerContainer>*)ctrl;
- (void)adContainerDidDisappear:(UIViewController<AdBannerContainer>*)ctrl;
- (void)adContainerDidLayoutSubviews:(UIViewController<AdBannerContainer>*)ctrl;

- (void)removeBannerFromContainer;

@end

@protocol AdBannerContainer

- (void)placeBannerView:(UIView*)bannerView;
- (void)bannerViewWasRemoved;

@end
