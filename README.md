# CROP Ad Banner Management

The library includes:
- banner management framework (`AdBannerManager`, `AdBannerProvider`, `AdNetworkController`);
- banner implementations for CropDMP and Google AdMob networks;
- consent acquiring code (`AdConsentHelper`).

## Prerequisites

1. Add `Sources` folder contents to your project.
2. Add [iOS Utils](https://github.com/CropNetwork/utils.ios) and [CropDMP](https://github.com/CropNetwork/cropdmp.ios) source files to your project.
3. Add AdMob SDK to your project (follow "Import the Mobile Ads SDK" and "Update your Info.plist" steps from [Google's guide](https://developers.google.com/admob/ios/quick-start)).
4. Initialize CropDMP library in your app delegate (see [CropDMP's README](https://github.com/CropNetwork/cropdmp.ios/blob/master/README.md) for details).

## Setting Up Banners

To show ads, first of all one needs to set up AdBannerManager. A good place to do it is `-[AppDelegate application:didFinishLaunchingWithOptions:]`. Banner setup should occur after CropDMP initialization. Here's an example of banner initialization in app delegate (relevant parts):

```objc
#import "AdBannerManager.h"
#import "AdMobBannerProvider.h"
#import "AdMobNetworkController.h"
#import "CropDMPBannerProvider.h"
#import "CropDMPNetworkController.h"

// ...

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //  <CropDMP initialization> (should go before banner initialization)

    AdBannerManager *adBannerManager = [AdBannerManager sharedInstance];

    // Setup AdMob banners
    NSString *adMobUnitID = @"..."; // Use your ad unit ID here
    AdMobNetworkController *adMobNetworkController = [[AdMobNetworkController alloc] init];
    AdMobBannerProvider *adMobBannerProvider = [[AdMobBannerProvider alloc] initWithAdUnitID:adUnitID];
    adMobBannerProvider.testDeviceIDs = @[ /* ... */ ]; // Optionally set testing devices
    [adBannerManager addNetworkController:adMobNetworkController];
    [adBannerManager addBannerProvider:adMobBannerProvider];

    // Setup CropDMP banners
    CropDMPNetworkController *cropDMPNetworkController = [[CropDMPNetworkController alloc] init];
    CropDMPBannerProvider *cropDMPBannerProvider = [[CropDMPBannerProvider alloc] init];
    [adBannerManager addNetworkController:cropDMPNetworkController];
    [adBannerProvider addBannerProvider:cropDMPBannerProvider];

    // Preferentially show CropDMP banner
    adBannerManager.preferredBannerProviderIndex = 1;

	// Enable personalized or non-personalized ads
    adBannerManager.privacyConsent = AdNetworkPrivacyConsentPersonalized; // or NonPersonalized

    // ...
}
```

## Banner Placement

The simplest way to embed banner view in the UI is to use `AdBannerContainerViewController`. It serves as a container for both ad view and your content view controller, placing ad banner below the content. The exact placement of the `AdBannerContainerViewController` depends of where you want to display the banner. For example, if you want to place banner at the very bottom of the app, you can derive your view controller from `AdBannerContainerViewController`. `AdBannerContainerViewController` needs to be initialized with the content view controller:

```objc

// RootViewController.h

#import "AdBannerContainerViewController.h"

@interface RootViewController : AdBannerContainerViewController
@end

// -[AppDelegate application:didFinishLaunchingWithOptions:]

ContentViewController *contentViewController = [[ContentViewController alloc] init];
self.window.rootViewController = [[RootViewController alloc] initWithChildViewCtrl:contentViewController];
```

Alternatively, you can embed banners in your own view controller without deriving `AdBannerContainerViewController`. You'll need to implement `AdBannerContainer` protocol and make sure to notify `AdBannerManager` whenever controller's view appear and disappear:

```objc

// ViewController.h

#import "AdBannerManager.h"

@interface ViewController : UIViewController<AdBannerContainer>
@end

// ViewController.m

#import "ViewController.h"

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[AdBannerManager sharedInstance] adContainerWillAppear:self];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    [[AdBannerManager sharedInstance] adContainerDidDisappear:self];
}

// AdBannerContainer methods

- (void)placeBannerView:(NSView *)banner {
    // Insert banner into the view hierarchy
}

- (void)bannerViewWasRemoved {
    // Perform any necessary cleanup
}

@end

```

