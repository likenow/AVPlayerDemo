//
//  KLVideoController.m
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import "KLVideoController.h"
#import "KLVideoPlayer.h"
#import "KLVideoPlayerView.h"
#import "KLPlayerTool.h"
#import "KLVideoPlayerProtocols.h"
#import <SDWebImage/SDWebImage.h>

NSNotificationName kKLVideoPlayStateDidChangeNotification = @"kKLVideoPlayStateDidChangeNotification";

@interface KLVideoController () <KLVideoPlayerDelegate, KLVideoPlayerViewDelegate>

@property (nonatomic, strong) KLVideoPlayerView *playerView;
@property (nonatomic, strong) KLVideoPlayer *videoPlayer;

@property (nonatomic, copy) void (^videoReadyToPlayBlock) (void);
@property (nonatomic, copy) void (^videoPlayTimeBlock) (Float64);
@property (nonatomic, copy) void (^videoPlayFailedBlock) (NSError *);
@property (nonatomic, copy) void (^videoPlayStateBlock) (BOOL);
@property (nonatomic, copy) void (^videoPlayFinishedBlock) (void);
@property (nonatomic, copy) void (^videoFirstFrameImageLoadCompletion) (BOOL success, UIImage *image, NSError *error, NSURL *imageURL);

@end

@implementation KLVideoController

- (void)dealloc
{
    if (self.videoPlayer) {
        [self.videoPlayer clearCurrentVideoResource];
    }
}

- (instancetype)initWithVideoURL:(NSURL *)videoURL viewFrame:(CGRect)frame
{
    return [self initWithVideoURL:videoURL videoFirstFrameImageURL:nil viewFrame:frame];
}
- (instancetype)initWithVideoURL:(NSURL *)videoURL videoFirstFrameImageURL:(nullable NSString *)firstFrameImage viewFrame:(CGRect)frame {
    return [self initWithVideoURL:videoURL videoFirstFrameImageURL:firstFrameImage viewFrame:frame downloadWhilePlay:NO];
    
}
- (instancetype)initWithVideoURL:(NSURL *)videoURL videoFirstFrameImageURL:(NSString *)firstFrameImage viewFrame:(CGRect)frame downloadWhilePlay:(BOOL)download {
    self = [super init];
    if (self) {
        _videoPlayer = [[KLVideoPlayer alloc] initWithVideoURL:videoURL downloadWhilePlay:download];
        [_videoPlayer addDelegate:self];
        _isLooping = YES;
        _isAutoDispose = NO;
        _playerView = [[KLVideoPlayerView alloc] initWithFrame:frame];
        AVPlayerLayer *playerLayer = [_videoPlayer createPlayerLayerForCurrenPlayer];
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _playerView.playerLayer = playerLayer;
        _playerView.delegate = self;
        if (firstFrameImage.length > 0) {
            [_playerView setFirstFrameImageURL:firstFrameImage];
        } else {
            [self firstFrameWithVideoURL:videoURL];
        }
        
    }
    return self;
}

/// 获取视频第一帧
- (UIImage *)firstFrameWithVideoURL:(NSURL *)url {
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *assetGen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetGen.appliesPreferredTrackTransform = YES;
    
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);// 与清晰度相关
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [assetGen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *videoImage = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    return videoImage;
}


- (void)setVideoHasReadBlock:(void (^)(void))block
{
    self.videoReadyToPlayBlock = block;
}

- (void)setVideoPlayTimeBlock:(void (^)(Float64))block
{
    _videoPlayTimeBlock = block;
}

- (void)setVideoHasPlayFailedBlock:(void (^)(NSError *))block
{
    self.videoPlayFailedBlock = block;
}

- (void)setVideoHasPlayFinishedBlock:(void (^)(void))block
{
    self.videoPlayFinishedBlock = block;
}

- (void)setVideoPlayStateBlock:(void (^)(BOOL))block
{
    _videoPlayStateBlock = block;
}

- (void)setVideoFirstFrameHasLoadCompletionBlock:(void (^)(BOOL, UIImage *, NSError *, NSURL *))block
{
    self.videoFirstFrameImageLoadCompletion = block;
}

#pragma mark - Delegate
- (void)kl_videoPlayToTime:(Float64)time
{
    if (self.videoPlayTimeBlock) {
        self.videoPlayTimeBlock(time);
    }
    if (self.playerView.controlView.showProgressBar) {
        NSString *currentTimeText = [KLPlayerTool formatTimeWithTotalSeconds:time];
        [self.playerView.controlView.progressBar setLeftLabelText:currentTimeText];
        if (self.videoPlayer.totalTime > 0) {
            CGFloat progress = time / self.videoPlayer.totalTime;
            [self.playerView.controlView.progressBar setProgress:progress];
        } else {
            [self.playerView.controlView.progressBar setProgress:0];
        }
    }
}

- (void)kl_videoPlayerHasReadyToPlay
{
    Float64 totalTime = self.videoPlayer.totalTime;
    if (totalTime >= 15) {
        NSString *totalTimeText = [KLPlayerTool formatTimeWithTotalSeconds:totalTime];
        [self.playerView.controlView.progressBar setRightLabelText:totalTimeText];
    } else {
        self.playerView.controlView.showProgressBar = NO;
    }
    
    if (self.videoReadyToPlayBlock) {
        self.videoReadyToPlayBlock();
    }
}

- (void)kl_videoPlayerHasPlayFailed:(NSError *)error
{
    [self.playerView videoHasPlayFailed];
    if (self.videoPlayFailedBlock) {
        self.videoPlayFailedBlock(error);
    }
}

- (void)kl_videoPlayerBufferEmpty
{
    [self.playerView setLoadingViewShow:YES];
}

- (void)kl_videoPlayerLikelyKeepUp
{
    [self.playerView setLoadingViewShow:NO];
}

- (void)kl_videoPlayerHasPlayFinished
{
    [self.playerView videoHasPlayFinished];
    if (self.videoPlayFinishedBlock) {
        self.videoPlayFinishedBlock();
    }
    if (self.isLooping) {
        [self.videoPlayer replayCurrentItemWithCompletion:^(BOOL finished) {
            
        }];
    }
    if (self.isAutoDispose) {
        [self.videoPlayer clearCurrentVideoResource];
    }
}

- (void)kl_videoPlayerPlayStateHasChanged
{
    BOOL isPlay = self.videoPlayer.isPlay;
    [self.playerView setPlayState:isPlay];
    if (self.videoPlayStateBlock) {
        self.videoPlayStateBlock(isPlay);
    }
}

- (void)kl_videoPlayerMutedStateHasChanged
{
    BOOL isMuted = self.videoPlayer.muted;
    [self.playerView setMutedState:isMuted];
}

#pragma mark -Delegate
- (BOOL)videoPlayerViewNeedShowControlView:(KLVideoPlayerView *)playerView
{
    return self.videoPlayer.readyToPlay;
}

- (void)videoPlayerView:(KLVideoPlayerView *)playerView didTapedPlay:(BOOL)isPlay
{
    if (isPlay) {
        [self.videoPlayer play];
    } else {
        [self.videoPlayer pause];
    }
    //用户主动点击了播放按钮，
    [[NSNotificationCenter defaultCenter] postNotificationName:kKLVideoPlayStateDidChangeNotification object:self userInfo:nil];
}

- (void)videoPlayerView:(KLVideoPlayerView *)playerView didTapedMuted:(BOOL)isMuted
{
    self.videoPlayer.muted = isMuted;
}

- (BOOL)videoPlayerViewShouldPlay:(KLVideoPlayerView *)playerView
{
    return self.videoPlayer.readyToPlay;
}

@end
