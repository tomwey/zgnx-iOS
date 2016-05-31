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

@interface VODListView () <ReloadDelegate, UITableViewDelegate>

@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic, strong) AWTableViewDataSource* dataSource;

@property (nonatomic, weak) UIRefreshControl* refreshControl;

@property (nonatomic, assign) NSUInteger currentPage;

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
//    self.allowLoadingNextPage = YES;
    
    self.dataSource = [[AWTableViewDataSource alloc] initWithArray:nil
                                                         cellClass:@"VideoCell"
                                                        identifier:@"video.cell.id"];
    
    self.tableView =
    [[UITableView alloc] initWithFrame:self.bounds style:UITableViewStylePlain];
    
    self.tableView.dataSource = self.dataSource;
    self.tableView.delegate   = self;
    
    [self addSubview:self.tableView];
    
    self.tableView.autoresizingMask =
    UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.tableView removeBlankCells];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = [VideoCell cellHeight];
    self.tableView.showsVerticalScrollIndicator = NO;
    
    UIRefreshControl* refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(startLoad) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    
    refreshControl.tintColor = NAV_BAR_BG_COLOR;
    
    self.refreshControl = refreshControl;
    
    // 加载更多组件
//    LoadMoreView* lmv = [[LoadMoreView alloc] init];
//    __weak typeof(self) weakSelf = self;
//    [self.tableView addFooterLoadMoreView:lmv withCallback:^{
//        weakSelf.currentPage ++;
//        [weakSelf startLoadForPage:weakSelf.currentPage completion:nil];
//    }];
//    self.loadMoreView = lmv;
}

- (void)startLoad
{
    if ( !self.refreshControl.isRefreshing ) {
        [self.refreshControl beginRefreshing];
    }
    
    [self startLoadForPage:1 completion:^(BOOL succeed) {
        [self.refreshControl endRefreshing];
    }];
}

- (void)startLoadForPage:(NSUInteger)pageNo completion:( void (^)(BOOL succeed) )completion
{
    [self.tableView removeErrorOrEmptyTips];
    
    if ( pageNo == 1 ) {
//        [MBProgressHUD showHUDAddedTo:self animated:YES];
    }
    
    [[VODService sharedInstance] loadWithCatalogID:_catalogID
                                              page:pageNo
                                        completion:
     ^(id results, NSError *error) {
         
         [self.tableView footerLoadMoreViewEndLoading];
         
         if ( error ) {
             [self.tableView showErrorOrEmptyMessage:@"Oops, 加载失败了！点击重试" reloadDelegate:self];
             return;
         }
         
        if ( [results[@"data"] count] > 0 ) {
//            self.allowLoadingNextPage = YES;
            if ( pageNo > 1 ) {
                NSMutableArray* temp = [NSMutableArray arrayWithArray:self.dataSource.dataSource];
                [temp addObjectsFromArray:results[@"data"]];
                self.dataSource.dataSource = [NSArray arrayWithArray:temp];
            } else {
                self.dataSource.dataSource = results[@"data"];
            }
            
            [self.tableView reloadData];
        } else {
//            self.allowLoadingNextPage = YES;
            if ( pageNo == 1 ) {
                [self.tableView showErrorOrEmptyMessage:@"Oops, 没有数据！" reloadDelegate:self];
            } else {
                self.tableView.footerLoadMoreViewHidden = YES;
            }
        }
        
        if ( completion ) {
            completion(!error);
        }
    }];
}

- (void)reloadDataForErrorOrEmpty
{
    if ( self.reloadBlock ) {
        self.reloadBlock(NO);
    }
    [self startLoadForPage:1 completion:^(BOOL succeed) {
        if ( self.reloadBlock ) {
            self.reloadBlock(succeed);
        }
    }];
}

//- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if ( self.allowLoadingNextPage &&
//        [self.dataSource.dataSource count] == (kPageSize * self.currentPage) &&
//        indexPath.row == [self.dataSource.dataSource count] - 1  ) {
//        
//        self.allowLoadingNextPage = NO;
//        
//        self.currentPage ++;
//        
//        [self startLoadForPage:self.currentPage completion:nil];
//    }
//}

@end
