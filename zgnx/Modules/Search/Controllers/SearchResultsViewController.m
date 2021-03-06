//
//  SearchResultsViewController.m
//  zgnx
//
//  Created by tangwei1 on 16/6/2.
//  Copyright © 2016年 tangwei1. All rights reserved.
//

#import "SearchResultsViewController.h"
#import "Defines.h"
#import "LoadDataService.h"
#import "VideoCell.h"

@interface SearchResultsViewController ()

@property (nonatomic, copy) NSString* keyword;
@property (nonatomic, strong) LoadDataService* dataService;
@property (nonatomic, assign) NSUInteger videoType;

@end

@implementation SearchResultsViewController

- (instancetype)initWithKeyword:(NSString *)keyword
                      videoType:(NSUInteger)videoType
{
    if ( self = [super init] ) {
        
        self.fromType = StreamFromTypeDefault;
        
        self.keyword = keyword;
        self.videoType = videoType;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navBar.title = self.keyword;
}

- (void)loadDataForPage:(NSInteger)page
{
    [super loadDataForPage:page];
    
    if ( !self.dataService ) {
        self.dataService = [[LoadDataService alloc] init];
    }
    
    NSString *token = [[UserService sharedInstance] currentUser].authToken ?: @"";
    __weak typeof(self)weakSelf = self;
    [self.dataService GET:API_SEARCH_VIDEOS
                   params:@{ @"q" : self.keyword,
                             @"page": @(page),
                             @"size": @(kPageSize),
                             @"token": token,
                             @"type": @(self.videoType),
                             }
               completion:^(id result, NSError *error) {
        [weakSelf finishLoading:[result objectForKey:@"data"] error:error];
    }];
}

@end
