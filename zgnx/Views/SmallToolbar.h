//
//  SmallToolbar.h
//  zgnx
//
//  Created by tangwei1 on 16/6/3.
//  Copyright © 2016年 tangwei1. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ToolbarButtonTag) {
    ToolbarButtonTagBili  = 100,
    ToolbarButtonTagShare = 101,
    ToolbarButtonTagLike  = 102,
};

@class Stream;
@interface SmallToolbar : UIView

- (instancetype)initWithStream:(Stream *)aStream;

//@property (nonatomic, strong) id videoInfo;

@property (nonatomic, strong) Stream *stream;

@property (nonatomic, copy) void (^toolbarButtonDidTapBlock)(UIButton* sender);

@end
