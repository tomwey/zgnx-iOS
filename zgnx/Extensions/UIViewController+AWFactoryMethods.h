//
//  AWFactoryMethods.h
//  zgnx
//
//  Created by tangwei1 on 16/5/24.
//  Copyright © 2016年 tangwei1. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (AWFactoryMethods)

+ (UIViewController *)viewControllerWithClass:(Class)controllerClz;

+ (UIViewController *)viewControllerWithClassName:(NSString *)controllerClassName;

@end
