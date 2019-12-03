/*******************************************************************
 Filename: AdBannerManager.m
   Author: Vitaliy Mostovy
  Company: Arkuda Digital LLC, Copyright 2010, All Rights Reserved
 *******************************************************************/

#import <Foundation/Foundation.h>

#import "AdBannerManager.h"
#import "ADDebug.h"

NSString *const privacyConsentDefaultsKey = @"privacyConsent";
NSString *const privacyConsentStringNoAds = @"none";
NSString *const privacyConsentStringNonPersonalized = @"non-personalized";
NSString *const privacyConsentStringPersonalized = @"personalized";

@interface AdBannerManager ()

// Array of id<AdBannerProvider>
@property (strong, nonatomic) NSMutableArray *bannerProviders;

// Array of id<AdNetworkController>
@property (strong, nonatomic) NSMutableArray *networkControllers;

@property (assign, nonatomic) CGSize bannerSize;
@property (weak, nonatomic) UIViewController<AdBannerContainer> *currentContainer;

@property (assign, nonatomic) int currentBannerProviderIndex;
@property (readonly, nonatomic) id<AdBannerProvider> currentBannerProvider;

@property (strong, nonatomic) NSTimer *preferredBannerProviderCheckTimer;

// Tip from Apple:
//     "Only create a banner view when you intend to display it to the user.
//     Otherwise, it may cycle through ads and deplete the list of available
//     advertising for your application. Otherwise, it may cycle through ads
//     and deplete the list of available advertising for your application."
@property (strong, nonatomic) NSTimer *bannerDestroyTimer;

@end

@implementation AdBannerManager

@dynamic preferredBannerProviderIndex;
@dynamic currentBannerProvider;

- (id)init
{
    if (!(self = [super init]))
        return nil;

    _privacyConsent = [self readSavedPrivacyConsent];

    _bannerProviders = [[NSMutableArray alloc] initWithCapacity:5];
    _networkControllers = [[NSMutableArray alloc] initWithCapacity:5];
    _currentBannerProviderIndex = -1;
    _bannerSize = CGSizeMake(0,0);

    return self;
}

+ (AdBannerManager *)sharedInstance
{
    static AdBannerManager *instance = nil;
    if (instance == nil) {
        instance = [[AdBannerManager alloc] init];
    }

    return instance;
}

- (void)addBannerProvider:(id<AdBannerProvider>)provider
{
    provider.delegate = self;
    provider.personalizationEnabled = _privacyConsent == AdNetworkPrivacyConsentPersonalized;

    [_bannerProviders addObject:provider];
    if (_currentBannerProviderIndex < 0)
        [self switchToProvider:0];
}

- (void)addNetworkController:(id<AdNetworkController>)controller
{
    controller.privacyConsent = _privacyConsent;
    [_networkControllers addObject:controller];
}

- (void)continueWithoutPrivacyConsent
{
    for (id<AdNetworkController> controller in _networkControllers) {
        controller.privacyConsent = AdNetworkPrivacyConsentPersonalized;
    }

    for (id<AdBannerProvider> banner in _bannerProviders) {
        banner.personalizationEnabled = YES;
    }
}

- (void)setPrivacyConsent:(AdNetworkPrivacyConsent)privacyConsent
{
    if (_privacyConsent == privacyConsent)
        return;

    _privacyConsent = privacyConsent;
    [self savePrivacyConsent:privacyConsent];

    for (id<AdNetworkController> controller in _networkControllers) {
        controller.privacyConsent = privacyConsent;
    }
    for (id<AdBannerProvider> banner in _bannerProviders) {
        banner.personalizationEnabled = privacyConsent == AdNetworkPrivacyConsentPersonalized;
    }
}

- (void)setPreferredBannerProvider:(id<AdBannerProvider>)preferredBannerProvider
{
    if (_preferredBannerProvider == preferredBannerProvider)
        return;

    _preferredBannerProvider = preferredBannerProvider;
    if (_preferredBannerProvider && _preferredBannerProvider != self.currentBannerProvider) {
        [self startPreferredBannerCheckTimer];
    }
}

- (NSUInteger)preferredBannerProviderIndex
{
    if (!_preferredBannerProvider)
        return NSNotFound;

    return [_bannerProviders indexOfObjectIdenticalTo:_preferredBannerProvider];
}

- (void)setPreferredBannerProviderIndex:(NSUInteger)index
{
    [self setPreferredBannerProvider:_bannerProviders[index]];
}

- (id<AdBannerProvider>)currentBannerProvider
{
    return [self bannerProviderForIndex:_currentBannerProviderIndex];
}

- (void)switchToNextProvider
{
    [self switchToProvider:(_currentBannerProviderIndex + 1) % _bannerProviders.count];
}

- (void)switchToProvider:(int)providerIndex
{
    id<AdBannerProvider> oldProvider = self.currentBannerProvider;
    id<AdBannerProvider> newProvider = [self bannerProviderForIndex:providerIndex];
    if (oldProvider == newProvider)
        return;

    if (_preferredBannerProvider && newProvider == _preferredBannerProvider)
        [self stopPreferredBannerCheckTimer];

    _currentBannerProviderIndex = providerIndex;

    [self finishWithProvider:oldProvider];
    [self startWithProvider:newProvider];
}

- (void)finishWithProvider:(id<AdBannerProvider>)provider
{
    if (provider.bannerView.superview) {
        [provider.bannerView removeFromSuperview];
        [_currentContainer bannerViewWasRemoved];
    }

    [provider releaseBannerView];
}

- (void)startWithProvider:(id<AdBannerProvider>)provider
{
    _bannerSize = CGSizeZero;

    if (!_currentContainer) {
        [self startBannerDestroyTimer];
        return;
    }

    if (!provider.bannerView) {
        // Create banner view
        [provider createViewForOrientation:[self bannerOrientationFromController:_currentContainer]
                                controller:_currentContainer];
    }

    [provider setRootViewController:_currentContainer];
    [_currentContainer placeBannerView:provider.bannerView];
}

- (id<AdBannerProvider>)bannerProviderForIndex:(int)index
{
    if (index < 0)
        return nil;
    return _bannerProviders[index];
}

- (void)startPreferredBannerCheckTimer
{
    if (_preferredBannerProviderCheckTimer)
        return;

    _preferredBannerProviderCheckTimer = [NSTimer scheduledTimerWithTimeInterval:adBannerManagerPreferredBannerCheckInterval target:self selector:@selector(onPreferredBannerCheckTimer:) userInfo:nil repeats:NO];
}

- (void)stopPreferredBannerCheckTimer
{
    if (_preferredBannerProviderCheckTimer) {
        [_preferredBannerProviderCheckTimer invalidate];
        _preferredBannerProviderCheckTimer = nil;
    }
}

- (void)onPreferredBannerCheckTimer:(NSTimer *)timer
{
    _preferredBannerProviderCheckTimer = nil;

    if (!_preferredBannerProvider)
        return;

    NSUInteger preferredProviderIndex = [_bannerProviders indexOfObjectIdenticalTo:_preferredBannerProvider];

    ADAssert(preferredProviderIndex != NSNotFound, @"Preferred banner provider not found");
    if (preferredProviderIndex == NSNotFound)
        return;

    [self switchToProvider:preferredProviderIndex];
}

- (void)startBannerDestroyTimer
{
    const NSTimeInterval kDestroyAfterSeconds = 10;
    if (!_bannerDestroyTimer)
    {
        _bannerDestroyTimer = [NSTimer scheduledTimerWithTimeInterval:kDestroyAfterSeconds
                                                               target:self
                                                             selector:@selector(onBannerDestroyTimer:)
                                                             userInfo:nil
                                                              repeats:NO];
    }
}

- (void)stopBannerDestroyTimer
{
    if (_bannerDestroyTimer) {
        [_bannerDestroyTimer invalidate];
        _bannerDestroyTimer = nil;
    }
}

// This timer will fire several seconds after all view controllers disappear
- (void)onBannerDestroyTimer:(NSTimer*)timer
{
    _bannerDestroyTimer = nil;
    if (!_currentContainer)
        return;

    if (self.currentBannerProvider.bannerView)
    {
        [self.currentBannerProvider.bannerView removeFromSuperview]; // paranoia
        [self.currentBannerProvider releaseBannerView];
    }

}

- (AdBannerOrientation)bannerOrientationFromController:(UIViewController*)ctrl
{
    AdBannerOrientation orientation = kAdBannerOrientationPortrait;
    const CGSize sz = ctrl.view.bounds.size;
    if (sz.width > sz.height)
        orientation = kAdBannerOrientationLandscape;

    return orientation;
}

- (void)checkIfBannerSizeChanged
{
    const CGSize prev_size = _bannerSize;
    _bannerSize = self.currentBannerProvider.bannerView.bounds.size;
    if (!CGSizeEqualToSize(prev_size, _bannerSize)) {
        [_currentContainer.view setNeedsLayout];
    }
}

- (void)adContainerWillAppear:(UIViewController<AdBannerContainer>*)ctrl
{
    assert(ctrl);

    [self stopBannerDestroyTimer];

    // Create banner view if not yet
    if (!self.currentBannerProvider.bannerView)
        [self.currentBannerProvider createViewForOrientation:[self bannerOrientationFromController:ctrl] controller:ctrl];

    UIView *bannerView = self.currentBannerProvider.bannerView;

    // Detach from previous controller if needed
    if (bannerView.superview || _currentContainer) {
        [bannerView removeFromSuperview];
        [_currentContainer bannerViewWasRemoved];
    }

    _currentContainer = ctrl;

    // Attach to visible controller
    [self.currentBannerProvider setRootViewController:ctrl];
    [_currentContainer placeBannerView:self.currentBannerProvider.bannerView];
}

- (void)adContainerDidDisappear:(UIViewController<AdBannerContainer>*)ctrl
{
    assert(ctrl);
    if (_currentContainer != ctrl) {
        // In case of -[ctrlViewDidDisapper:] being delivered
        // after -[adContainerWillAppear:]
        return;
    }

    // Detach from controller, which become invisible
    [self.currentBannerProvider.bannerView removeFromSuperview];
    [_currentContainer bannerViewWasRemoved];
    [self.currentBannerProvider setRootViewController:nil];
    _currentContainer = nil;
    [self startBannerDestroyTimer];
}

- (void)adContainerDidLayoutSubviews:(UIViewController<AdBannerContainer>*)ctrl
{
    if (!_currentContainer || _currentContainer != ctrl)
        return;

    [self.currentBannerProvider adjustToInterfaceOrientation:[self bannerOrientationFromController:ctrl]];
    [self checkIfBannerSizeChanged];
}

- (void)removeBannerFromContainer
{
    [self.currentBannerProvider.bannerView removeFromSuperview];
    [_currentContainer bannerViewWasRemoved];
    [self.currentBannerProvider setRootViewController:nil];
    _currentContainer = nil;
    [self startBannerDestroyTimer];
}

#pragma mark - AdBannerProviderDelegate

- (void)adBannerProvider:(id<AdBannerProvider>)provider
requestedLayoutForBanner:(UIView *)banner
{
    if (_currentContainer) {
        [_currentContainer.view setNeedsLayout];
    }
}

- (void)adBannerProviderFailedToReceiveAd:(id<AdBannerProvider>)provider
{
    if (provider == self.currentBannerProvider && _preferredBannerProvider && provider == _preferredBannerProvider && _bannerProviders.count > 1) {
        [self startPreferredBannerCheckTimer];
    }

    [self switchToNextProvider];
}

#pragma mark - Saving privacy consent info

- (AdNetworkPrivacyConsent)readSavedPrivacyConsent
{
    NSString *stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:privacyConsentDefaultsKey];
    if (!stringValue)
        return AdNetworkPrivacyConsentNotAcquired;
    return [self privacyConsentFromString:stringValue];
}

- (void)savePrivacyConsent:(AdNetworkPrivacyConsent)consent
{
    if (consent == AdNetworkPrivacyConsentNotAcquired) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:privacyConsentDefaultsKey];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:[self privacyConsentToString:consent] forKey:privacyConsentDefaultsKey];
    }
}

- (NSString *)privacyConsentToString:(AdNetworkPrivacyConsent)consent
{
    switch (consent) {
        case AdNetworkPrivacyConsentNotAcquired:
            assert(false);
            return nil;
        case AdNetworkPrivacyConsentNoAds:
            return privacyConsentStringNoAds;
        case AdNetworkPrivacyConsentNonPersonalized:
            return privacyConsentStringNonPersonalized;
        case AdNetworkPrivacyConsentPersonalized:
            return privacyConsentStringPersonalized;
    }

    assert(false);
    return privacyConsentStringNoAds;
}

- (AdNetworkPrivacyConsent)privacyConsentFromString:(NSString *)string {
    if ([string isEqualToString:privacyConsentStringNoAds])
        return AdNetworkPrivacyConsentNoAds;

    if ([string isEqualToString:privacyConsentStringNonPersonalized])
        return AdNetworkPrivacyConsentNonPersonalized;

    if ([string isEqualToString:privacyConsentStringPersonalized])
        return AdNetworkPrivacyConsentPersonalized;

    assert(false);
    return AdNetworkPrivacyConsentNotAcquired;
}

@end
