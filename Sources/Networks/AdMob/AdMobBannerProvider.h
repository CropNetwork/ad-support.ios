/*******************************************************************
 Filename: AdMobBannerProvider.h
   Author: Vitaliy Mostovy
  Company: Arkuda Digital LLC, Copyright 2010, All Rights Reserved
 *******************************************************************/

#import <GoogleMobileAds/GoogleMobileAds.h>

#import "AdBannerProvider.h"

@class GADBannerView;
@protocol GADBannerViewDelegate;

@interface AdMobBannerProvider : NSObject<AdBannerProvider, GADBannerViewDelegate>

- (id)initWithAdUnitID:(NSString *)unitID;

@property (copy, nonatomic) NSArray *testDeviceIDs;

@end
