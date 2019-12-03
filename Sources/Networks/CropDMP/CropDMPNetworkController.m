//
//  CropDMPNetworkController.m
//
//  Copyright © 2019 CROP.network. All rights reserved.
//

#import "CropDMPNetworkController.h"
#import "CropDMP.h"

@implementation CropDMPNetworkController

@synthesize privacyConsent = _privacyConsent;

- (void)setPrivacyConsent:(AdNetworkPrivacyConsent)privacyConsent
{
    CropDMPPrivacyConsent cropDMPConsent = ^{
        switch (privacyConsent) {
            case AdNetworkPrivacyConsentNotAcquired:
            case AdNetworkPrivacyConsentNoAds:
                return CropDMPPrivacyConsentNone;
            case AdNetworkPrivacyConsentNonPersonalized:
                return CropDMPPrivacyConsentNonPersonalized;
            case AdNetworkPrivacyConsentPersonalized:
                return CropDMPPrivacyConsentPersonalized;
        }
    }();
    [CropDMP sharedInstance].privacyConsent = cropDMPConsent;
}

@end
