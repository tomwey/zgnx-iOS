//
//  VODListView.m
//  zgnx
//
//  Created by tangwei1 on 16/5/26.
//  Copyright © 2016年 tangwei1. All rights reserved.
//

#import "VODListView.h"
#import <AWTableView/AWTableViewDataSource.h>
#import "VODService.h"
#import <AWTableView/UITableView+RemoveBlankCells.h>
#import <AWTableView/UITableView+LoadEmptyOrErrorHandle.h>
#import "Defines.h"
#import "VideoCell.h"
#import "BannerView.h"

@interface VODListView () <ReloadDelegate, UITableViewDelegate>

@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic, strong) AWTableViewDataSource* dataSource;

@property (nonatomic, weak) UIRefreshControl* refreshControl;

@property (nonatomic, assign) NSUInteger currentPage;

@property (nonatomic, assign) BOOL hasNextPage;
@property (nonatomic, assign) BOOL allowLoading;

@property (nonatomic, strong) BannerView *bannerView;

@end
@implementation VODListView

- (instancetype)initWithFrame:(CGRect)frame
{
    if ( self = [super initWithFrame:frame] ) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.currentPage = 1;
    self.hasNextPage = NO;
    self.allowLoading = YES;
    
    self.dataSource = [[AWTableViewDataSource alloc] initWithArray:nil
                                                         cellClass:@"VideoCell"
                                                        identifier:@"video.cell.id"];
    
    self.tableView =
    [[UITableView alloc] initWithFrame:self.bounds style:UITableViewStylePlain];
    
    self.tableView.dataSource = self.dataSource;
    self.tableView.delegate   = self;
    
    [self addSubview:self.tableView];
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 10, 0);
    
    self.tableView.autoresizingMask =
    UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.tableView removeBlankCells];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = [VideoCell cellHeight];
    self.tableView.showsVerticalScrollIndicator = NO;
    
    self.bannerView = [[BannerView alloc] init];
    self.tableView.tableHeaderView = self.bannerView;
    
    __weak typeof(self)weakSelf = self;
    self.refreshControl = [self.tableView addRefreshControlWithReloadCallback:^(UIRefreshControl *control) {
        if ( control ) {
            [weakSelf startLoad];
        }
    }];
    self.refreshControl.tintColor = NAV_BAR_BG_COLOR;
}

- (void)dealloc
{
    NSLog(@"dealloc");
    [self.bannerView invalidateTimer];
}

- (void)startLoad
{
    if ( !self.refreshControl.isRefreshing ) {
        [self.refreshControl beginRefreshing];
    }
    
    self.currentPage = 1;
    __weak typeof(self)weakSelf = self;
    [self startLoadForPage:self.currentPage completion:^(BOOL succeed) {
        [weakSelf.refreshControl endRefreshing];
    }];
}

- (void)startLoadForPage:(NSUInteger)pageNo completion:( void (^)(BOOL succeed) )completion
{
    [self.tableView removeErrorOrEmptyTips];
    
    if ( pageNo == 1 ) {
//        [MBProgressHUD showHUDAddedTo:self animated:YES];
//        self.tableView.hidden = YES;
        
        __weak typeof(self) weakSelf = self;
        
        self.bannerView.categoryId = self.catalogID;
        [self.bannerView startLoading:^(id selectItem) {
            if ( weakSelf.didClickBannerBlock ) {
                weakSelf.didClickBannerBlock(selectItem);
            }
        } completionCallback:^(NSArray *result, NSError *error) {
            if ( [result count] == 0 ) {
                weakSelf.tableView.tableHeaderView = nil;
            } else {
                weakSelf.tableView.tableHeaderView = self.bannerView;
            }
        }];
    }
    
    [[VODService sharedInstance] loadWithCatalogID:_catalogID
                                              page:pageNo
                                        completion:
     ^(id results, NSError *error) {
         
         self.allowLoading = YES;
         
         if ( completion ) {
             completion(!error);
         }
         
         if ( error && pageNo == 1 ) {
             self.hasNextPage = NO;
             [self.tableView showErrorOrEmptyMessage:@"Oops, 加载失败了！点击重试" reloadDelegate:self];
             return;
         }
         
        if ( [results[@"data"] count] > 0 ) {
            if ( pageNo > 1 ) {
                NSMutableArray* temp = [NSMutableArray arrayWithArray:self.dataSource.dataSource];
                [temp addObjectsFromArray:results[@"data"]];
                self.dataSource.dataSource = [NSArray arrayWithArray:temp];
            } else {
                self.dataSource.dataSource = results[@"data"];
            }
            
            self.tableView.hidden = NO;
            [self.tableView reloadData];
            
            if ( [results[@"data"] count] < kPageSize ) {
                self.hasNextPage = NO;
            } else {
                self.hasNextPage = YES;
            }
        } else {
//            self.allowLoadingNextPage = YES;
            self.hasNextPage = NO;
            if ( pageNo == 1 ) {
                [self.tableView showErrorOrEmptyMessage:@"Oops, 没有数据！" reloadDelegate:self];
            } else {
//                self.tableView.footerLoadMoreViewHidden = YES;
            }
        }
        
    }];
}

- (void)reloadDataForErrorOrEmpty
{
    if ( self.reloadBlock ) {
        self.reloadBlock(NO);
    }
    
    __weak typeof(self) weakSelf = self;
    
    self.currentPage = 1;
    self.tableView.hidden = YES;
    [self startLoadForPage:self.currentPage completion:^(BOOL succeed) {
        if ( weakSelf.reloadBlock ) {
            weakSelf.reloadBlock(succeed);
        }
    }];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( self.hasNextPage && self.allowLoading &&
        indexPath.row == [self.dataSource.dataSource count] - 1  ) {
        
        self.allowLoading = NO;
        
        self.currentPage ++;
        
        [self startLoadForPage:self.currentPage completion:nil];
    }
}

@end
