//
//  VideoCell.m
//  zgnx
//
//  Created by tangwei1 on 16/5/26.
//  Copyright © 2016年 tangwei1. All rights reserved.
//

#import "VideoCell.h"
#import "Defines.h"
#import <UIImageView+AFNetworking.h>
#import "StaticToolbar.h"
#import "AppDelegate.h"
//#import "ViewHistory.h"
//#import "ViewHistoryTable.h"
//#import "Stream.h"
#import "Defines.h"
#import "DMSManager.h"

NSString * const kVideoCellDidSelectNotification = @"kVideoCellDidSelectNotification";
NSString * const kVideoCellDidDeleteNotification = @"kVideoCellDidDeleteNotification";

@interface VideoCell () <UIAlertViewDelegate>

@property (nonatomic, strong) UIView*      containerView;
@property (nonatomic, strong) UILabel*     titleLabel;
@property (nonatomic, strong) UIImageView* coverImageView;

@property (nonatomic, strong) UIImageView* playIconView;
@property (nonatomic, strong) UILabel*     viewCountLabel;

@property (nonatomic, strong) UIImageView* msgIconView;
@property (nonatomic, strong) UILabel*     msgCountLabel;

@property (nonatomic, strong) UIImageView* likeIconView;
@property (nonatomic, strong) UILabel*     likeCountLabel;

//@property (nonatomic, strong, readwrite) NSMutableDictionary *cellData;
@property (nonatomic, strong, readwrite) Stream *stream;

@property (nonatomic, strong) UIButton *deleteButton;

@property (nonatomic, strong) UILabel *approvedLabel;

@end

@implementation VideoCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ( self = [super initWithStyle:style reuseIdentifier:reuseIdentifier] ) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateStream:)
                                                     name:@"kNeedReloadDataNotification"
                                                   object:nil];
    }
    return self;
}

- (void)doEdit
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.deleteButton.hidden = NO;
}

- (void)doneEdit
{
    self.deleteButton.hidden = YES;
}

- (void)updateStream:(NSNotification *)noti
{
    if ( [self.stream.stream_id isEqualToString:[noti.object stream_id]] ) {
        self.stream.liked = [noti.object liked];
    }
}

- (void)configData:(id)data
{
    if ( [data isKindOfClass:[NSDictionary class]] ) {
        self.stream = [[Stream alloc] initWithDictionary:data];
    } else if ( [data isKindOfClass:[Stream class]] ) {
        self.stream = data;
    }
    
    NSLog(@"sid: %@", self.stream.stream_id);
    
    self.titleLabel.text = self.stream.title;

    self.coverImageView.image = nil;
    self.coverImageView.userInteractionEnabled = NO;
    self.coverImageView.backgroundColor = [UIColor grayColor];
    
    NSURL *url = [NSURL URLWithString:self.stream.cover_image];
    NSLog(@"url: %@", url);
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    __weak typeof(self) weakSelf = self;
    [self.coverImageView setImageWithURLRequest:request
                               placeholderImage:nil
                                        success:
     ^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
        weakSelf.coverImageView.image = image;
        weakSelf.coverImageView.userInteractionEnabled = YES;
    } failure:
     ^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
                                            
    }];
    
    NSInteger viewCount = [self.stream.view_count integerValue];
    NSInteger msgCount  = [self.stream.msg_count integerValue];
    NSInteger likeCount = [self.stream.likes_count integerValue];
    
    NSString* viewCountText = viewCount >= 10000 ? [NSString stringWithFormat:@"%.1f万", viewCount / 10000.0] : [self.stream.view_count description];
    
    NSString* msgCountText = msgCount >= 10000 ? [NSString stringWithFormat:@"%.1f万", msgCount / 10000.0] : [self.stream.msg_count description];
    
    NSString* likeCountText = likeCount >= 10000 ? [NSString stringWithFormat:@"%.1f万", likeCount / 10000.0] : [self.stream.likes_count description];
    
    self.viewCountLabel.text = viewCountText;
    self.msgCountLabel.text  = msgCountText;
    self.likeCountLabel.text = likeCountText;
//    self.msgCountLabel.hidden = YES;
    
//    NSLog(@"type: %@, video_file: %@, sid: %@", self.stream.type,
//          self.stream.video_file, self.stream.stream_id);
    if ( [self.stream.type integerValue] == 1 &&
        [self.stream.video_file length] == 0 ) {
        
        NSString *topic = [NSString stringWithFormat:@"u%@", self.stream.stream_id];
        
        // 订阅实时用户消息
        AppDelegate *app = [UIApplication sharedApplication].delegate;
        DMSManager *dmsManager = app.dmsManager;
        [dmsManager addMessageHandler:^(MQTTMessage *message) {
            if ( [message.topic isEqualToString:topic] ) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSInteger count = [message.payloadString integerValue];
                    NSString* viewCountText2 = count >= 10000 ? [NSString stringWithFormat:@"%.1f万", count / 10000.0] : message.payloadString;
                    self.viewCountLabel.text = viewCountText2;
                });
            }
        }];
        [dmsManager subscribe:topic
                   completion:^(BOOL succeed, NSError *error) {
                       if ( succeed ) {
                           NSLog(@"订阅实时用户数消息成功");
                       } else {
                           NSLog(@"ady: %@", error);
                       }
                   }];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.didSelectItem = nil;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.containerView.frame = [[self class] calcuContainerViewFrame];
    
    self.titleLabel.frame = CGRectMake(10, 0, self.containerView.width - 20, 30);
    
    self.coverImageView.frame = CGRectInset(self.containerView.bounds, 0, 30);
    
    if ( self.stream.fromType == StreamFromTypeUploaded &&
        [self.stream.type integerValue] == 2 &&
        [self.stream.approved boolValue] == NO) {
        self.approvedLabel.frame = CGRectMake(self.coverImageView.right - 60, self.coverImageView.top + 10,
                                              60, 20);
    }
    
    self.playIconView.center = CGPointMake(10 + self.playIconView.width/2,
                                           self.coverImageView.bottom + 15);
    self.viewCountLabel.frame = CGRectMake(self.playIconView.right + 5,
                                           self.coverImageView.bottom,
                                           self.containerView.width / 2 - self.playIconView.width - 5,
                                           30);
    CGSize size = [self.msgCountLabel.text sizeWithAttributes:@{ NSFontAttributeName: self.msgCountLabel.font }];
    self.msgCountLabel.frame = CGRectMake(self.containerView.width -
                                          self.playIconView.left - size.width,
                                          self.viewCountLabel.top,
                                          size.width,
                                          30);
    self.msgIconView.center = CGPointMake(self.msgCountLabel.left - 5
                                          - self.msgIconView.width/2,
                                          self.msgCountLabel.midY);
    
    self.likeIconView.frame = CGRectMake(0, 0, 16 * 11 / 12.0, 16);
    self.likeIconView.center = CGPointMake(self.containerView.width / 2 ,
                                           self.msgIconView.midY);
    
    size = [self.likeCountLabel.text sizeWithAttributes:@{ NSFontAttributeName: self.likeCountLabel.font }];
    
    self.likeCountLabel.frame = CGRectMake(0, 0, size.width, size.height );
    self.likeCountLabel.center = CGPointMake(self.containerView.width / 2 + 8 + self.likeIconView.width, self.msgIconView.midY);
    
    self.likeIconView.left = self.likeCountLabel.left - 8 - self.likeIconView.width;
    
    if ( self.stream.fromType == StreamFromTypeHistory ||
        self.stream.fromType == StreamFromTypeUploaded ) {
        self.deleteButton.center = CGPointMake(self.containerView.width / 2,
                                               self.containerView.height / 2);
    }
}

+ (CGRect)calcuContainerViewFrame
{
    static CGRect frame;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        frame = CGRectMake(kThumbLeft, kThumbTop,
                           AWFullScreenWidth() - kThumbLeft * 2,
                           (AWFullScreenWidth() - kThumbLeft * 2) * 0.618 + 60 );
    });
    return frame;
}

+ (CGFloat)cellHeight
{
    return CGRectGetMaxY([self calcuContainerViewFrame]);
}

- (UIView *)containerView
{
    if ( !_containerView ) {
        _containerView = [[UIView alloc] init];
        [self.contentView addSubview:_containerView];
        _containerView.backgroundColor = [UIColor whiteColor];
        
        UILongPressGestureRecognizer *longPress =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePress:)];
        longPress.minimumPressDuration = 0.3;
        [_containerView addGestureRecognizer:longPress];
    }
    return _containerView;
}

- (UILabel *)titleLabel
{
    if ( !_titleLabel ) {
        _titleLabel = AWCreateLabel(CGRectZero, nil, NSTextAlignmentLeft,
                                    AWSystemFontWithSize(15, NO),
                                    [UIColor blackColor]);
        _titleLabel.backgroundColor = [UIColor whiteColor];
        [self.containerView addSubview:_titleLabel];
    }
    return _titleLabel;
}

- (UILabel *)approvedLabel
{
    if ( !_approvedLabel ) {
        _approvedLabel = AWCreateLabel(CGRectZero, @"等待审核", NSTextAlignmentCenter,
                                    AWSystemFontWithSize(12, NO),
                                    [UIColor whiteColor]);
        _approvedLabel.backgroundColor = NAV_BAR_BG_COLOR;
        [self.containerView addSubview:_approvedLabel];
    }
    return _approvedLabel;
}

- (UIImageView *)coverImageView
{
    if ( !_coverImageView ) {
        _coverImageView = AWCreateImageView(nil);
        _coverImageView.userInteractionEnabled = NO;
        _coverImageView.backgroundColor = [UIColor grayColor];//AWColorFromRGB(137, 137, 137);
        [_coverImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)]];
        [self.containerView addSubview:_coverImageView];
    }
    return _coverImageView;
}

- (UIImageView *)playIconView
{
    if ( !_playIconView ) {
        _playIconView = AWCreateImageView(@"tags_play.png");
//        _playIconView.backgroundColor = [UIColor grayColor];
        [self.containerView addSubview:_playIconView];
    }
    return _playIconView;
}

- (UILabel *)viewCountLabel
{
    if ( !_viewCountLabel ) {
        _viewCountLabel = AWCreateLabel(CGRectZero, nil, NSTextAlignmentLeft,
                                    nil,
                                    [UIColor grayColor]);
        _viewCountLabel.backgroundColor = [UIColor whiteColor];
        [self.containerView addSubview:_viewCountLabel];
    }
    return _viewCountLabel;
}

- (UIImageView *)msgIconView
{
    if ( !_msgIconView ) {
        _msgIconView = AWCreateImageView(@"tags_comment.png");
//        _msgIconView.backgroundColor = [UIColor grayColor];
        [self.containerView addSubview:_msgIconView];
    }
    return _msgIconView;
}

- (UILabel *)msgCountLabel
{
    if ( !_msgCountLabel ) {
        _msgCountLabel = AWCreateLabel(CGRectZero, nil, NSTextAlignmentRight,
                                        nil,
                                        [UIColor grayColor]);
        _msgCountLabel.backgroundColor = [UIColor clearColor];
        [self.containerView addSubview:_msgCountLabel];
    }
    return _msgCountLabel;
}

- (UIImageView *)likeIconView
{
    if ( !_likeIconView ) {
        _likeIconView = AWCreateImageView(@"tags_zan_n.png");
        //        _msgIconView.backgroundColor = [UIColor grayColor];
        [self.containerView addSubview:_likeIconView];
    }
    return _likeIconView;
}

- (UILabel *)likeCountLabel
{
    if ( !_likeCountLabel ) {
        _likeCountLabel = AWCreateLabel(CGRectZero, nil, NSTextAlignmentLeft,
                                       nil,
                                       [UIColor grayColor]);
        [self.containerView addSubview:_likeCountLabel];
    }
    return _likeCountLabel;
}

- (void)handlePress:(UILongPressGestureRecognizer *)gesture
{
    if ( gesture.state == UIGestureRecognizerStateBegan ) {
        [[[UIAlertView alloc] initWithTitle:@"您确定吗？"
                                    message:@"删除之后数据无法恢复"
                                   delegate:self
                          cancelButtonTitle:nil
                          otherButtonTitles:@"确定", @"取消", nil] show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ( buttonIndex == 0 ) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kVideoCellDidDeleteNotification object:self];
    }
}

- (void)tap
{
    if ( self.didSelectItem ) {
        self.didSelectItem(self);
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kVideoCellDidSelectNotification object:self];
    }
}

@end
