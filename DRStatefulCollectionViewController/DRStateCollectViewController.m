//
//  DRStatefulCollectionViewController.m
//  DRStatefulCollectionViewControllerDemo
//
//  Created by Ming Hui Ho on 13/10/3.
//  Copyright (c) 2013年 Ming Hui Ho. All rights reserved.
//

#import "DRStateCollectViewController.h"

@interface SVPullToRefreshView ()

@property (nonatomic, copy) void (^pullToRefreshActionHandler)(void);

@end

@interface SVInfiniteScrollingView ()

@property (nonatomic, copy) void (^infiniteScrollingHandler)(void);

@end

static const int kLoadingCellTag = 2570;

@interface DRStateCollectViewController ()

@property (nonatomic, assign) BOOL isCountingRows;
@property (nonatomic, assign) BOOL hasAddedPullToRefreshControl;
@property (nonatomic,retain) UIRefreshControl *refreshControl;

// Loading

- (void) _loadFirstPage;
- (void) _loadNextPage;

- (void) _loadFromPullToRefresh;

// Table View Cells & NSIndexPaths

- (UITableViewCell *) _cellForLoadingCell;
- (BOOL) _indexRepresentsLastSection:(NSInteger)section;
- (BOOL) _indexPathRepresentsLastRow:(NSIndexPath *)indexPath;
- (NSInteger) _totalNumberOfRows;
- (CGFloat) _cumulativeHeightForCellsAtIndexPaths:(NSArray *)indexPaths;

@end

@implementation DRStateCollectViewController

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (!self) return nil;
    
    _statefulState = DRStateCollectViewControllerStateIdle;
    self.statefulDelegate = self;
    
    return self;
}

- (void) dealloc {
    self.statefulDelegate = nil;
}

#pragma mark - Loading Methods

- (void) loadNewer {
    if([self _totalNumberOfRows] == 0) {
        [self _loadFirstPage];
    } else {
        [self _loadFromPullToRefresh];
    }
}

- (void) _loadFirstPage {
    if(self.statefulState == DRStateCollectViewControllerStateInitialLoading || [self _totalNumberOfRows] > 0) return;
    
    self.statefulState = DRStateCollectViewControllerStateInitialLoading;
    
    [self.collectionView reloadData];
    
    [self.statefulDelegate statefulTableViewControllerWillBeginInitialLoading:self completionBlock:^{
        [self.collectionView reloadData]; // We have to call reloadData before we call _totalNumberOfRows otherwise the new count (after loading) won't be accurately reflected.
        
        if([self _totalNumberOfRows] > 0) {
            self.statefulState = DRStateCollectViewControllerStateIdle;
        } else {
            self.statefulState = DRStateCollectViewControllerStateEmpty;
        }
    } failure:^(NSError *error) {
        self.statefulState = DRStateCollectViewControllerError;
    }];
}
- (void) _loadNextPage {
    if(self.statefulState == DRStateCollectViewControllerStateLoadingNextPage) return;
    
    if([self.statefulDelegate statefulTableViewControllerShouldBeginLoadingNextPage:self]) {
        self.collectionView.showsInfiniteScrolling = YES;
        
        self.statefulState = DRStateCollectViewControllerStateLoadingNextPage;
        
        [self.statefulDelegate statefulTableViewControllerWillBeginLoadingNextPage:self completionBlock:^{
            [self.collectionView reloadData];
            
            if(![self.statefulDelegate statefulTableViewControllerShouldBeginLoadingNextPage:self]) {
                self.collectionView.showsInfiniteScrolling = NO;
            };
            
            if([self _totalNumberOfRows] > 0) {
                self.statefulState = DRStateCollectViewControllerStateIdle;
            } else {
                self.statefulState = DRStateCollectViewControllerStateEmpty;
            }
        } failure:^(NSError *error) {
            //TODO What should we do here?
            self.statefulState = DRStateCollectViewControllerStateIdle;
        }];
    } else {
        self.collectionView.showsInfiniteScrolling = NO;
    }
}

- (void) _loadFromPullToRefresh {
    if(self.statefulState == DRStateCollectViewControllerStateLoadingFromPullToRefresh) return;
    
    self.statefulState = DRStateCollectViewControllerStateLoadingFromPullToRefresh;
    
    [self.statefulDelegate statefulTableViewControllerWillBeginLoadingFromPullToRefresh:self completionBlock:^(NSArray *indexPaths) {
        if([indexPaths count] > 0) {
            CGFloat totalHeights = [self _cumulativeHeightForCellsAtIndexPaths:indexPaths];
            
            //Offset by the height of the pull to refresh view when it's expanded:
            CGFloat offset = 0.0f;
            
            if([self respondsToSelector:@selector(refreshControl)]) {
                offset = self.refreshControl.frame.size.height;
            } else {
                offset = self.collectionView.pullToRefreshView.frame.size.height;
            }
            
            [self.collectionView setContentInset:UIEdgeInsetsMake(offset, 0.0f, 0.0f, 0.0f)];
            [self.collectionView reloadData];
            
            if(self.collectionView.contentOffset.y == 0) {
                self.collectionView.contentOffset = CGPointMake(0, (self.collectionView.contentOffset.y + totalHeights) - 60.0);
            } else {
                self.collectionView.contentOffset = CGPointMake(0, (self.collectionView.contentOffset.y + totalHeights));
            }
        }
        
        self.statefulState = DRStateCollectViewControllerStateIdle;
        [self _pullToRefreshFinishedLoading];
    } failure:^(NSError *error) {
        //TODO: What should we do here?
        
        self.statefulState = DRStateCollectViewControllerStateIdle;
        [self _pullToRefreshFinishedLoading];
    }];
}

#pragma mark - Table View Cells & NSIndexPaths

- (UITableViewCell *) _cellForLoadingCell {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.center = cell.center;
    [cell addSubview:activityIndicator];
    
    [activityIndicator startAnimating];
    
    cell.tag = kLoadingCellTag;
    
    return cell;
}
- (BOOL) _indexRepresentsLastSection:(NSInteger)section {
    NSInteger totalNumberOfSections = [self numberOfSectionsInCollectionView:self.collectionView];
    if(section != (totalNumberOfSections - 1)) return NO; //section is not the last section!
    
    return YES;
}
- (BOOL) _indexPathRepresentsLastRow:(NSIndexPath *)indexPath {
    NSInteger totalNumberOfSections = [self numberOfSectionsInCollectionView:self.collectionView];
    if(indexPath.section != (totalNumberOfSections - 1)) return NO; //indexPath.section is not the last section!
    
    NSInteger totalNumberOfRowsInSection = [self collectionView:self.collectionView numberOfItemsInSection:indexPath.section];
    if(indexPath.row != (totalNumberOfRowsInSection - 1)) return NO; //indexPath.row is not the last row in this section!
    
    return YES;
}
- (NSInteger) _totalNumberOfRows {
    self.isCountingRows = YES;
    
    NSInteger numberOfRows = 0;
    
    NSInteger numberOfSections = [self numberOfSectionsInCollectionView:self.collectionView];
    for(NSInteger i = 0; i < numberOfSections; i++) {
        numberOfRows += [self collectionView:self.collectionView numberOfItemsInSection:i];
    }
    
    self.isCountingRows = NO;
    
    return numberOfRows;
}
- (CGFloat) _cumulativeHeightForCellsAtIndexPaths:(NSArray *)indexPaths {
    if(!indexPaths) return 0.0;
    
    CGFloat totalHeight = 0.0;
    
    for(NSIndexPath *indexPath in indexPaths) {
//        totalHeight += [self collectionView:self.collectionView heightForRowAtIndexPath:indexPath];
    }
    
    return totalHeight;
}

- (void) _pullToRefreshFinishedLoading {
    [self.collectionView.pullToRefreshView stopAnimating];
    if([self respondsToSelector:@selector(refreshControl)]) {
        [self.refreshControl endRefreshing];
    }
}

#pragma mark - Setter Overrides

- (void) setStatefulState:(DRStateCollectViewControllerState)statefulState {
    if([self.statefulDelegate respondsToSelector:@selector(statefulTableViewController:willTransitionToState:)]) {
        [self.statefulDelegate statefulTableViewController:self willTransitionToState:statefulState];
    }
    
	_statefulState = statefulState;
    
    switch (_statefulState) {
        case DRStateCollectViewControllerStateIdle:
            [self.collectionView.infiniteScrollingView stopAnimating];
            
            self.collectionView.backgroundView = nil;
            [self.loadingView removeFromSuperview];
//            self.collectionView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
            self.collectionView.scrollEnabled = YES;
//            self.collectionView.tableHeaderView.hidden = NO;
//            self.collectionView.tableFooterView.hidden = NO;
            [self.collectionView reloadData];
            
            break;
            
        case DRStateCollectViewControllerStateInitialLoading:
            self.collectionView.backgroundView = self.loadingView;
//            self.collectionView.separatorStyle = UITableViewCellSeparatorStyleNone;
            self.collectionView.scrollEnabled = NO;
//            self.collectionView.tableHeaderView.hidden = YES;
//            self.collectionView.tableFooterView.hidden = YES;
            [self.collectionView reloadData];
            
            break;
            
        case DRStateCollectViewControllerStateEmpty:
            [self.collectionView.infiniteScrollingView stopAnimating];
            
            self.collectionView.backgroundView = self.emptyView;
//            self.collectionView.separatorStyle = UITableViewCellSeparatorStyleNone;
            self.collectionView.scrollEnabled = NO;
//            self.collectionView.tableHeaderView.hidden = YES;
//            self.collectionView.tableFooterView.hidden = YES;
            [self.collectionView reloadData];
            
        case DRStateCollectViewControllerStateLoadingNextPage:
            // TODO
            break;
            
        case DRStateCollectViewControllerStateLoadingFromPullToRefresh:
            // TODO
            break;
            
        case DRStateCollectViewControllerError:
            [self.collectionView.infiniteScrollingView stopAnimating];
            
            self.collectionView.backgroundView = self.errorView;
//            self.collectionView.separatorStyle = UITableViewCellSeparatorStyleNone;
            self.collectionView.scrollEnabled = NO;
//            self.collectionView.tableHeaderView.hidden = YES;
//            self.collectionView.tableFooterView.hidden = YES;
            [self.collectionView reloadData];
            break;
            
        default:
            break;
    }
    
    if([self.statefulDelegate respondsToSelector:@selector(statefulTableViewController:didTransitionToState:)]) {
        [self.statefulDelegate statefulTableViewController:self didTransitionToState:statefulState];
    }
}

#pragma mark - View Lifecycle

- (void) loadView {
    [super loadView];
    
    self.loadingView = [[UIView alloc] initWithFrame:self.collectionView.bounds];
    self.loadingView.backgroundColor = [UIColor greenColor];
    
    self.emptyView = [[UIView alloc] initWithFrame:self.collectionView.bounds];
    self.emptyView.backgroundColor = [UIColor yellowColor];
    
    self.errorView = [[UIView alloc] initWithFrame:self.collectionView.bounds];
    self.errorView.backgroundColor = [UIColor redColor];
    
    self.hasAddedPullToRefreshControl = NO;
}

- (void) viewDidLoad {
    [super viewDidLoad];
}
- (void) viewDidUnload {
    [super viewDidUnload];
    
    self.loadingView = nil;
    self.emptyView = nil;
    self.errorView = nil;
}

- (void) viewWillAppear:(BOOL)animated {
    __block DRStateCollectViewController *safeSelf = self;
    
    BOOL shouldPullToRefresh = YES;
    if([self.statefulDelegate respondsToSelector:@selector(statefulTableViewControllerShouldPullToRefresh:)]) {
        shouldPullToRefresh = [self.statefulDelegate statefulTableViewControllerShouldPullToRefresh:self];
    }
    
    if(!self.hasAddedPullToRefreshControl && shouldPullToRefresh) {
        if([self respondsToSelector:@selector(refreshControl)]) {
            self.refreshControl = [[UIRefreshControl alloc] init];
            [self.refreshControl addTarget:self action:@selector(_loadFromPullToRefresh) forControlEvents:UIControlEventValueChanged];
        } else {
            [self.collectionView addPullToRefreshWithActionHandler:^{
                [safeSelf _loadFromPullToRefresh];
            }];
        }
        
        self.hasAddedPullToRefreshControl = YES;
    }
    
    BOOL shouldInfinitelyScroll = YES;
    if([self.statefulDelegate respondsToSelector:@selector(statefulTableViewControllerShouldInfinitelyScroll:)]) {
        shouldInfinitelyScroll = [self.statefulDelegate statefulTableViewControllerShouldInfinitelyScroll:self];
    }
    
    [self updateInfiniteScrollingHandlerAndFooterView:shouldInfinitelyScroll];
    
    [self _loadFirstPage];
    
    [super viewWillAppear:animated];
}

- (void) updateInfiniteScrollingHandlerAndFooterView:(BOOL)shouldInfinitelyScroll {
    if (shouldInfinitelyScroll) {
        if(self.collectionView.infiniteScrollingView.infiniteScrollingHandler == nil) {
            __block DRStateCollectViewController *safeSelf = self;
            
            [self.collectionView addInfiniteScrollingWithActionHandler:^{
                [safeSelf _loadNextPage];
            }];
        }
    } else {
        self.collectionView.infiniteScrollingView.infiniteScrollingHandler = nil;
//        self.collectionView.tableFooterView = nil;
    }
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - DRStateCollectViewControllerDelegate

- (void) statefulTableViewControllerWillBeginInitialLoading:(DRStateCollectViewController *)vc completionBlock:(void (^)())success failure:(void (^)(NSError *error))failure {
    NSAssert(NO, @"statefulTableViewControllerWillBeginInitialLoading:completionBlock:failure: is meant to be implementd by it's subclasses!");
}

- (void) statefulTableViewControllerWillBeginLoadingFromPullToRefresh:(DRStateCollectViewController *)vc completionBlock:(void (^)(NSArray *indexPathsToInsert))success failure:(void (^)(NSError *error))failure {
    NSAssert(NO, @"statefulTableViewControllerWillBeginLoadingFromPullToRefresh:completionBlock:failure: is meant to be implementd by it's subclasses!");
}

- (void) statefulTableViewControllerWillBeginLoadingNextPage:(DRStateCollectViewController *)vc completionBlock:(void (^)())success failure:(void (^)(NSError *))failure {
    NSAssert(NO, @"statefulTableViewControllerWillBeginLoadingNextPage:completionBlock:failure: is meant to be implementd by it's subclasses!");
}
- (BOOL) statefulTableViewControllerShouldBeginLoadingNextPage:(DRStateCollectViewController *)vc {
    NSAssert(NO, @"statefulTableViewControllerShouldBeginLoadingNextPage is meant to be implementd by it's subclasses!");    
    
    return NO;
}


@end
