//
//  IGCropView.m
//  InstagramAssetsPicker
//
//  Created by JG on 2/3/15.
//  Copyright (c) 2015 JG. All rights reserved.
//

#import "IGCropView.h"
#import "GPUImage.h"

#define rad(angle) ((angle) / 180.0 * M_PI)


@interface IGCropView()<UIScrollViewDelegate>
{
    CGSize _imageSize;
    int _playState;//if is video(playing or pause) or image
    NSString * _type;
    
    AVAssetExportSession *exporter;

    GPUImageMovie *movieFile;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageMovieWriter *movieWriter;
}

@property (strong, nonatomic) UIImageView *imageView;
@property (nonatomic, strong) MPMoviePlayerController *videoPlayer;
@property (nonatomic) CGFloat videoPlayerScale;
@property (nonatomic, strong) ALAsset *asset;
@property (strong, nonatomic) UIImageView * videoStartMaskView;

@end

@implementation IGCropView


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = NO;
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.alwaysBounceHorizontal = YES;
        self.alwaysBounceVertical = YES;
        self.bouncesZoom = YES;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.delegate = self;
        

    }
    return self;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // center the zoom view as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = self.imageView.frame;
    
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    else
        frameToCenter.origin.x = 0;
    
    // center vertically
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else
        frameToCenter.origin.y = 0;
    
    self.imageView.frame = frameToCenter;
    
    self.videoStartMaskView.hidden = YES;
    


}


-(UIImageView *)videoStartMaskView
{
    if(!_videoStartMaskView)
    {
        self.videoStartMaskView =[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"InstagramAssetsPicker.bundle/Start"] ];
        //FIXME: should use constraint
        self.videoStartMaskView.frame = CGRectMake(self.superview.frame.size.width / 2 + self.superview.frame.origin.x - 25, self.superview.frame.size.height / 2 + self.superview.frame.origin.y - 25, 50, 50);
        [self.superview addSubview:self.videoStartMaskView];
        self.videoStartMaskView.hidden = YES;
    }
    return _videoStartMaskView;
}


- (id)cropAsset
{
    if(self.asset)
    {
        if([_type isEqualToString:ALAssetTypePhoto])
        {
            UIImage * image = [self capture];
            return image;
        }
        else if([_type isEqualToString:ALAssetTypeVideo])
        {
            AVAsset * asset = [self CropVideo];
            return asset;

        }
        else
            return nil;
    }
    else
        return nil;

}



- (CGRect) rangeRestrictForRect:(CGRect )unitRect
{
    //incase <0 or >1
    if(unitRect.origin.x < 0) unitRect.origin.x = 0;
    if(unitRect.origin.x > 1) unitRect.origin.x = 1;
    if(unitRect.origin.y < 0) unitRect.origin.y = 0;
    if(unitRect.origin.y > 1) unitRect.origin.y = 1;
    if(unitRect.size.height < 0) unitRect.size.height = 0;
    if(unitRect.size.height > 1) unitRect.size.height = 1;
    if(unitRect.size.width < 0) unitRect.size.width = 0;
    if(unitRect.size.width > 1) unitRect.size.width = 1;
    
    return unitRect;
}


#pragma mark -Video Process
- (AVAsset *)CropVideo
{
    
    UIInterfaceOrientation orientation = [IGCropView orientationForTrack:[AVAsset assetWithURL:self.asset.defaultRepresentation.url]];
    AVAsset *asset = [AVAsset assetWithURL:self.asset.defaultRepresentation.url];

    
    CGRect visibleRect = [self convertRect:self.bounds toView:self.videoPlayer.view];

    CGAffineTransform t = CGAffineTransformMakeScale( 1 / self.videoPlayerScale, 1 / self.videoPlayerScale);
    
    visibleRect = CGRectApplyAffineTransform(visibleRect, t);
    
    //竖屏的视频裁剪框要先转换为横屏模式
    CGFloat y;
    switch (orientation)
    {
        case UIInterfaceOrientationLandscapeLeft:
            
            break;
        case UIInterfaceOrientationLandscapeRight:
            
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            y =  visibleRect.origin.y;
            visibleRect.origin.y = visibleRect.origin.x;
            visibleRect.origin.x = y;
            break;
        default:
            y =  visibleRect.origin.y;
            visibleRect.origin.y = visibleRect.origin.x;
            visibleRect.origin.x = y;
    };
    
    //得到videoTrack正常播放时候进行转换的transform
    AVAssetTrack *videoTrack = [[[AVAsset assetWithURL:self.asset.defaultRepresentation.url] tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGAffineTransform txf = [videoTrack preferredTransform];
    //要剪切的矩形进行坐标转换
    visibleRect = CGRectApplyAffineTransform(visibleRect, txf);
    
    //转换为0-1
    t = CGAffineTransformMakeScale(1.0f / self.asset.defaultRepresentation.dimensions.width, 1.0f / self.asset.defaultRepresentation.dimensions.height);
    
    CGRect croprect = CGRectApplyAffineTransform(visibleRect, t);
    
    croprect = [self rangeRestrictForRect:croprect];
    
    movieFile = [[GPUImageMovie alloc] initWithAsset:asset];
    movieFile.runBenchmark = YES;
    movieFile.playAtActualSpeed = NO;
    
    filter = [[GPUImageCropFilter alloc] initWithCropRegion:croprect];
    //the camera sensor default orientation is LandscapeLeft
    switch (orientation)
    {
        case UIInterfaceOrientationLandscapeLeft:
            [filter setInputRotation:kGPUImageNoRotation atIndex:0];

            break;
        case UIInterfaceOrientationLandscapeRight:
            [filter setInputRotation:kGPUImageRotate180 atIndex:0];

            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            [filter setInputRotation:kGPUImageRotateLeft atIndex:0];

            break;
        default:
            [filter setInputRotation:kGPUImageRotateRight atIndex:0];

    };

    
    [movieFile addTarget:filter];
    
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(1080, 1080)];
    
    [filter addTarget:movieWriter];
    
    movieWriter.shouldPassthroughAudio = YES;
    movieFile.audioEncodingTarget = movieWriter;
    [movieFile enableSynchronizedEncodingUsingMovieWriter:movieWriter];
    
    [movieWriter startRecording];
    [movieFile startProcessing];
    
//    __weak GPUImageMovieWriter * weakWriter = movieWriter;
//    __weak GPUImageOutput<GPUImageInput>  * weakFilter = filter;
    
    //FIXME: 
    __block BOOL finished = NO;
    [movieWriter setCompletionBlock:^{
        NSLog(@"Completed Successfully");
        [movieWriter finishRecording];
        [filter removeTarget:movieWriter];
        finished = YES;
    }];
    while (!finished);
    return [AVAsset assetWithURL:movieURL];
}






#pragma mark -Image Process
- (UIImage *)capture
{
    
#warning 为什么一processing直接就能得到，GPU比CPU快这么多？
    
    CGRect visibleRect = [self _calcVisibleRectForCropArea];//caculate visible rect for crop
    CGAffineTransform rectTransform = [self _orientationTransformedRectOfImage:self.imageView.image];//if need rotate caculate
    visibleRect = CGRectApplyAffineTransform(visibleRect, rectTransform);

    //convert to 0-1
    CGAffineTransform t;
    if((self.imageView.image.imageOrientation == UIImageOrientationLeft) || ((self.imageView.image.imageOrientation == UIImageOrientationRight)))
     t = CGAffineTransformMakeScale(1.0f / self.imageView.image.size.height, 1.0f / self.imageView.image.size.width);
    else
     t = CGAffineTransformMakeScale(1.0f / self.imageView.image.size.width, 1.0f / self.imageView.image.size.height);
    
    CGRect unitRect = CGRectApplyAffineTransform(visibleRect, t);
    
    //incase <0 or >1

    unitRect = [self rangeRestrictForRect:unitRect];

    
    GPUImagePicture * picture = [[GPUImagePicture alloc] initWithImage:self.imageView.image];
    
    
    GPUImageCropFilter * cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:unitRect];
    
    [picture addTarget:cropFilter];
    [cropFilter useNextFrameForImageCapture];
    [picture processImage];

    UIImage * image =[cropFilter imageFromCurrentFramebufferWithOrientation:self.imageView.image.imageOrientation];
    return image;
    
    
    
    
//    CGRect visibleRect = [self _calcVisibleRectForCropArea];//caculate visible rect for crop
//    CGAffineTransform rectTransform = [self _orientationTransformedRectOfImage:self.imageView.image];//if need rotate caculate
//    visibleRect = CGRectApplyAffineTransform(visibleRect, rectTransform);
//    
//    CGImageRef ref = CGImageCreateWithImageInRect([self.imageView.image CGImage], visibleRect);//crop
//    UIImage* cropped = [[UIImage alloc] initWithCGImage:ref scale:self.imageView.image.scale orientation:self.imageView.image.imageOrientation] ;
//    return cropped;
}



static CGRect IGScaleRect(CGRect rect, CGFloat scale)
{
    return CGRectMake(rect.origin.x * scale, rect.origin.y * scale, rect.size.width * scale, rect.size.height * scale);
}

-(CGRect)_calcVisibleRectForCropArea{
    
    CGFloat sizeScale = self.imageView.image.size.width / self.imageView.frame.size.width;
    sizeScale *= self.zoomScale;
    CGRect visibleRect = [self convertRect:self.bounds toView:self.imageView];
    return visibleRect = IGScaleRect(visibleRect, sizeScale);
}

- (CGAffineTransform)_orientationTransformedRectOfImage:(UIImage *)img
{
    CGAffineTransform rectTransform;
    switch (img.imageOrientation)
    {
        case UIImageOrientationLeft:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(90)), 0, -img.size.height);
            break;
        case UIImageOrientationRight:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-90)), -img.size.width, 0);
            break;
        case UIImageOrientationDown:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-180)), -img.size.width, -img.size.height);
            break;
        default:
            rectTransform = CGAffineTransformIdentity;
    };
    
    return CGAffineTransformScale(rectTransform, img.scale, img.scale);
}



+ (UIInterfaceOrientation)orientationForTrack:(AVAsset *)asset
{
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGSize size = [videoTrack naturalSize];
    CGAffineTransform txf = [videoTrack preferredTransform];
    
    if (size.width == txf.tx && size.height == txf.ty)
        return UIInterfaceOrientationLandscapeRight;
    else if (txf.tx == 0 && txf.ty == 0)
        return UIInterfaceOrientationLandscapeLeft;
    else if (txf.tx == 0 && txf.ty == size.width)
        return UIInterfaceOrientationPortraitUpsideDown;
    else
        return UIInterfaceOrientationPortrait;
}


- (void)displayAsset:(ALAsset *)asset
{
    self.asset = asset;
    _type   = [asset valueForProperty:ALAssetPropertyType];
    
    // clear the previous image
    [self.imageView removeFromSuperview];
    self.imageView = nil;
    if(self.videoPlayer)
    {
        [self.videoPlayer stop];
        [self.videoPlayer.view removeFromSuperview];
    }

    
    //hide start mask and add observer
    self.videoStartMaskView.hidden = YES;

    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    
    
    if([_type isEqual:ALAssetTypePhoto])//photo
    {
        
        
        UIImage * image = [UIImage imageWithCGImage:asset.defaultRepresentation.fullResolutionImage scale:asset.defaultRepresentation.scale orientation:(UIImageOrientation)asset.defaultRepresentation.orientation];
        // reset our zoomScale to 1.0 before doing any further calculations
        self.zoomScale = 1.0;
        
        // make a new UIImageView for the new image
        self.imageView = [[UIImageView alloc] initWithImage:image];
        self.imageView.clipsToBounds = NO;
        [self addSubview:self.imageView];
        
        
        CGRect frame = self.imageView.frame;
        if (image.size.height > image.size.width) {
            frame.size.width = self.bounds.size.width;
            frame.size.height = (self.bounds.size.width / image.size.width) * image.size.height;
        } else {
            frame.size.height = self.bounds.size.height;
            frame.size.width = (self.bounds.size.height / image.size.height) * image.size.width;
        }
        self.imageView.frame = frame;
        [self configureForImageSize:self.imageView.bounds.size];
        _playState = 0;
    }
    else
    {

        
        self.videoPlayer = [[MPMoviePlayerController alloc] initWithContentURL:asset.defaultRepresentation.url];
        self.videoPlayer.controlStyle = MPMovieControlStyleNone;
        self.videoPlayer.movieSourceType = MPMovieSourceTypeFile;
        self.videoPlayer.scalingMode = MPMovieScalingModeAspectFill;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidFinishedCallBack:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
        
        CGSize assetSize = asset.defaultRepresentation.dimensions;
        CGSize size;
        if (assetSize.height > assetSize.width) {
            size.width = self.bounds.size.width;
            size.height = (self.bounds.size.width / assetSize.width) * assetSize.height;
            self.videoPlayerScale =  self.bounds.size.width / assetSize.width;

        } else {
            size.height = self.bounds.size.height;
            size.width = (self.bounds.size.height / assetSize.height) * assetSize.width;
            self.videoPlayerScale =  self.bounds.size.height / assetSize.height;

        }
        
        self.videoPlayer.view.frame = CGRectMake(0, 0, size.width, size.height);

        [self addSubview:self.videoPlayer.view];
        [self.videoPlayer play];
        [self configureForImageSize:self.videoPlayer.view.frame.size];
        
        _playState = 1;
    }
}


- (void)configureForImageSize:(CGSize)imageSize
{
    _imageSize = imageSize;
    self.contentSize = imageSize;
    
    //to center
    if (imageSize.width > imageSize.height) {
        self.contentOffset = CGPointMake(imageSize.width/4, 0);
    } else if (imageSize.width < imageSize.height) {
        self.contentOffset = CGPointMake(0, imageSize.height/4);
    }
    
    [self setMaxMinZoomScalesForCurrentBounds];
    self.zoomScale = self.minimumZoomScale;
}

- (void)setMaxMinZoomScalesForCurrentBounds
{
    self.minimumZoomScale = 1.0;
    self.maximumZoomScale = 2.0;
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if((self.videoPlayer) && (_playState == 2))
    {
        _playState = 1;
        [self.videoPlayer play];
        self.videoStartMaskView.hidden = YES;

        
    }
}

- (void) playerDidFinishedCallBack:(NSNotification *)notification
{
    _playState = 2;
    self.videoStartMaskView.hidden = NO;

}


#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}


@end
