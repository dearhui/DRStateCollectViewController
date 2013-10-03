//
//  ThumbnailViewController.m
//  DRStatefulCollectionViewControllerDemo
//
//  Created by Ming Hui Ho on 13/10/3.
//  Copyright (c) 2013年 Ming Hui Ho. All rights reserved.
//

#import "ThumbnailViewController.h"
#import "thumbnailViewCell.h"
#import <AFNetworking/UIImageView+AFNetworking.h>

@interface ThumbnailViewController ()
    @property NSMutableArray *items;
@end

@implementation ThumbnailViewController

#pragma mark - View Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.items = [NSMutableArray array];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    thumbnailViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    NSURL *urlPrefix = [NSURL URLWithString:@"https://raw.github.com/ShadoFlameX/PhotoCollectionView/master/Photos/"];
    NSString *photoFilename = [NSString stringWithFormat:@"thumbnail%d.jpg", indexPath.row % 25];
    NSURL *photoURL = [urlPrefix URLByAppendingPathComponent:photoFilename];
    
    [cell.imageView setImageWithURL:photoURL];
    
    return cell;
}

#pragma mark - DRStateCollectViewControllerDelegate
- (void) statefulTableViewControllerWillBeginInitialLoading:(DRStateCollectViewController *)vc completionBlock:(void (^)())success failure:(void (^)(NSError *error))failure {
    dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
        sleep(2);   // 5 sec
        
        NSMutableArray *arr = [NSMutableArray array];
        for (int i = 0 ; i < 25; i++) {
            [arr addObject:[NSString stringWithFormat:@"%d", i]];
        }
        self.items = arr;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            success();
        });
    });
}

- (void) statefulTableViewControllerWillBeginLoadingFromPullToRefresh:(DRStateCollectViewController *)vc completionBlock:(void (^)(NSArray *indexPathsToInsert))success failure:(void (^)(NSError *error))failure {
    dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
        sleep(2);   // 5 sec
        
        NSMutableArray *arr = [NSMutableArray array];
        for (int i = 0 ; i < 25; i++) {
            [arr addObject:[NSString stringWithFormat:@"%d", i]];
        }
        self.items = arr;
        
        NSMutableArray *a = [NSMutableArray array];
        
        for(NSInteger i = 0; i < self.items.count; i++) {
            [a addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            success([NSArray arrayWithArray:a]);
        });
    });
}

- (void) statefulTableViewControllerWillBeginLoadingNextPage:(DRStateCollectViewController *)vc completionBlock:(void (^)())success failure:(void (^)(NSError *error))failure {
    dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
        sleep(2);   // 5 sec
        
        NSMutableArray *arr = [NSMutableArray array];
        for (int i = 0 ; i < 25; i++) {
            [arr addObject:[NSString stringWithFormat:@"%d", i]];
        }
        [self.items addObjectsFromArray:arr];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            success();
        });
    });
}

- (BOOL) statefulTableViewControllerShouldBeginLoadingNextPage:(DRStateCollectViewController *)vc {
    return self.items.count <= 100;
}

@end
