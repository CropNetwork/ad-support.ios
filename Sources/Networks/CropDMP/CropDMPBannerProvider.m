//
//  CropDMPBannerProvider.m
//
//  Copyright © 2019 CROP.network. All rights reserved.
//

#import <WebKit/WebKit.h>

#import "CropDMP.h"
#import "CropDMPBannerProvider.h"
#import "ADDebug.h"

@interface URLQueue : NSObject
- (void)pushURL:(NSURL *)url;
- (BOOL)popURLAndAllPrecedingURLs:(NSURL *)url;
@end // @interface URLQueue

@interface CropDMPBannerProvider () <WKNavigationDelegate>
@property (strong, nonatomic) WKWebView *banner;
@property (strong, nonatomic) URLQueue *urlQueue;
@property (assign, nonatomic) AdBannerOrientation lastSetOrientation;
@end

@implementation CropDMPBannerProvider

@synthesize personalizationEnabled = _personalizationEnabled;
@synthesize delegate = _delegate;

- (id)init
{
    if (!(self = [super init]))
        return nil;

    _urlQueue = [[URLQueue alloc] init];
    _lastSetOrientation = kAdBannerOrientationPortrait;

    [self subscribeToCropDMPNotifications];

    return self;
}

- (void)dealloc
{
    [self unsubscribeFromCropDMPNotifications];
}

#pragma mark -

- (void)createViewForOrientation:(AdBannerOrientation)initialOrientation
                      controller:(UIViewController *)controller
{
    assert(!_banner);

    WKPreferences *preferences = [[WKPreferences alloc] init];
    preferences.javaScriptEnabled = YES;

#ifndef NDEBUG
    [preferences setValue:@YES forKey:@"developerExtrasEnabled"];
#endif

    WKUserContentController *userContentController = [[WKUserContentController alloc] init];

    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.userContentController = userContentController;
    configuration.preferences = preferences;

    _banner = [[WKWebView alloc] initWithFrame:CGRectZero
                                 configuration:configuration];
    _banner.navigationDelegate = self;
    _banner.hidden = YES;

    [self adjustToInterfaceOrientation:_lastSetOrientation];
}

- (void)releaseBannerView
{
    if (!_banner)
        return;

    _banner = nil;
}

- (void)adjustToInterfaceOrientation:(AdBannerOrientation)orientation {
    if (!_banner)
        return;

    _lastSetOrientation = orientation;

    const UIUserInterfaceIdiom idiom = UI_USER_INTERFACE_IDIOM();
    const CGSize bannerSize = [self adSizeForInterfaceIdiom:idiom
                                                orientation:orientation];
    if (_banner) {
        _banner.frame = CGRectMake(_banner.frame.origin.x,
                                   _banner.frame.origin.y,
                                   bannerSize.width,
                                   bannerSize.height);
    }

    [CropDMP sharedInstance].preferredAdBannerSizePixels = [self pointSizeToPixelSize:bannerSize];
    [[CropDMP sharedInstance] sendAllDeviceInfos];
}


- (UIView *)bannerView {
    return _banner;
}

- (void)setRootViewController:(UIViewController *)ctrl {
    // Do nothing
}

- (CGSize)adSizeForInterfaceIdiom:(UIUserInterfaceIdiom)idiom
                      orientation:(AdBannerOrientation)orientation
{
    const CGSize screenSize = [UIScreen mainScreen].bounds.size;
    const CGFloat height = idiom == UIUserInterfaceIdiomPad ? 90
             : orientation == kAdBannerOrientationLandscape ? 30
                                                            : 75;
    return CGSizeMake(screenSize.width, height);
}

- (CGSize)pointSizeToPixelSize:(CGSize)pointSize
{
    const CGFloat screenScale = [UIScreen mainScreen].scale;
    return CGSizeMake(pointSize.width * screenScale,
                      pointSize.height * screenScale);
}

#pragma mark -

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(nonnull WKNavigationAction *)navigationAction decisionHandler:(nonnull void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSURL *requestedURL = navigationAction.request.URL;
    if ([_urlQueue popURLAndAllPrecedingURLs:requestedURL]) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }

    decisionHandler(WKNavigationActionPolicyCancel);

    UIApplication *app = [UIApplication sharedApplication];
    if (![app canOpenURL:requestedURL]) {
        ADDLog(@"CropDMPBannerProvider: Banner link can't be opened: %@", requestedURL);
        return;
    }

    [app openURL:requestedURL];
}

#pragma mark -

- (void)onCropDMPReceivedBannerURL
{
    NSURL *bannerURL = [NSURL URLWithString:[CropDMP sharedInstance].bannerURL];
    if (!bannerURL) {
        // Empty or invalid URL string
        [self reportFailureToDelegate];
        return;
    }

    ADDLog(@"onCropDMPReceivedBannerURL %@", bannerURL);
    [_urlQueue pushURL:bannerURL];

    [_banner loadRequest:[[NSURLRequest alloc] initWithURL:bannerURL]];
    _banner.hidden = NO;

    [self requestLayoutFromDelegate];
}

- (void)onCropDMPFailedToReceivedBannerURL
{
    [self reportFailureToDelegate];
}

- (void)subscribeToCropDMPNotifications
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(onCropDMPReceivedBannerURL)
                   name:CropDMPReceivedBannerURLNotification
                 object:[CropDMP sharedInstance]];
    [center addObserver:self
               selector:@selector(onCropDMPFailedToReceivedBannerURL)
                   name:CropDMPFailedToReceiveBannerURLNotification
                 object:[CropDMP sharedInstance]];
}

- (void)unsubscribeFromCropDMPNotifications
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self
                      name:CropDMPReceivedBannerURLNotification
                    object:[CropDMP sharedInstance]];
    [center removeObserver:self
                      name:CropDMPFailedToReceiveBannerURLNotification
                    object:[CropDMP sharedInstance]];
}

#pragma mark -

- (void)requestLayoutFromDelegate
{
    if ([_delegate respondsToSelector:@selector(adBannerProvider:requestedLayoutForBanner:)])
    {
        [_delegate adBannerProvider:self requestedLayoutForBanner:_banner];
    }
}

- (void)reportFailureToDelegate
{
    if ([_delegate respondsToSelector:@selector(adBannerProviderFailedToReceiveAd:)])
    {
        [_delegate adBannerProviderFailedToReceiveAd:self];
    }
}

@end

#pragma mark - URLQueue

@interface URLQueue() // Private properties
@property NSMutableArray *urls;
@end // @interface URLQueue()

@implementation URLQueue

- (instancetype)init
{
    if (!(self = [super init]))
        return nil;

    _urls = [NSMutableArray arrayWithCapacity:5];

    return self;
}

- (void)pushURL:(NSURL *)url
{
    [_urls addObject:url];
}

- (BOOL)popURLAndAllPrecedingURLs:(NSURL *)url
{
    const NSUInteger urlIndex = [_urls indexOfObject:url];
    if (urlIndex == NSNotFound)
        return NO;

    [_urls removeObjectsInRange:NSMakeRange(0, urlIndex + 1)];

    return YES;
}

@end // @implemenation URLQueue
