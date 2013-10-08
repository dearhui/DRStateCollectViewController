//
//  DRStateCollectViewController.h
//  DRStateCollectViewControllerDemo
//
//  Created by Ming Hui Ho on 13/10/3.
//  Copyright (c) 2013年 Ming Hui Ho. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVPullToRefresh.h"

typedef enum {
	DRStateCollectViewControllerStateIdle = 0,
	DRStateCollectViewControllerStateInitialLoading = 1,
	DRStateCollectViewControllerStateLoadingFromPullToRefresh = 2,
	DRStateCollectViewControllerStateLoadingNextPage = 3,
	DRStateCollectViewControllerStateEmpty = 4,
	DRStateCollectViewControllerError = 5,
} DRStateCollectViewControllerState;

typedef enum {
    DRStateCollectStateLoadInitial = 0,
    DRStateCollectStateLoadPull,
    DRStateCollectStateLoadNext
} DRStateCollectStateLoad;

@class DRStateCollectViewController;

@protocol DRStateCollectViewControllerDelegate <NSObject>

@required
- (void) stateCollectViewController:(DRStateCollectViewController *)vc
                    completionBlock:(void (^)())success
                            failure:(void (^)(NSError *error))failure
                          loadState:(DRStateCollectStateLoad)state;

@required
- (BOOL) stateCollectViewControllerShouldBeginLoadingNextPage:(DRStateCollectViewController *)vc;

@optional
- (void) stateCollectViewController:(DRStateCollectViewController *)vc willTransitionToState:(DRStateCollectViewControllerState)state;

@optional
- (void) stateCollectViewController:(DRStateCollectViewController *)vc didTransitionToState:(DRStateCollectViewControllerState)state;

@optional
- (BOOL) stateCollectViewControllerShouldPullToRefresh:(DRStateCollectViewController *)vc;

@optional
- (BOOL) stateCollectViewControllerShouldInfinitelyScroll:(DRStateCollectViewController *)vc;

@end

@interface DRStateCollectViewController : UIViewController <DRStateCollectViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic) DRStateCollectViewControllerState statefulState;

@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) IBOutlet UIView *emptyView;
@property (strong, nonatomic) IBOutlet UIView *loadingView;
@property (strong, nonatomic) IBOutlet UIView *errorView;

@property (nonatomic, unsafe_unretained) id <DRStateCollectViewControllerDelegate> statefulDelegate;

- (void) loadNewer;

- (void) updateInfiniteScrollingHandlerAndFooterView:(BOOL)shouldInfinitelyScroll;

@end
