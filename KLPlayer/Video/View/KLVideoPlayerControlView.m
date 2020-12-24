//
//  KLVideoPlayerControlView.m
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import "KLVideoPlayerControlView.h"
#import "KLGCDTimer.h"
#import "UIView+KLExtension.h"
#import "KLPlayerTool.h"
#import "KLPlayerMacros.h"


static CGFloat kBottomContentViewHeight = 60;
static CGFloat kControlButtonBottomMargin = 10;
static CGFloat kControlButtonWidth = 30;
static CGFloat kControlButtonHeight = 30;

static CGFloat kControlButtonRightMargin = 10;
static NSTimeInterval kKLVideoAutoHiddenControlViewTime = 4.0;

@interface KLVideoPlayerControlView ()

@property (nonatomic, strong) UIImageView *bottomContentView;
@property (nonatomic, strong) UIImageView *playImageView;
@property (nonatomic, strong) UIImageView *voiceImageView;
@property (nonatomic, strong) UIImageView *fullScreenImageView;

@property (nonatomic, strong) KLGCDTimer *timer;

@property (nonatomic, strong) UIView *topContentView;

@end

@implementation KLVideoPlayerControlView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        _needFullScreen = NO;
        _externalBottomMargin = 0;
        self.backgroundColor = [UIColor clearColor];
        __weak typeof(self) weakSelf = self;
        [self kl_setTapActionWithBlock:^{
            [weakSelf hiddenSelf];
        }];
                
        _bottomContentView = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.kl_h-kBottomContentViewHeight, self.kl_w, kBottomContentViewHeight+_externalBottomMargin)];
        _bottomContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _bottomContentView.userInteractionEnabled = YES;
        _bottomContentView.backgroundColor = RGBAColor(31, 31, 31, 0.6);
        [self addSubview:_bottomContentView];
        
        _playImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, kBottomContentViewHeight-kControlButtonHeight-kControlButtonBottomMargin, kControlButtonWidth, kControlButtonHeight)];
        _play = NO;
        [_bottomContentView addSubview:_playImageView];
        
        [_playImageView kl_setTapActionWithBlock:^{
            [weakSelf playButtonTaped];
        }];
        
        _fullScreenImageView = [[UIImageView alloc] initWithFrame:CGRectMake(_bottomContentView.kl_w-kControlButtonRightMargin-kControlButtonWidth, _playImageView.kl_y, kControlButtonWidth, kControlButtonHeight)];
        _fullScreen = NO;
        [_bottomContentView addSubview:_fullScreenImageView];
        
        [_fullScreenImageView kl_setTapActionWithBlock:^{
            [weakSelf fullScreenButtonTaped];
        }];
        
        _voiceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(_fullScreenImageView.kl_x-15-kControlButtonWidth, _playImageView.kl_y, kControlButtonWidth, kControlButtonHeight)];
        _muted = NO;
        [_bottomContentView addSubview:_voiceImageView];
        [_voiceImageView kl_setTapActionWithBlock:^{
            [weakSelf voiceButtonTaped];
        }];
        
        CGFloat progressX = _playImageView.kl_maxX+10;
        CGFloat progressWidth = _bottomContentView.kl_w - progressX - kControlButtonWidth - kControlButtonRightMargin - 10;
        _progressBar = [[KLVideoProgressBar alloc] initWithFrame:CGRectMake(progressX, _playImageView.kl_minY, progressWidth, kControlButtonHeight)];
        [_bottomContentView addSubview:_progressBar];
    }
    return self;
}

- (void)setNeedFullScreen:(BOOL)needFullScreen
{
    _needFullScreen = needFullScreen;
    [self setNeedsLayout];
}

- (void)setExternalBottomMargin:(CGFloat)externalBottomMargin
{
    _externalBottomMargin = externalBottomMargin;
    if (externalBottomMargin > 0) {
        [self setNeedsLayout];
        self.bottomContentView.backgroundColor = RGBAColor(31, 31, 31, 0.6);
    }
}

- (void)hiddenSelf
{
    self.hidden = YES;
}

- (void)setShowProgressBar:(BOOL)showProgressBar
{
    _showProgressBar = showProgressBar;
    self.progressBar.hidden = !showProgressBar;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.progressBar.hidden = self.needFullScreen;
    CGFloat bottomContentViewHeight = kBottomContentViewHeight+self.externalBottomMargin;
    self.bottomContentView.frame = CGRectMake(0, self.kl_h-bottomContentViewHeight, self.kl_w, bottomContentViewHeight);
    
    self.playImageView.frame = CGRectMake(10, bottomContentViewHeight-kControlButtonHeight-kControlButtonBottomMargin-self.externalBottomMargin, kControlButtonWidth, kControlButtonHeight);
    if (self.needFullScreen) {
        self.fullScreenImageView.frame = CGRectMake(self.bottomContentView.kl_w-kControlButtonRightMargin-kControlButtonWidth, self.playImageView.kl_y, kControlButtonWidth, kControlButtonHeight);
        self.voiceImageView.frame = CGRectMake(self.fullScreenImageView.kl_x-15-kControlButtonWidth, self.playImageView.kl_y, kControlButtonWidth, kControlButtonHeight);
    } else {
        if (self.showProgressBar) {
            CGFloat progressX = self.playImageView.kl_maxX+10;
            CGFloat progressWidth = self.bottomContentView.kl_w - progressX - kControlButtonWidth - kControlButtonRightMargin - 10;
            self.progressBar.frame = CGRectMake(progressX, self.playImageView.kl_minY, progressWidth, kControlButtonHeight);
        } else {
            self.progressBar.hidden = YES;
        }
        self.voiceImageView.frame = self.fullScreenImageView.frame;
        self.fullScreenImageView.hidden = YES;
    }
}

- (void)setFullScreen:(BOOL)fullScreen
{
    _fullScreen = fullScreen;
    if (fullScreen) {
        self.fullScreenImageView.image = [KLPlayerTool imageWithName:@"kl_video_zoom_fullscreen"];
    } else {
        self.fullScreenImageView.image = [KLPlayerTool imageWithName:@"kl_video_full_screen"];
    }
}

- (void)setHiddenTimer
{
    [self.timer invalidate];
    self.timer = nil;
    
    __weak typeof(self) weakSelf = self;
    self.timer = [KLGCDTimer scheduleGCDTimerAfterTimeInterval:kKLVideoAutoHiddenControlViewTime block:^{
        [weakSelf hiddenSelf];
    }];
}

- (void)invalidateTimer
{
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    
    if (hidden) {
        [self invalidateTimer];
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerControlViewDidHidden:)]) {
            [self.delegate videoPlayerControlViewDidHidden:self];
        }
    } else {
        [self invalidateTimer];
        [self setHiddenTimer];
    }
}

- (void)setMuted:(BOOL)muted
{
    _muted = muted;
    if (muted) {
        self.voiceImageView.image = [KLPlayerTool imageWithName:@"kl_video_no_voice"];
    } else {
        self.voiceImageView.image = [KLPlayerTool imageWithName:@"kl_video_voice"];
    }
}

- (void)setPlay:(BOOL)play
{
    _play = play;
    if (play) {
        self.playImageView.image = [KLPlayerTool imageWithName:@"kl_video_pause"];
    } else {
        self.playImageView.image = [KLPlayerTool imageWithName:@"kl_video_play"];
    }
}

- (void)playButtonTaped
{
    [self setHiddenTimer];
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerControlViewDidTapedPlayButton:)]) {
        [self.delegate videoPlayerControlViewDidTapedPlayButton:self];
    }
}

- (void)voiceButtonTaped
{
    [self setHiddenTimer];
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerControlViewDidTapedVoiceButton:)]) {
        [self.delegate videoPlayerControlViewDidTapedVoiceButton:self];
    }
}

- (void)fullScreenButtonTaped
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerControlViewDidTapedFullScreen:)]) {
        [self.delegate videoPlayerControlViewDidTapedFullScreen:self];
    }
}


@end
