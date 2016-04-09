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

@import Photos;

@interface IGCropView : UIScrollView
@property (nonatomic, strong) ALAsset * alAsset;
@property (nonatomic, strong) PHAsset * phAsset;

- (void)cropAsset:(void(^)(id))completeBlock;

- (void)getCropRegion:(void(^)(CGRect))completeBlock;

//for lately crop
+(void)cropPhAsset:(PHAsset *)asset withRegion:(CGRect)rect onComplete:(void(^)(id))completion;

@end
