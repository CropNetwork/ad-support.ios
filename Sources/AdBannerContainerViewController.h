/*******************************************************************
 Filename: AdBannerContainerViewController.h
     Date: Aug 8, 2010
   Author: Vitaliy Mostovy
  Company: Arkuda Digital LLC, Copyright 2010, All Rights Reserved
 *******************************************************************/

#import "AdBannerManager.h"

@class AdBannerContainerView;

@interface AdBannerContainerViewController : UIViewController
    <AdBannerContainer>

- (id)initWithCoder:(NSCoder *)aDecoder; // Nib instantiation
- (id)initWithChildViewCtrl:(UIViewController*)childViewCtrl;

// Must be overridden if instantiated from nib
- (UIViewController *)childViewCtrl;

@property (assign, nonatomic) BOOL shouldAutorotate;

@end
