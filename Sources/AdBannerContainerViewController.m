/*******************************************************************
 Filename: AdBannerContainerViewController.m
     Date: Aug 8, 2010
   Author: Vitaliy Mostovy
  Company: Arkuda Digital LLC, Copyright 2010, All Rights Reserved
 *******************************************************************/

#import "AdBannerContainerViewController.h"

#import "AdBannerContainerView.h"

@interface AdBannerContainerViewController ()
{
    UIViewController *m_child_ctrl;
    AdBannerContainerView *m_view;
}

@end

@implementation AdBannerContainerViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        m_view = [[AdBannerContainerView alloc] init];
        m_child_ctrl = [self childViewCtrl];
        _shouldAutorotate = true;
    }
    return self;
}

- (id)initWithChildViewCtrl:(UIViewController*)childViewCtrl
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        self.tabBarItem = childViewCtrl.tabBarItem;

        m_view = [[AdBannerContainerView alloc] init];
        m_child_ctrl = childViewCtrl;
        _shouldAutorotate = true;
    }
    return self;
}

- (UINavigationItem *)navigationItem
{
    return m_child_ctrl.navigationItem;
}

-(UIViewController*)childViewCtrl
{
    assert(false); // subclass must override
    return nil;
}

- (void)loadView
{
    [m_child_ctrl willMoveToParentViewController:self];
    [self addChildViewController:m_child_ctrl];
    [m_view placeContentView:m_child_ctrl.view];
    [m_child_ctrl didMoveToParentViewController:self];

    self.view  = m_view;
}

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

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    [[AdBannerManager sharedInstance] adContainerDidLayoutSubviews:self];
}

- (void)placeBannerView:(UIView*)bannerView
{
    [m_view placeBannerView:bannerView];
}

- (void)bannerViewWasRemoved
{
    [m_view bannerViewWasRemoved];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations { // iOS 6
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskAllButUpsideDown;
}

@end
