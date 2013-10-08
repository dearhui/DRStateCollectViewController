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

@interface DRStateCollectViewController ()

@property (nonatomic, assign) BOOL hasAddedPullToRefreshControl;

// Loading
- (void) _loadFirstPage;
- (void) _loadNextPage;
- (void) _loadFromPullToRefresh;

- (NSInteger) _totalNumberOfRows;

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
    
    [self.statefulDelegate stateCollectViewController:self completionBlock:^{
        [self.collectionView reloadData]; // We have to call reloadData before we call _totalNumberOfRows otherwise the new count (after loading) won't be accurately reflected.
        
        if([self _totalNumberOfRows] > 0) {
            self.statefulState = DRStateCollectViewControllerStateIdle;
        } else {
            self.statefulState = DRStateCollectViewControllerStateEmpty;
        }
    } failure:^(NSError *error) {
        self.statefulState = DRStateCollectViewControllerError;
    } loadState:DRStateCollectStateLoadInitial];
}

- (void) _loadNextPage {
    if(self.statefulState == DRStateCollectViewControllerStateLoadingNextPage) return;
    
    if([self.statefulDelegate stateCollectViewControllerShouldBeginLoadingNextPage:self]) {
//        self.collectionView.showsInfiniteScrolling = YES;
        
        self.statefulState = DRStateCollectViewControllerStateLoadingNextPage;
        
        [self.statefulDelegate stateCollectViewController:self completionBlock:^{
            [self.collectionView reloadData];
            
            if(![self.statefulDelegate stateCollectViewControllerShouldBeginLoadingNextPage:self]) {
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
        } loadState:DRStateCollectStateLoadNext];
    } else {
        self.collectionView.showsInfiniteScrolling = NO;
    }
}

- (void) _loadFromPullToRefresh {
    if(self.statefulState == DRStateCollectViewControllerStateLoadingFromPullToRefresh) return;
    
    self.statefulState = DRStateCollectViewControllerStateLoadingFromPullToRefresh;
    
    [self.statefulDelegate stateCollectViewController:self completionBlock:^(void) {
        self.statefulState = DRStateCollectViewControllerStateIdle;
        [self _pullToRefreshFinishedLoading];
        
        if([self.statefulDelegate stateCollectViewControllerShouldBeginLoadingNextPage:self]) {
            self.collectionView.showsInfiniteScrolling = YES;
        };
    } failure:^(NSError *error) {
        //TODO: What should we do here?
        
        self.statefulState = DRStateCollectViewControllerStateIdle;
        [self _pullToRefreshFinishedLoading];
    } loadState:DRStateCollectStateLoadPull];
}

#pragma mark - Table View Cells & NSIndexPaths
- (NSInteger) _totalNumberOfRows {
    NSInteger numberOfRows = 0;
    
    NSInteger numberOfSections = [self numberOfSectionsInCollectionView:self.collectionView];
    for(NSInteger i = 0; i < numberOfSections; i++) {
        numberOfRows += [self collectionView:self.collectionView numberOfItemsInSection:i];
    }
    
    return numberOfRows;
}

- (void) _pullToRefreshFinishedLoading {
    [self.collectionView.pullToRefreshView stopAnimating];
    if([self respondsToSelector:@selector(refreshControl)]) {
        [self.refreshControl endRefreshing];
    }
}

#pragma mark - Setter Overrides

- (void) setStatefulState:(DRStateCollectViewControllerState)statefulState {
    if([self.statefulDelegate respondsToSelector:@selector(stateCollectViewController:willTransitionToState:)]) {
        [self.statefulDelegate stateCollectViewController:self willTransitionToState:statefulState];
    }
    
	_statefulState = statefulState;
    
    switch (_statefulState) {
        case DRStateCollectViewControllerStateIdle:
            [self.collectionView.infiniteScrollingView stopAnimating];
            [self.loadingView removeFromSuperview];
            [self.emptyView removeFromSuperview];
            [self.errorView removeFromSuperview];
            self.collectionView.scrollEnabled = YES;
            [self.collectionView reloadData];
            
            break;
            
        case DRStateCollectViewControllerStateInitialLoading:
            [self.collectionView addSubview:self.loadingView];
            self.collectionView.scrollEnabled = NO;
            [self.collectionView reloadData];
            
            break;
            
        case DRStateCollectViewControllerStateEmpty:
            [self.collectionView.infiniteScrollingView stopAnimating];
            [self.collectionView addSubview:self.emptyView];
            self.collectionView.scrollEnabled = NO;
            [self.collectionView reloadData];
            
        case DRStateCollectViewControllerStateLoadingNextPage:
            // TODO
            break;
            
        case DRStateCollectViewControllerStateLoadingFromPullToRefresh:
            // TODO
            break;
            
        case DRStateCollectViewControllerError:
            [self.collectionView.infiniteScrollingView stopAnimating];
            [self.collectionView addSubview:self.errorView];
            self.collectionView.scrollEnabled = NO;
            [self.collectionView reloadData];
            break;
            
        default:
            break;
    }
    
    if([self.statefulDelegate respondsToSelector:@selector(stateCollectViewController:didTransitionToState:)]) {
        [self.statefulDelegate stateCollectViewController:self didTransitionToState:statefulState];
    }
}

#pragma mark - View Lifecycle

- (void) viewDidLoad {
    [super viewDidLoad];
    
    if (!self.loadingView) {
        self.loadingView = [[UIView alloc] initWithFrame:self.collectionView.bounds];
        self.loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.loadingView.backgroundColor = [UIColor greenColor];
    }
    
    self.emptyView = [[UIView alloc] initWithFrame:self.collectionView.bounds];
    self.emptyView.backgroundColor = [UIColor yellowColor];
    
    self.errorView = [[UIView alloc] initWithFrame:self.collectionView.bounds];
    self.errorView.backgroundColor = [UIColor redColor];
    
    self.hasAddedPullToRefreshControl = NO;
    
    __block DRStateCollectViewController *safeSelf = self;
    
    BOOL shouldPullToRefresh = YES;
    if([self.statefulDelegate respondsToSelector:@selector(stateCollectViewControllerShouldPullToRefresh:)]) {
        shouldPullToRefresh = [self.statefulDelegate stateCollectViewControllerShouldPullToRefresh:self];
    }
    
    if(!self.hasAddedPullToRefreshControl && shouldPullToRefresh) {
        if([self respondsToSelector:@selector(refreshControl)]) {
            self.refreshControl = [[UIRefreshControl alloc] init];
            [self.refreshControl addTarget:self action:@selector(_loadFromPullToRefresh) forControlEvents:UIControlEventValueChanged];
            [self.collectionView addSubview:self.refreshControl];
            self.collectionView.alwaysBounceVertical = YES;
        } else {
            [self.collectionView addPullToRefreshWithActionHandler:^{
                [safeSelf _loadFromPullToRefresh];
            }];
        }
        
        self.hasAddedPullToRefreshControl = YES;
    }
    
    BOOL shouldInfinitelyScroll = YES;
    if([self.statefulDelegate respondsToSelector:@selector(stateCollectViewControllerShouldInfinitelyScroll:)]) {
        shouldInfinitelyScroll = [self.statefulDelegate stateCollectViewControllerShouldInfinitelyScroll:self];
    }
    
    [self updateInfiniteScrollingHandlerAndFooterView:shouldInfinitelyScroll];
    
    [self _loadFirstPage];
}

- (void) viewDidUnload {
    [super viewDidUnload];
    
    self.loadingView = nil;
    self.emptyView = nil;
    self.errorView = nil;
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
    }
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - DRStateCollectViewControllerDelegate

- (void) stateCollectViewController:(DRStateCollectViewController *)vc
                    completionBlock:(void (^)())success
                            failure:(void (^)(NSError *error))failure
                          loadState:(DRStateCollectStateLoad)state {
    NSAssert(NO, @"stateCollectViewController:completionBlock:failure:loadState: is meant to be implementd by it's subclasses!");
}

- (BOOL) stateCollectViewControllerShouldBeginLoadingNextPage:(DRStateCollectViewController *)vc {
    NSAssert(NO, @"stateCollectViewControllerShouldBeginLoadingNextPage is meant to be implementd by it's subclasses!");    
    
    return NO;
}


@end
