/*******************************************************************
 Filename: AdMobBannerProvider.m
   Author: Vitaliy Mostovy
  Company: Arkuda Digital LLC, Copyright 2010, All Rights Reserved
 *******************************************************************/

#import <GoogleMobileAds/GoogleMobileAds.h>

#import "AdMobBannerProvider.h"
#import "ADDebug.h"

@interface AdMobBannerProvider ()
{
    GADBannerView                      *m_ad_view;

    // The following is workaround for admob bug???: if first ad
    // wasn't received and GADBannerView.adSize property is changed,
    // it didn't reload baner to match changed size, but changed
    // banner view frame size. Reproduced with app started
    // from landscape mode.
    BOOL                                m_first_ad_was_received;
    GADAdSize                           m_current_size;
}

@property (copy, nonatomic) NSString *adUnitID;

@end

@implementation AdMobBannerProvider

@synthesize personalizationEnabled = _personalizationEnabled;
@synthesize delegate = _delegate;

- (id)initWithAdUnitID:(NSString *)unitID
{
    if (!(self = [super init]))
        return nil;

    _adUnitID = unitID;

    return self;
}

-(void)dealloc
{
    [self releaseBannerView];
}

- (GADAdSize)adSizeFromOrientation:(AdBannerOrientation)orientation
{
    if (orientation == kAdBannerOrientationPortrait) {
        return kGADAdSizeSmartBannerPortrait;
    } else {
        return kGADAdSizeSmartBannerLandscape;
    }
}

- (GADRequest *)createRequest
{
    GADRequest *request = [GADRequest request];
    request.testDevices = _testDeviceIDs;

    if (!_personalizationEnabled) {
        GADExtras *extras = [[GADExtras alloc] init];
        extras.additionalParameters = @{@"npa": @"1"};
        [request registerAdNetworkExtras:extras];
    }

    return request;
}

#pragma mark - GADBannerViewDelegate

- (void)adViewDidReceiveAd:(GADBannerView *)adView
{
    if (!m_first_ad_was_received && !GADAdSizeEqualToSize(m_ad_view.adSize, m_current_size))
    {
        m_ad_view.adSize = m_current_size; // reload banner
        return;
    }
    
    m_first_ad_was_received = YES;

    m_ad_view.hidden = NO;

    if ([_delegate respondsToSelector:@selector(adBannerProvider:requestedLayoutForBanner:)])
    {
        [_delegate adBannerProvider:self requestedLayoutForBanner:m_ad_view];
    }
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error
{
    m_ad_view.hidden = YES;
    if ([_delegate respondsToSelector:@selector(adBannerProvider:requestedLayoutForBanner:)])
    {
        [_delegate adBannerProvider:self requestedLayoutForBanner:m_ad_view];
    }
#ifndef NDEBUG
    ADDLog(@"%@", error);
#endif
}

#pragma mark - AdBanner

- (void)createViewForOrientation:(AdBannerOrientation)initialOrientation
                      controller:(UIViewController*)controller
{
    assert(m_ad_view == nil);
    if (m_ad_view != nil)
     return;

    m_current_size = [self adSizeFromOrientation:initialOrientation];
    m_ad_view = [[GADBannerView alloc] initWithAdSize:m_current_size];
    m_ad_view.hidden = YES;
    m_ad_view.adUnitID = _adUnitID;
    m_ad_view.delegate = self;
    m_ad_view.rootViewController = controller;
    [m_ad_view loadRequest:[self createRequest]];
    m_first_ad_was_received = NO;
}

- (void)releaseBannerView
{
    if (m_ad_view != nil)
    {
        m_ad_view.hidden = YES;
        m_ad_view.rootViewController = nil;
        m_ad_view.delegate = nil;
        m_ad_view = nil;
    }
    m_first_ad_was_received = NO;
    m_current_size = kGADAdSizeInvalid;
}

- (UIView*)bannerView
{
    return m_ad_view;
}

- (void)adjustToInterfaceOrientation:(AdBannerOrientation)orientation
{
    if (m_ad_view == nil)
        return;

    m_current_size = [self adSizeFromOrientation:orientation];
    if (GADAdSizeEqualToSize(m_ad_view.adSize, m_current_size))
        return;

    if (!m_first_ad_was_received) {
        return;
    }

    // If not using mediation, then changing the adSize
    // after an ad has been shown will cause a new request
    // (for an ad of the new size) to be sent.

    m_ad_view.adSize = m_current_size;
    m_ad_view.hidden = YES; // Will be blank (hidden?) after changing adSize
                            // and sending request for new banner
    [_delegate adBannerProvider:self
       requestedLayoutForBanner:m_ad_view]; // Hide banner until new one
                                            // will be received
}

- (void)setRootViewController:(UIViewController *)controller
{
    if (m_ad_view == nil)
        return;

    m_ad_view.rootViewController = controller;
}

@end
