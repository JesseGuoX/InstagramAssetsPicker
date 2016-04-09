//
//  IGViewController.m
//  InstagramAssetsPicker
//
//  Created by JG on 02/03/2015.
//  Copyright (c) 2014 JG. All rights reserved.
//

#import "IGViewController.h"
#import "IGAssetsPicker.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface IGViewController ()<IGAssetsPickerDelegate>
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) MPMoviePlayerController *videoPlayer;

@end

@implementation IGViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.videoPlayer = [[MPMoviePlayerController alloc] init];
    self.videoPlayer.controlStyle = MPMovieControlStyleNone;
    self.videoPlayer.movieSourceType = MPMovieSourceTypeFile;
    self.videoPlayer.scalingMode = MPMovieScalingModeNone;
    [self.view addSubview:self.videoPlayer.view];
    self.videoPlayer.view.hidden = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showPickerAction:(id)sender {
    
    [self getPermissionForPhotos:^(BOOL hasAccess) {
        if (!hasAccess) {
            NSLog(@"Cannot access photos, give this app permission for your photos.");
            return;
        }
        
        IGAssetsPickerViewController *picker = [[IGAssetsPickerViewController alloc] init];
        picker.delegate = self;
        picker.cropAfterSelect = true;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:picker animated:YES completion:NULL];
        });
    }];
}

#pragma mark - IGAssetsPickerDelegate

- (void)IGAssetsPickerFinishCroppingToAsset:(id)asset
{    
    if ([asset isKindOfClass:[UIImage class]]) {
        [self.videoPlayer stop];
        self.videoPlayer.view.hidden = YES;
        self.imageView.hidden = NO;
        self.imageView.image = (UIImage *)asset;
    } else if ([asset isKindOfClass:[NSURL class]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.videoPlayer.contentURL = ((NSURL *) asset);
            self.videoPlayer.view.hidden = NO;
            self.imageView.hidden = YES;
            self.videoPlayer.view.frame = self.imageView.frame;
            [self.videoPlayer play];
        });
    }
}

- (void)IGAssetsPickerGetCropRegion:(CGRect)rect withPhAsset:(PHAsset *)asset
{
    NSLog(@"IGAssetsPickerGetCropRegion");
}

- (void)getPermissionForPhotos:(void(^)(BOOL))completeBlock
{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    
    switch (status)
    {
        case PHAuthorizationStatusAuthorized:
            completeBlock(true);
            break;
        case PHAuthorizationStatusNotDetermined:
        {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus authorizationStatus)
             {
                 if (authorizationStatus == PHAuthorizationStatusAuthorized)
                 {
                     completeBlock(true);
                 }
                 else
                 {
                     completeBlock(false);
                 }
             }];
            break;
        }
        default:
            completeBlock(false);
            break;
    }
}
@end
