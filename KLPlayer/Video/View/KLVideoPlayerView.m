//
//  KLVideoPlayerView.m
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import "KLVideoPlayerView.h"
#import "KLVideoView.h"
#import "KLGCDTimer.h"
#import "KLVideoLoadingView.h"
#import "KLPlayerMacros.h"
#import "SDWebImage.h"

@interface KLVideoPlayerView () <KLVideoControlDelegate, KLVideoPlayerDelegate>

@property (nonatomic, assign) BOOL muted;
@property (nonatomic, assign) BOOL isPlay;

//@property (nonatomic, assign) BOOL readyPlay;

@property (nonatomic, assign) BOOL controlViewShow;
@property (nonatomic, strong) KLVideoLoadingView *loadingView;

@property (nonatomic, strong) KLVideoView *videoView;

@property (nonatomic, strong) KLVideoLoadingView *initialLoadingView;

@property (nonatomic, strong) KLGCDTimer *timer;
@property (nonatomic, strong) UIControl *tapControl;
@property (nonatomic, assign) BOOL playFinished;

@property (nonatomic, strong) KLVideoPlayerControlView *controlView;

@property (nonatomic, strong) UIImageView *firstFrameImageView;

@end

@implementation KLVideoPlayerView

- (void)dealloc
{
    [self.timer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = RGBAColor(51, 51, 51, 1);
        
        self.initialLoadingView = [[KLVideoLoadingView alloc] initWithFrame:self.bounds];
        self.initialLoadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.initialLoadingView];
        
        self.firstFrameImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.firstFrameImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        self.firstFrameImageView.userInteractionEnabled = NO;
        self.firstFrameImageView.backgroundColor = [UIColor clearColor];
        [self addSubview:self.firstFrameImageView];
        
        self.tapControl = [[UIControl alloc] initWithFrame:self.bounds];
        self.tapControl.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self.tapControl addTarget:self action:@selector(userDidTapedVideo) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.tapControl];
        
        self.videoView = [[KLVideoView alloc] initWithFrame:self.bounds];
        self.videoView.backgroundColor = [UIColor clearColor];
        self.videoView.userInteractionEnabled = NO;//只做视频展示层，不做其他
        [self addSubview:self.videoView];
        
        self.controlView = [[KLVideoPlayerControlView alloc] initWithFrame:self.bounds];
        self.controlView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        self.controlView.delegate = self;
        self.controlView.hidden = YES;
        self.controlViewShow = NO;
        self.controlView.needFullScreen = NO;
        self.controlView.showProgressBar = YES;
        [self addSubview:self.controlView];
        
        self.loadingView = [[KLVideoLoadingView alloc] initWithFrame:self.bounds];
        self.loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        self.loadingView.hidden = YES;
        [self addSubview:self.loadingView];
        
//        self.readyPlay = NO;
        _isEndByFirstFrameImage = NO;
    }
    return self;
}

- (void)setSafeAreaInsets:(UIEdgeInsets)inset {}

- (void)setFirstFrameImage:(UIImage *)image
{
    self.firstFrameImageView.image = image;
    
}

- (void)setFirstFrameImageURL:(NSString *)url
{
    if (!url) {
        return;
    }
    [self.firstFrameImageView sd_setImageWithURL:[NSURL URLWithString:url] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        
    }];
}

- (void)setPlayerLayer:(AVPlayerLayer *)playerLayer
{
    self.videoView.playerLayer = playerLayer;
    _playerLayer = playerLayer;
}

- (void)setPlayState:(BOOL)isPlay
{
    [self innerSetPlayState:isPlay];
}

- (void)setMutedState:(BOOL)muted
{
    self.muted = muted;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.videoView.frame = self.bounds;
    self.loadingView.frame = self.bounds;
}

- (void)innerSetPlayState:(BOOL)isPlay
{
    self.isPlay = isPlay;
    self.controlView.play = isPlay;
}

- (void)setMuted:(BOOL)muted
{
    _muted = muted;
    self.controlView.muted = muted;
}

- (void)setFullScreen:(BOOL)fullScreen
{
    _fullScreen = fullScreen;
    self.controlView.fullScreen = fullScreen;
}

- (void)setLoadingViewShow:(BOOL)show
{
    self.loadingView.hidden = !show;
}

- (void)videoHasPlayFailed
{
    self.initialLoadingView.hidden = YES;
    self.loadingView.hidden = YES;
}

- (void)videoHasPlayFinished
{
    self.isPlay = NO;
    self.playFinished = YES;
    self.controlView.play = NO;
    if (self.isEndByFirstFrameImage) {
        if (self.firstFrameImageView.image) {
            [self bringSubviewToFront:self.firstFrameImageView];
            self.isEndByFirstFrameImage = NO;
        }
    }
    
}

- (void)setControlViewIsShow:(BOOL)show
{
    if (show) {
        self.controlView.hidden = NO;
        self.controlViewShow = YES;
    } else {
        self.controlView.hidden = YES;
        self.controlViewShow = NO;
    }
}

#pragma mark - Private
- (void)showControlView:(BOOL)show
{
    [self setControlViewIsShow:show];
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerView:showControlView:)]) {
        [self.delegate videoPlayerView:self showControlView:show];
    }
}

- (void)userDidTapedVideo
{
    if (!self.loadingView.hidden) {
        return;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerViewNeedShowControlView:)]) {
        BOOL isNeed = [self.delegate videoPlayerViewNeedShowControlView:self];
        if (isNeed) {
            [self showControlView:YES];
        }
    }
}

#pragma mark - KLVideoControlDelegate
- (void)videoPlayerControlViewDidHidden:(KLVideoPlayerControlView *)controlView
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerView:showControlView:)]) {
        [self.delegate videoPlayerView:self showControlView:NO];
    }
}

- (void)videoPlayerControlViewDidTapedPlayButton:(KLVideoPlayerControlView *)controlView
{
    if (self.isPlay) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerView:didTapedPlay:)]) {
            [self.delegate videoPlayerView:self didTapedPlay:NO];
        }
        [self innerSetPlayState:NO];
    } else {
        BOOL shouldPlay = YES;
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerViewShouldPlay:)]) {
            shouldPlay = [self.delegate videoPlayerViewShouldPlay:self];
        }
        if (shouldPlay) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerView:didTapedPlay:)]) {
                [self.delegate videoPlayerView:self didTapedPlay:YES];
            }
            [self innerSetPlayState:YES];
        }
    }
}

- (void)videoPlayerControlViewDidTapedVoiceButton:(KLVideoPlayerControlView *)controlView
{
    self.muted = !self.muted;
    if (self.delegate  && [self.delegate respondsToSelector:@selector(videoPlayerView:didTapedMuted:)]) {
        [self.delegate videoPlayerView:self didTapedMuted:self.muted];
    }
}

@end
