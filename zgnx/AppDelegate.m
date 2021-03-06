//
//  AppDelegate.m
//  zgnx
//
//  Created by tangwei1 on 16/5/9.
//  Copyright © 2016年 tangwei1. All rights reserved.
//

#import "AppDelegate.h"
#import "Defines.h"
#import "TestViewController.h"
#import "CustomURLProtocol.h"
#import "DMSManager.h"
#import "MyImageCache.h"

@interface AppDelegate ()

@property (nonatomic, strong) DMSManager *dmsManager;

@end

@implementation AppDelegate

+ (void)load
{
    [[APIConfig sharedInstance] setProductionServer:API_HOST];
    [[APIConfig sharedInstance] setDebugMode:NO];
    
    NSURLCache* urlCache = [[NSURLCache alloc] initWithMemoryCapacity:10 * 1024 * 1024
                                                         diskCapacity:100 * 1024 * 1024
                                                             diskPath:@"zgnx-assets"];
    [NSURLCache setSharedURLCache:urlCache];
    
    // 设置图片缓存
    [UIImageView setSharedImageCache:[[MyImageCache alloc] init]];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    UINavigationController* nav = [[UINavigationController alloc] init];
    nav.navigationBarHidden = YES;
    
    UITabBarController* tabBarController = [[UITabBarController alloc] init];
    tabBarController.tabBar.barTintColor = [UIColor whiteColor];
    tabBarController.viewControllers = @[
                                         [[CTMediator sharedInstance] CTMediator_openVODVC],
                                         [[CTMediator sharedInstance] CTMediator_openLiveVC],
                                         [[CTMediator sharedInstance] CTMediator_openUserVCWithAuthToken:nil],
                                         ];
    [nav pushViewController:tabBarController animated:NO];
    
    self.window.rootViewController = nav;
//    TestViewController* tvc = [[TestViewController alloc] init];
//    self.window.rootViewController = tvc;
    
    [self.window makeKeyAndVisible];
    
    // 创建一个MQTT连接
    self.dmsManager = [[DMSManager alloc] initWithClientId:@"online.user.client"];
    [self.dmsManager connect:^(BOOL succeed, NSError *error) {
        //        NSLog(@"error:%@", error);
    }];
//    [YunBaService setupWithAppkey:YB_APP_KEY];
//    [NSURLProtocol registerClass:[CustomURLProtocol class]];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end

@implementation UINavigationController (NotAllowRotation)

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

@end
