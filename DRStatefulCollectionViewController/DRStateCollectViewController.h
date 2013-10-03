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

@class DRStateCollectViewController;

@protocol DRStateCollectViewControllerDelegate <NSObject>

@required
- (void) statefulTableViewControllerWillBeginInitialLoading:(DRStateCollectViewController *)vc completionBlock:(void (^)())success failure:(void (^)(NSError *error))failure;

@required
- (void) statefulTableViewControllerWillBeginLoadingFromPullToRefresh:(DRStateCollectViewController *)vc completionBlock:(void (^)(NSArray *indexPathsToInsert))success failure:(void (^)(NSError *error))failure;

@required
- (void) statefulTableViewControllerWillBeginLoadingNextPage:(DRStateCollectViewController *)vc completionBlock:(void (^)())success failure:(void (^)(NSError *error))failure;

@required
- (BOOL) statefulTableViewControllerShouldBeginLoadingNextPage:(DRStateCollectViewController *)vc;

@optional
- (void) statefulTableViewController:(DRStateCollectViewController *)vc willTransitionToState:(DRStateCollectViewControllerState)state;

@optional
- (void) statefulTableViewController:(DRStateCollectViewController *)vc didTransitionToState:(DRStateCollectViewControllerState)state;

@optional
- (BOOL) statefulTableViewControllerShouldPullToRefresh:(DRStateCollectViewController *)vc;

@optional
- (BOOL) statefulTableViewControllerShouldInfinitelyScroll:(DRStateCollectViewController *)vc;

@end

@interface DRStateCollectViewController : UICollectionViewController <DRStateCollectViewControllerDelegate>

@property (nonatomic) DRStateCollectViewControllerState statefulState;

@property (strong, nonatomic) UIView *emptyView;
@property (strong, nonatomic) UIView *loadingView;
@property (strong, nonatomic) UIView *errorView;

@property (nonatomic, unsafe_unretained) id <DRStateCollectViewControllerDelegate> statefulDelegate;

- (void) loadNewer;

- (void) updateInfiniteScrollingHandlerAndFooterView:(BOOL)shouldInfinitelyScroll;

@end