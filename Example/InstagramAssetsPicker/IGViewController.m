//
//  IGViewController.m
//  InstagramAssetsPicker
//
//  Created by JG on 02/03/2015.
//  Copyright (c) 2014 JG. All rights reserved.
//

#import "IGViewController.h"
#import "IGAssetsPickerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface IGViewController ()
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
    IGAssetsPickerViewController *picker = [[IGAssetsPickerViewController alloc] init];

    picker.cropAsset = ^(id asset)
    {
        if([asset isKindOfClass:[UIImage class]])//photo
        {
            [self.videoPlayer stop];
            self.videoPlayer.view.hidden = YES;
            self.imageView.hidden = NO;
            self.imageView.image = (UIImage *)asset;
        }
        else if([asset isKindOfClass:[AVAsset class]])//video
        {
            self.videoPlayer.contentURL = ((AVURLAsset *)asset).URL;
            self.videoPlayer.view.hidden = NO;
            self.imageView.hidden = YES;
            self.videoPlayer.view.frame = self.imageView.frame;
            
            [self.videoPlayer play];
        }
    
    };
    [self presentViewController:picker animated:YES completion:NULL];
}

@end
