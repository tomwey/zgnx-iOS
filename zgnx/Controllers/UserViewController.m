//
//  UserViewController.m
//  zgnx
//
//  Created by tangwei1 on 16/5/24.
//  Copyright © 2016年 tangwei1. All rights reserved.
//

#import "UserViewController.h"
#import "Defines.h"

@implementation UserViewController

- (instancetype)initWithAuthToken:(NSString *)token
{
    if (self = [super init]) {
        [self createTabBarItemWithTitle:@"我的"
                                  image:nil
                          selectedImage:nil
                    titleTextAttributes:@{ NSFontAttributeName : AWSystemFontWithSize(16, NO) }];
    }
    return self;
}

@end
