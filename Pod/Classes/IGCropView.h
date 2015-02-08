//
//  IGCropView.h
//  InstagramAssetsPicker
//
//  Created by JG on 2/3/15.
//  Copyright (c) 2015 JG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

@interface IGCropView : UIScrollView

- (void)displayAsset:(ALAsset *)asset;

- (id)cropAsset;

@end
