//
//  AdNetworkController.h
//
//  Copyright © 2019 CROP.network. All rights reserved.
//

typedef enum {
    AdNetworkPrivacyConsentNotAcquired,
    AdNetworkPrivacyConsentNoAds,
    AdNetworkPrivacyConsentNonPersonalized,
    AdNetworkPrivacyConsentPersonalized,
} AdNetworkPrivacyConsent;

@protocol AdNetworkController <NSObject>

// Default is None
@property (assign, nonatomic) AdNetworkPrivacyConsent privacyConsent;

@end
