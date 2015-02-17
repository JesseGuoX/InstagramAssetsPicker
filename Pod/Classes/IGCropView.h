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
@property (nonatomic, strong) ALAsset * alAsset;

- (id)cropAsset;

- (CGRect)getCropRegion;

//for lately crop
+(id)cropAlAsset:(ALAsset *)asset withRegion:(CGRect)rect;

@end
