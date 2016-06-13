//
//  VideoPlayerView.m
//  zgnx
//
//  Created by tangwei1 on 16/6/13.
//  Copyright © 2016年 tangwei1. All rights reserved.
//

#import "VideoPlayerView.h"
#import "NELivePlayer.h"
#import "NELivePlayerController.h"
#import "NELivePlayerControl.h"
#import "Defines.h"

@interface VideoPlayerView ()

@property (nonatomic, strong) id <NELivePlayer> livePlayer;

@property (nonatomic, strong) NELivePlayerControl *mediaControl;
@property (nonatomic, strong) UIControl           *controlOverlay;

@property (nonatomic, strong) UIView *topControlView;
@property (nonatomic, strong) UIView *bottomControlView;

@property (nonatomic, strong) UILabel  *currentTimeLabel;
@property (nonatomic, strong) UILabel  *totalTimeLabel;
@property (nonatomic, strong) UISlider *progressSlider;

@property (nonatomic, strong) UIActivityIndicatorView *bufferingIndicator;

@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *quitButton;
@property (nonatomic, strong) UIButton *scaleButton;

@property (nonatomic, strong) NSMutableArray *bottomExtraItems;
@property (nonatomic, strong) NSMutableArray *topExtraItems;

@property (nonatomic, strong) NSTimer *progressTimer;
@property (nonatomic, strong) NSTimer *autoHideTimer;

@property (nonatomic, assign) VideoPlayerMode playerMode;

@end

@implementation VideoPlayerView

- (instancetype)initWithContentURL:(NSURL *)url params:(NSDictionary *)params
{
    if ( self = [super init] ) {
        
        self.playerMode = VideoPlayerModeDefault;
        
        self.livePlayer = [[NELivePlayerController alloc] initWithContentURL:url];
        [self.livePlayer setScalingMode:NELPMovieScalingModeAspectFit];
        [self addSubview:self.livePlayer.view];
        
        [self.livePlayer setShouldAutoplay:YES];
        [self.livePlayer setPauseInBackground: NO];
        
        self.mediaControl = [[NELivePlayerControl alloc] init];
        [self.mediaControl addTarget:self
                              action:@selector(onMediaControlClick)
                    forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.mediaControl];
        
        self.mediaControl.delegatePlayer = self.livePlayer;
        
        // 控制
        self.controlOverlay = [[UIControl alloc] init];
        [self.mediaControl addSubview:self.controlOverlay];
        [self.controlOverlay addTarget:self
                                action:@selector(onControlOverlayClick)
                      forControlEvents:UIControlEventTouchUpInside];
        self.controlOverlay.hidden = YES;
        
        self.topControlView = [[UIView alloc] init];
        [self.controlOverlay addSubview:self.topControlView];
        self.topControlView.backgroundColor = [UIColor blackColor];
        self.topControlView.alpha = 0.8;
        
        self.bottomControlView = [[UIView alloc] init];
        [self.controlOverlay addSubview:self.bottomControlView];
        self.bottomControlView.backgroundColor = [UIColor blackColor];
        self.bottomControlView.alpha = 0.8;
        
        // 退出按钮
        self.quitButton = AWCreateImageButton(@"btn_player_quit.png", self, @selector(quitPlay));
        [self.topControlView addSubview:self.quitButton];
        
        // 播放按钮
        self.playButton = AWCreateImageButton(@"btn_player_play.png", self, @selector(play));;
        [self.bottomControlView addSubview:self.playButton];
        
        // 全屏按钮
        self.scaleButton = AWCreateImageButton(@"btn_player_scale01.png", self, @selector(gotoFullscreen));
        [self.bottomControlView addSubview:self.scaleButton];
        
        self.currentTimeLabel = AWCreateLabel(CGRectZero,
                                              @"00:00:00",
                                              NSTextAlignmentCenter,
                                              AWSystemFontWithSize(10.0, NO),
                                              AWColorFromRGB(191, 191, 191));
        [self.bottomControlView addSubview:self.currentTimeLabel];
        
        // 进度条
        self.progressSlider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, 0, 30)];
        [self.bottomControlView addSubview:self.progressSlider];
        [self.progressSlider addTarget:self action:@selector(updateProgress) forControlEvents:UIControlEventValueChanged];
        
        [[UISlider appearance] setThumbImage:[UIImage imageNamed:@"btn_player_slider_thumb"] forState:UIControlStateNormal];
        [[UISlider appearance] setMaximumTrackImage:[UIImage imageNamed:@"btn_player_slider_all"] forState:UIControlStateNormal];
        [[UISlider appearance] setMinimumTrackImage:[UIImage imageNamed:@"btn_player_slider_buffered.png"] forState:UIControlStateNormal];
        
        // 总时间
        self.totalTimeLabel = AWCreateLabel(CGRectZero,
                                            @"--:--:--",
                                            NSTextAlignmentCenter,
                                            self.currentTimeLabel.font,
                                            self.currentTimeLabel.textColor);
        [self.bottomControlView addSubview:self.totalTimeLabel];
        
        // 缓冲进度动画
        self.bufferingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self addSubview:self.bufferingIndicator];
        self.bufferingIndicator.hidesWhenStopped = YES;
        
        [self addNotifications];
        
        // 添加播放进度定时器
        self.progressTimer = [NSTimer timerWithTimeInterval:0.5
                                                     target:self
                                                   selector:@selector(updatePlayProgress)
                                                   userInfo:nil
                                                    repeats:YES];
        [self.progressTimer setFireDate:[NSDate distantFuture]];
        [[NSRunLoop currentRunLoop] addTimer:self.progressTimer forMode:NSRunLoopCommonModes];
        
        // 添加自动隐藏定时器
        self.autoHideTimer = [NSTimer timerWithTimeInterval:5.0
                                                     target:self
                                                   selector:@selector(autoHide)
                                                   userInfo:nil
                                                    repeats:YES];
        [self.autoHideTimer setFireDate:[NSDate distantFuture]];
        [[NSRunLoop currentRunLoop] addTimer:self.autoHideTimer forMode:NSRunLoopCommonModes];
        
        [self.livePlayer prepareToPlay];
        
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.livePlayer.view.frame = self.bounds;
    self.mediaControl.frame    = self.bounds;
    self.controlOverlay.frame  = self.bounds;
    
    self.bufferingIndicator.center = CGPointMake(self.width / 2, self.height / 2);
    
    self.topControlView.frame  = CGRectMake(0, 0, self.width, 40);
    self.quitButton.frame      = CGRectMake(10, 0, 40, 40);
    
    __block CGFloat right = self.width;
    
    // 布局其他额外的控件
    [self.topExtraItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIView *view = (UIView *)obj;
        view.position = CGPointMake(right - view.width - 10, self.topControlView.height / 2.0 - view.height / 2.0);
        right = view.right;
    }];
    
    self.bottomControlView.frame = CGRectMake(0, self.height - 50, self.width, 50);
    
    self.scaleButton.frame       = CGRectMake(self.bottomControlView.width - 10 - 40, 5, 40, 40);
    self.playButton.frame        = CGRectMake(10, 5, 40, 40);
    self.currentTimeLabel.frame  = CGRectMake(self.playButton.right + 5,
                                              self.bottomControlView.height / 2 - 20 / 2,
                                              50, 20);
    
    __block CGFloat left = self.scaleButton.left;
    
    // 布局其他额外控件
    [self.bottomExtraItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIView *view = (UIView *)obj;
        view.position = CGPointMake(left - 10 - view.width, self.bottomControlView.height / 2.0 - view.height / 2.0);
        left = view.left;
    }];
    
    self.totalTimeLabel.frame = CGRectMake(left - 10 - 50, self.currentTimeLabel.top,
                                           50, 20);
    
    CGFloat width = self.totalTimeLabel.left - 5 - self.currentTimeLabel.right - 5;
    self.progressSlider.frame = CGRectMake(self.currentTimeLabel.right + 5, self.bottomControlView.height / 2 - 30 / 2.0,
                                           width, 30);
}

- (void)addNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(NELivePlayerDidPreparedToPlay:)
                                                 name:NELivePlayerDidPreparedToPlayNotification
                                               object:self.livePlayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(NeLivePlayerloadStateChanged:)
                                                 name:NELivePlayerLoadStateChangedNotification
                                               object:self.livePlayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(NELivePlayerPlayBackFinished:)
                                                 name:NELivePlayerPlaybackFinishedNotification
                                               object:self.livePlayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(NELivePlayerFirstVideoDisplayed:)
                                                 name:NELivePlayerFirstVideoDisplayedNotification
                                               object:self.livePlayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(NELivePlayerReleaseSuccess:)
                                                 name:NELivePlayerReleaseSueecssNotification
                                               object:self.livePlayer];
}

- (void)updatePlayProgress
{
    [self syncUIStatus];
}

- (void)autoHide
{
    self.controlOverlay.hidden = YES;
    
    [self.progressTimer setFireDate:[NSDate distantFuture]];
    [self.autoHideTimer setFireDate:[NSDate distantFuture]];
}

- (void)dealloc
{
    [self.livePlayer shutdown];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addExtraItemsAtBottomControl:(NSArray<UIView *> *)items
{
    if ( items == nil ) {
        [self.bottomExtraItems enumerateObjectsUsingBlock:^(UIView*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            UIView *item = (UIView *)obj;
            [item removeFromSuperview];
        }];
        [self.bottomExtraItems removeAllObjects];
    } else {
        [items enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.bottomExtraItems addObject:obj];
            [self.bottomControlView addSubview:(UIView *)obj];
        }];
    }
}

- (void)addExtraItemsAtTopControl:(NSArray *)items
{
    if ( items == nil ) {
        [self.topExtraItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            UIView *item = (UIView *)obj;
            [item removeFromSuperview];
        }];
        [self.topExtraItems removeAllObjects];
    } else {
        [items enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.topExtraItems addObject:obj];
            [self.topControlView addSubview:(UIView *)obj];
        }];
    }
}

- (void)syncUIStatus
{
    NSTimeInterval duration = [self.livePlayer duration];
    NSInteger inDuration = round(duration);
    
    NSTimeInterval currentPos = [self.livePlayer currentPlaybackTime];
    NSInteger inCurrentPos = round(currentPos);
    
    self.currentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d",
                                  (int) ( inCurrentPos / 3600 ),
                                  (int) ( inCurrentPos / 60 ),
                                  (int) ( inCurrentPos % 60 )];
    
    if ( inDuration > 0 ) {
        self.totalTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d",
                                    (int) ( inDuration / 3600 ),
                                    (int) ( inDuration / 60 ),
                                    (int) ( inDuration % 60 )];
        self.progressSlider.value = currentPos;
        self.progressSlider.maximumValue = duration;
    } else {
        self.progressSlider.value = 0.0f;
    }
    
    if ( [self.livePlayer playbackState] == NELPMoviePlaybackStatePlaying ) {
        [self.playButton setImage:[UIImage imageNamed:@"btn_player_play.png"] forState:UIControlStateNormal];
    } else {
        [self.playButton setImage:[UIImage imageNamed:@"btn_player_pause.png"] forState:UIControlStateNormal];
    }
}

#pragma mark - 
#pragma mark Target - Actions
- (void)onMediaControlClick
{
    self.controlOverlay.hidden = NO;
    
    [self.autoHideTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:5.0]];
    [self.progressTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    
    [self syncUIStatus];
}

- (void)onControlOverlayClick
{
    [self autoHide];
}

- (void)quitPlay
{
    if ( self.playerMode == VideoPlayerModeDefault ) {
        if ( self.didShutdownPlayerBlock ) {
            
            [self.autoHideTimer invalidate];
            [self.progressTimer invalidate];
            
            [self.livePlayer shutdown];
            
            self.didShutdownPlayerBlock(self);
        }
    } else {
        [self gotoFullscreen];
    }
}

- (void)play
{
    if ( [self.livePlayer playbackState] == NELPMoviePlaybackStatePlaying ) {
        [self.livePlayer shutdown];
        
        [self.playButton setImage:[UIImage imageNamed:@"btn_player_pause.png"] forState:UIControlStateNormal];
        
        [self syncUIStatus];
    } else {
        [self.livePlayer play];
        
        [self.playButton setImage:[UIImage imageNamed:@"btn_player_play.png"] forState:UIControlStateNormal];
        
        [self syncUIStatus];
    }
}

- (void)gotoFullscreen
{
    if ( self.playerMode == VideoPlayerModeDefault ) {
        self.playerMode = VideoPlayerModeFullscreen;
    } else {
        self.playerMode = VideoPlayerModeDefault;
    }
    
    if ( self.didTogglePlayerModeBlock ) {
        self.didTogglePlayerModeBlock(self, self.playerMode);
    }
}

- (void)updateProgress
{
    if ( self.mediaType == VideoPlayerMediaTypeLive ) {
        return;
    }
    
    [self.livePlayer setCurrentPlaybackTime:self.progressSlider.value];
    
    [self syncUIStatus];
}

#pragma mark -
#pragma mark Notification
- (void)NELivePlayerDidPreparedToPlay:(NSNotification*)notification
{
    //add some methods
    NSLog(@"NELivePlayerDidPreparedToPlay");
    
    [self syncUIStatus];
    
    [self.livePlayer play]; //开始播放
}

- (void)NeLivePlayerloadStateChanged:(NSNotification*)notification
{
    NELPMovieLoadState nelpLoadState = self.livePlayer.loadState;
    
    if (nelpLoadState == NELPMovieLoadStatePlaythroughOK)
    {
        NSLog(@"finish buffering");
        [self.bufferingIndicator stopAnimating];
    }
    else if (nelpLoadState == NELPMovieLoadStateStalled)
    {
        NSLog(@"begin buffering");
        [self.bufferingIndicator startAnimating];
    }
}

- (void)NELivePlayerPlayBackFinished:(NSNotification*)notification
{
    switch ([[[notification userInfo] valueForKey:NELivePlayerPlaybackDidFinishReasonUserInfoKey] intValue])
    {
        case NELPMovieFinishReasonPlaybackEnded:
            if (self.mediaType == VideoPlayerMediaTypeLive) {
                [[[UIAlertView alloc] initWithTitle:@"提示"
                                           message:@"直播结束"
                                          delegate:nil
                                 cancelButtonTitle:nil
                                 otherButtonTitles:@"OK", nil] show];
            }
            break;
            
        case NELPMovieFinishReasonPlaybackError:
            [[[UIAlertView alloc] initWithTitle:@"注意"
                                        message:@"播放失败"
                                       delegate:nil
                              cancelButtonTitle:nil
                              otherButtonTitles:@"OK", nil] show];
            break;
            
        case NELPMovieFinishReasonUserExited:
            break;
            
        default:
            break;
    }
}

- (void)NELivePlayerFirstVideoDisplayed:(NSNotification*)notification
{
    NSLog(@"first video frame rendered!");
}

- (void)NELivePlayerReleaseSuccess:(NSNotification*)notification
{
    NSLog(@"resource release success!");
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NELivePlayerReleaseSueecssNotification
                                                  object:self.livePlayer];
}

#pragma mark -
#pragma mark Getters and Setters
- (NSMutableArray *)bottomExtraItems
{
    if ( !_bottomExtraItems ) {
        _bottomExtraItems = [[NSMutableArray alloc] init];
    }
    return _bottomExtraItems;
}

- (NSMutableArray *)topExtraItems
{
    if ( !_topExtraItems ) {
        _topExtraItems = [[NSMutableArray alloc] init];
    }
    return _topExtraItems;
}

@end
