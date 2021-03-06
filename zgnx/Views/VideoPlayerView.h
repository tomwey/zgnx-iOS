//
//  VideoPlayerView.h
//  zgnx
//
//  Created by tangwei1 on 16/6/13.
//  Copyright © 2016年 tangwei1. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, VideoPlayerMode) {
    VideoPlayerModeDefault = 0, // 默认模式，非全屏
    VideoPlayerModeFullscreen = 1, // 全屏模式，在这里表示横屏
};

typedef NS_ENUM(NSInteger, VideoPlayerMediaType) {
    VideoPlayerMediaTypeVOD,  // 点播视频
    VideoPlayerMediaTypeLive, // 直播
};

@interface VideoPlayerView : UIView

- (instancetype)initWithContentURL:(NSURL *)url params:(NSDictionary *)params;

@property (nonatomic, assign) VideoPlayerMediaType mediaType;
@property (nonatomic, assign) VideoPlayerMode playerMode;

@property (nonatomic, copy) void (^didShutdownPlayerBlock)(VideoPlayerView *view, NSTimeInterval playProgress);
@property (nonatomic, copy) void (^didTogglePlayerModeBlock)(VideoPlayerView *view, VideoPlayerMode playerMode);

@property (nonatomic, assign) NSTimeInterval currentPlaybackTime;

/** 历史弹幕消息 */
@property (nonatomic, copy) NSArray *bilibiliHistories;

/**
 * 控件位置相对于全屏切换按钮从右往左依次排列，控件之间的间距为10
 */
- (void)addExtraItemsAtBottomControl:(NSArray<UIView *> *)items;

/**
 * 控件位置相对于视图宽度从右往左依次排列，控件之间的间距为10
 */
- (void)addExtraItemsAtTopControl:(NSArray<UIView *> *)items;

/**
 * 打开弹幕
 */
- (void)openBilibili:(BOOL)yesOrNo;

/**
 * 显示弹幕
 */
- (void)showBilibili:(NSString *)msg;

@end
