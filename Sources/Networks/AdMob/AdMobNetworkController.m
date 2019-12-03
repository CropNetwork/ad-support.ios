//
//  AdMobNetworkController.m
//
//  Copyright © 2019 CROP.network. All rights reserved.
//

#import <GoogleMobileAds/GoogleMobileAds.h>

#import "AdMobNetworkController.h"

NSString *const conversionID = @"1011901950";
#ifdef IS_PRO
NSString *const conversionLabel = @"_WZoCPuDmGMQ_svB4gM";
NSString *const conversionValue = @"3.00";
#else
NSString *const conversionLabel = @"07ryCPqFmGMQ_svB4gM";
NSString *const conversionValue = @"0.50";
#endif

@implementation AdMobNetworkController

@synthesize privacyConsent = _privacyConsent;

- (instancetype)init
{
    if (!(self = [super init]))
        return nil;

    _privacyConsent = AdNetworkPrivacyConsentNoAds;

    return self;
}

- (void)setPrivacyConsent:(AdNetworkPrivacyConsent)privacyConsent
{
    if (_privacyConsent == privacyConsent)
        return;

    _privacyConsent = privacyConsent;

    if (privacyConsent == AdNetworkPrivacyConsentPersonalized) {
        [[GADMobileAds sharedInstance] startWithCompletionHandler:nil];

    } else {
        [[GADMobileAds sharedInstance] startWithCompletionHandler:nil];
    }
}

@end
