//
//  VideoStreamModule.h
//  zgnx
//
//  Created by tangwei1 on 16/5/25.
//  Copyright © 2016年 tangwei1. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CTMediator.h"

@interface CTMediator (ViewHistoryModule)

- (UIViewController *)CTMediator_openViewHistoryVCWithAuthToken:(NSString *)authToken;

@end
