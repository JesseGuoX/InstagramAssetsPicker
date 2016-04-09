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
    PHAssetMediaType _mediaType;
    
    AVAssetExportSession *exporter;
}

@property (strong, nonatomic) UIImageView *imageView;
@property (nonatomic, strong) MPMoviePlayerController *videoPlayer;
@property (nonatomic) CGFloat videoPlayerScale;
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



-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    
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

-(void)getCropRegion:(void(^)(CGRect))completeBlock
{
    if (self.phAsset)
    {
        if (_mediaType == PHAssetResourceTypePhoto)
        {
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
            
            completeBlock(unitRect);
        }
        else if (_mediaType == PHAssetMediaTypeVideo)
        {
            PHImageManager *manager = [PHImageManager defaultManager];
            PHVideoRequestOptions *requestOptions = [[PHVideoRequestOptions alloc] init];
            requestOptions.networkAccessAllowed = true;
            
            [manager requestAVAssetForVideo:self.phAsset options:requestOptions resultHandler:^(AVAsset *avAsset, AVAudioMix *audioMix, NSDictionary *info) {
                UIInterfaceOrientation orientation = [IGCropView orientationForTrack:avAsset];
                
                CGRect visibleRect = [self convertRect:self.bounds toView:self.videoPlayer.view];
                
                CGAffineTransform t = CGAffineTransformMakeScale( 1 / self.videoPlayerScale, 1 / self.videoPlayerScale);
                
                visibleRect = CGRectApplyAffineTransform(visibleRect, t);
                
                // Vertical screen video cropping frame must first be converted to landscape mode
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
                
                // Get videoTrack normal play time for conversion transform
                AVAssetTrack *videoTrack = [[avAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
                CGAffineTransform txf = [videoTrack preferredTransform];
                // To cut a rectangular coordinate conversion
                visibleRect = CGRectApplyAffineTransform(visibleRect, txf);
                
                // Converted to 0-1
                t = CGAffineTransformMakeScale(1.0f / self.phAsset.pixelWidth, 1.0f / self.phAsset.pixelHeight);
                
                CGRect croprect = CGRectApplyAffineTransform(visibleRect, t);
                
                croprect = [self rangeRestrictForRect:croprect];
                
                completeBlock(croprect);
            }];
        }
        else
            completeBlock(CGRectNull);
    }
    else
        completeBlock(CGRectNull);
    
    
}

- (void)cropAsset:(void(^)(id))completeBlock
{
    [self getCropRegion:^(CGRect rect) {
        [IGCropView cropPhAsset:self.phAsset withRegion:rect onComplete:^(id croppedAsset) {
            completeBlock(croppedAsset);
        }];
    }];
}


+(void)cropPhAsset:(PHAsset *)asset withRegion:(CGRect)rect onComplete:(void(^)(id))completion
{
    if(asset)
    {
        if(asset.mediaType == PHAssetMediaTypeImage)//photo
        {
            PHImageManager *manager = [PHImageManager defaultManager];
            
            PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
            requestOptions.synchronous = true;
            requestOptions.networkAccessAllowed = true;
            requestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
            requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            
            [manager requestImageForAsset:asset
                               targetSize:PHImageManagerMaximumSize
                              contentMode:PHImageContentModeDefault
                                  options:requestOptions
                            resultHandler:^void(UIImage *image, NSDictionary *info) {
                                
                                completion([self cropImage:image withRegion:rect]);
                                
                            }];
            
        }
        else if(asset.mediaType == PHAssetMediaTypeVideo)//video
        {
            [self cropVideo:asset withRegion:rect onComplete:^(NSURL *movieURL) {
                completion(movieURL);
            }];
        }
        else
            completion(nil);
    }
    else
        completion(nil);
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

+ (void)cropVideo:(PHAsset *)asset withRegion:(CGRect)rect onComplete:(void(^)(NSURL *))completion
{
    PHImageManager *manager = [PHImageManager defaultManager];
    PHVideoRequestOptions *requestOptions = [[PHVideoRequestOptions alloc] init];
    requestOptions.networkAccessAllowed = true;
    
    [manager requestAVAssetForVideo:asset options:requestOptions resultHandler:^(AVAsset *avAsset, AVAudioMix *audioMix, NSDictionary *info) {
        UIInterfaceOrientation orientation = [IGCropView orientationForTrack:avAsset];
        
        GPUImageMovie *movieFile;
        GPUImageOutput<GPUImageInput> *filter;
        GPUImageMovieWriter *movieWriter;
        
        movieFile = [[GPUImageMovie alloc] initWithAsset:avAsset];
        movieFile.runBenchmark = YES;
        movieFile.playAtActualSpeed = NO;
        
        filter = [[GPUImageCropFilter alloc] initWithCropRegion:rect];
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
        
        NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *pathToMovie = [cacheDir stringByAppendingString:@"/movie.mp4"];
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
        completion(movieURL);
    }];
}




#pragma mark -Image Process

+ (UIImage *)cropImage:(UIImage *)image withRegion:(CGRect)rect
{
    GPUImagePicture * picture = [[GPUImagePicture alloc] initWithImage:image];
    
    GPUImageCropFilter * cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:rect];
    
    [picture addTarget:cropFilter];
    [cropFilter useNextFrameForImageCapture];
    [picture processImage];
    
    UIImage * returnImage =[cropFilter imageFromCurrentFramebufferWithOrientation:image.imageOrientation];
    return returnImage;
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

- (void)setPhAsset:(PHAsset *)asset
{
    _phAsset = asset;
    _mediaType = [asset mediaType];
    
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
    
    PHImageManager *manager = [PHImageManager defaultManager];
    
    if(_mediaType == PHAssetMediaTypeImage)//photo
    {
        PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
        requestOptions.synchronous = false;
        requestOptions.networkAccessAllowed = true;
        requestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        
        [manager requestImageForAsset:asset
                           targetSize:PHImageManagerMaximumSize
                          contentMode:PHImageContentModeDefault
                              options:requestOptions
                        resultHandler:^void(UIImage *image, NSDictionary *info) {
                            
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
                        }];
        
        
    }
    else
    {
        PHVideoRequestOptions *requestOptions = [[PHVideoRequestOptions alloc] init];
        requestOptions.networkAccessAllowed = true;
        
        [manager requestAVAssetForVideo:asset options:requestOptions resultHandler:^(AVAsset *avAsset, AVAudioMix *audioMix, NSDictionary *info) {
            AVURLAsset *urlAsset = (AVURLAsset *)avAsset;
            
            self.videoPlayer = [[MPMoviePlayerController alloc] initWithContentURL: urlAsset.URL];
            self.videoPlayer.controlStyle = MPMovieControlStyleNone;
            self.videoPlayer.movieSourceType = MPMovieSourceTypeFile;
            self.videoPlayer.scalingMode = MPMovieScalingModeAspectFill;
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidFinishedCallBack:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
            
            CGSize size;
            if (asset.pixelHeight > asset.pixelWidth) {
                size.width = self.bounds.size.width;
                size.height = (self.bounds.size.width / asset.pixelWidth) * asset.pixelHeight;
                self.videoPlayerScale =  self.bounds.size.width / asset.pixelWidth;
                
            } else {
                size.height = self.bounds.size.height;
                size.width = (self.bounds.size.height / asset.pixelHeight) * asset.pixelWidth;
                self.videoPlayerScale =  self.bounds.size.height / asset.pixelHeight;
                
            }
            
            self.videoPlayer.view.frame = CGRectMake(0, 0, size.width, size.height);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self addSubview:self.videoPlayer.view];
                [self.videoPlayer play];
                [self configureForImageSize:self.videoPlayer.view.frame.size];
                
                _playState = 1;
            });
            
        }];
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

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - MPMoviePlayerController Notification
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
