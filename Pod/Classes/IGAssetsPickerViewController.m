//
//  IGAssetsPickerViewController.m
//  InstagramAssetsPicker
//
//  Created by JG on 2/3/15.
//  Copyright (c) 2015 JG. All rights reserved.
//

#import "IGAssetsPickerViewController.h"
#import "IGCropView.h"
#import "IGAssetsCollectionViewCell.h"
#import "IGAssetsPicker.h"

@interface IGAssetsPickerViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate>
{
    CGFloat beginOriginY;
}
@property (strong, nonatomic) UIView *topView;
@property (strong, nonatomic) UIImageView *maskView;
@property (strong, nonatomic) IGCropView *cropView;

@property (strong, nonatomic) NSMutableArray *assets;
@property (strong, nonatomic) PHPhotoLibrary *assetsLibrary;

@property (strong, nonatomic) UICollectionView *collectionView;
@end

@implementation IGAssetsPickerViewController
@synthesize cropAfterSelect;
@synthesize fetchOptions;

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor blackColor];

    [self.view addSubview:self.topView];
    [self.view insertSubview:self.collectionView belowSubview:self.topView];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self loadPhotos];

}



- (NSMutableArray *)assets {
    if (_assets == nil) {
        _assets = [[NSMutableArray alloc] init];
    }
    return _assets;
}

- (PHPhotoLibrary *)assetsLibrary {
    if (_assetsLibrary == nil) {
        _assetsLibrary = [[PHPhotoLibrary alloc] init];
    }
    return _assetsLibrary;
}

- (void)loadPhotos {
    
    PHFetchResult *allMedia = [PHAsset fetchAssetsWithOptions: self.fetchOptions];
    long mediaCount = [allMedia count];
    [allMedia enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
        if (asset) {
            [self.assets insertObject:asset atIndex:0];
        }
        if (mediaCount == idx + 1) {
            if (self.assets.count) {
                
                PHAsset *asset = [self.assets objectAtIndex:0];
                [self.cropView setPhAsset:asset];
                [self.collectionView reloadData];
            }
        }
    }];

}


- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIView *)topView {
    if (_topView == nil) {
        CGFloat handleHeight = 44.0f;
        CGRect rect = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetWidth(self.view.bounds)+handleHeight*2);
        self.topView = [[UIView alloc] initWithFrame:rect];
        self.topView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        self.topView.backgroundColor = [UIColor clearColor];
        self.topView.clipsToBounds = YES;

        rect = CGRectMake(0, 0, CGRectGetWidth(self.topView.bounds), handleHeight);
        UIView *navView = [[UIView alloc] initWithFrame:rect];//26 29 33
        navView.backgroundColor = [[UIColor colorWithRed:26.0/255 green:29.0/255 blue:33.0/255 alpha:1] colorWithAlphaComponent:.8f];
        [self.topView addSubview:navView];

        rect = CGRectMake(0, 0, 60, CGRectGetHeight(navView.bounds));
        UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        backBtn.frame = rect;
        [backBtn setImage:[UIImage imageNamed:@"InstagramAssetsPicker.bundle/back"] forState:UIControlStateNormal];
        [backBtn addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
        [navView addSubview:backBtn];

        rect = CGRectMake((CGRectGetWidth(navView.bounds)-100)/2, 0, 100, CGRectGetHeight(navView.bounds));
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:rect];
        titleLabel.text = @"SELECT";
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
        [navView addSubview:titleLabel];

        rect = CGRectMake(CGRectGetWidth(navView.bounds)-80, 0, 80, CGRectGetHeight(navView.bounds));
        UIButton *cropBtn = [[UIButton alloc] initWithFrame:rect];
        [cropBtn setTitle:@"OK" forState:UIControlStateNormal];
        [cropBtn.titleLabel setFont:[UIFont systemFontOfSize:14.0f]];
        [cropBtn setTitleColor:[UIColor cyanColor] forState:UIControlStateNormal];
        [cropBtn addTarget:self action:@selector(cropAction) forControlEvents:UIControlEventTouchUpInside];
        [navView addSubview:cropBtn];

        rect = CGRectMake(0, CGRectGetHeight(self.topView.bounds)-handleHeight, CGRectGetWidth(self.topView.bounds), handleHeight);
        UIView *dragView = [[UIView alloc] initWithFrame:rect];
        dragView.backgroundColor = navView.backgroundColor;
        dragView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [self.topView addSubview:dragView];

        UIImage *img = [UIImage imageNamed:@"InstagramAssetsPicker.bundle/cameraroll-picker-grip"];
        rect = CGRectMake((CGRectGetWidth(dragView.bounds)-img.size.width)/2, (CGRectGetHeight(dragView.bounds)-img.size.height)/2, img.size.width, img.size.height);
        UIImageView *gripView = [[UIImageView alloc] initWithFrame:rect];
        gripView.image = img;
        [dragView addSubview:gripView];

        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
        [dragView addGestureRecognizer:panGesture];

        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
        [dragView addGestureRecognizer:tapGesture];

        [tapGesture requireGestureRecognizerToFail:panGesture];

        rect = CGRectMake(0, handleHeight, CGRectGetWidth(self.topView.bounds), CGRectGetHeight(self.topView.bounds)-handleHeight*2);
        self.cropView = [[IGCropView alloc] initWithFrame:rect];
        [self.topView addSubview:self.cropView];
        [self.topView sendSubviewToBack:self.cropView];

        self.maskView = [[UIImageView alloc] initWithFrame:rect];
        self.maskView.image = [UIImage imageNamed:@"InstagramAssetsPicker.bundle/straighten-grid"];

        UIPanGestureRecognizer *cropViewPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(cropViewPanGestureAction:)];
        [self.cropView addGestureRecognizer:cropViewPanGesture];

    }
    return _topView;
}

- (UICollectionView *)collectionView {
    if (_collectionView == nil) {
        CGFloat colum = 4.0, spacing = 2.0;
        CGFloat value = floorf((CGRectGetWidth(self.view.bounds) - (colum - 1) * spacing) / colum);

        UICollectionViewFlowLayout *layout  = [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize                     = CGSizeMake(value, value);
        layout.sectionInset                 = UIEdgeInsetsMake(0, 0, 0, 0);
        layout.minimumInteritemSpacing      = spacing;
        layout.minimumLineSpacing           = spacing;

        CGRect rect = CGRectMake(0, CGRectGetMaxY(self.topView.frame), CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)-CGRectGetHeight(self.topView.bounds));
        _collectionView = [[UICollectionView alloc] initWithFrame:rect collectionViewLayout:layout];
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.backgroundColor = [UIColor clearColor];

        [_collectionView registerClass:[IGAssetsCollectionViewCell class] forCellWithReuseIdentifier:@"IGAssetsCollectionViewCell"];

        //        rect = CGRectMake(0, 0, 60, layout.sectionInset.top);
        //        UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        //        backBtn.frame = rect;
        //        [backBtn setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
        //        [backBtn addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
        //        [_collectionView addSubview:backBtn];
        //
        //        rect = CGRectMake((CGRectGetWidth(_collectionView.bounds)-140)/2, 0, 140, layout.sectionInset.top);
        //        UILabel *titleLabel = [[UILabel alloc] initWithFrame:rect];
        //        titleLabel.text = @"CAMERA ROLL";
        //        titleLabel.textAlignment = NSTextAlignmentCenter;
        //        titleLabel.backgroundColor = [UIColor clearColor];
        //        titleLabel.textColor = [UIColor whiteColor];
        //        titleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
        //        [_collectionView addSubview:titleLabel];
    }
    return _collectionView;
}

- (void)backAction {
    [self dismissViewControllerAnimated:YES completion:NULL];
}


- (void)cropAction {
    if (cropAfterSelect)
    {
        if(self.delegate && [self.delegate respondsToSelector:@selector(IGAssetsPickerFinishCroppingToAsset:)])
        {
            [self.cropView cropAsset:^(id asset) {
                [self.delegate IGAssetsPickerFinishCroppingToAsset:asset];
            }];
        }
    }
    else
    {
        if(self.delegate && [self.delegate respondsToSelector:@selector(IGAssetsPickerGetCropRegion: withPhAsset:)])
        {
            [self.cropView getCropRegion:^(CGRect rect) {
                [self.delegate IGAssetsPickerGetCropRegion:rect withPhAsset:self.cropView.phAsset];
            }];
        }
    }
    
    [self backAction];
}

- (void)panGestureAction:(UIPanGestureRecognizer *)panGesture {
    switch (panGesture.state)
    {
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            CGRect topFrame = self.topView.frame;
            CGFloat endOriginY = self.topView.frame.origin.y;
            if (endOriginY > beginOriginY) {
                topFrame.origin.y = (endOriginY - beginOriginY) >= 20 ? 0 : -(CGRectGetHeight(self.topView.bounds)-20-44);
            } else if (endOriginY < beginOriginY) {
                topFrame.origin.y = (beginOriginY - endOriginY) >= 20 ? -(CGRectGetHeight(self.topView.bounds)-20-44) : 0;
            }

            CGRect collectionFrame = self.collectionView.frame;
            collectionFrame.origin.y = CGRectGetMaxY(topFrame);
            collectionFrame.size.height = CGRectGetHeight(self.view.bounds) - CGRectGetMaxY(topFrame);
            [UIView animateWithDuration:.3f animations:^{
                self.topView.frame = topFrame;
                self.collectionView.frame = collectionFrame;
            }];
            break;
        }
        case UIGestureRecognizerStateBegan:
        {
            beginOriginY = self.topView.frame.origin.y;
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            CGPoint translation = [panGesture translationInView:self.view];
            CGRect topFrame = self.topView.frame;
            topFrame.origin.y = translation.y + beginOriginY;

            CGRect collectionFrame = self.collectionView.frame;
            collectionFrame.origin.y = CGRectGetMaxY(topFrame);
            collectionFrame.size.height = CGRectGetHeight(self.view.bounds) - CGRectGetMaxY(topFrame);

            if (topFrame.origin.y <= 0 && (topFrame.origin.y >= -(CGRectGetHeight(self.topView.bounds)-20-44))) {
                self.topView.frame = topFrame;
                self.collectionView.frame = collectionFrame;
            }

            break;
        }
        default:
            break;
    }
}

- (void)cropViewPanGestureAction:(UIPanGestureRecognizer *)panGesture {
    switch (panGesture.state)
    {
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            [self.maskView removeFromSuperview];
            break;
        }
        case UIGestureRecognizerStateBegan:
        {
            [self.topView insertSubview:self.maskView aboveSubview:self.cropView];
            break;
        }
        default:
            break;
    }
}

- (void)tapGestureAction:(UITapGestureRecognizer *)tapGesture {
    CGRect topFrame = self.topView.frame;
    topFrame.origin.y = topFrame.origin.y == 0 ? -(CGRectGetHeight(self.topView.bounds)-20-44) : 0;

    CGRect collectionFrame = self.collectionView.frame;
    collectionFrame.origin.y = CGRectGetMaxY(topFrame);
    collectionFrame.size.height = CGRectGetHeight(self.view.bounds) - CGRectGetMaxY(topFrame);
    [UIView animateWithDuration:.3f animations:^{
        self.topView.frame = topFrame;
        self.collectionView.frame = collectionFrame;

    }];
}

#pragma mark - Collection View Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.assets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"IGAssetsCollectionViewCell";

    IGAssetsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    [cell applyAsset:[self.assets objectAtIndex:indexPath.row]];
    return cell;
}

#pragma mark - Collection View Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    PHAsset *asset = [self.assets objectAtIndex:indexPath.row];
    
    [self.cropView setPhAsset:asset];
    
    UICollectionViewCell * cell = [collectionView cellForItemAtIndexPath:indexPath];
    
    [self.collectionView setContentOffset:CGPointMake(0, cell.frame.origin.y - cell.frame.size.height / 2) animated:YES];
    if (self.topView.frame.origin.y != 0) {
        [self tapGestureAction:nil];
    }
    
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{

}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    NSLog(@"velocity:%f", velocity.y);
    if (velocity.y >= 2.0 && self.topView.frame.origin.y == 0) {
        [self tapGestureAction:nil];
    }
}


@end
