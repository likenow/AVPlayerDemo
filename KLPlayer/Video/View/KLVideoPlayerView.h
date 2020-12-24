//
//  KLVideoPlayerView.h
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import <UIKit/UIKit.h>
#import "KLVideoPlayerControlView.h"
#import "KLVideoView.h"
#import "KLVideoPlayerProtocols.h"

NS_ASSUME_NONNULL_BEGIN

@interface KLVideoPlayerView : UIView

@property (nonatomic, strong, readonly) KLVideoView *videoView;
@property (nonatomic, weak) id <KLVideoPlayerViewDelegate> delegate;
@property (nonatomic, assign) BOOL fullScreen;

@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong, readonly) KLVideoPlayerControlView *controlView;

/// 是否以第一帧（封面图）作为结束播放的最后画面，默认是 NO
@property (nonatomic, assign) BOOL isEndByFirstFrameImage;

- (void)setControlViewIsShow:(BOOL)show;

- (void)setFirstFrameImageURL:(NSString *)url;
- (void)setFirstFrameImage:(UIImage *)image;

- (void)setPlayState:(BOOL)isPlay;
- (void)setMutedState:(BOOL)muted;

- (void)setLoadingViewShow:(BOOL)show;
- (void)videoHasPlayFailed;
- (void)videoHasPlayFinished;

@end

NS_ASSUME_NONNULL_END
