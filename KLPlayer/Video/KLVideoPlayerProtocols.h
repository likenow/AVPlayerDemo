//
//  KLVideoPlayerProtocols.h
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class KLVideoPlayerControlView, KLVideoPlayerView;

@protocol KLVideoControlDelegate <NSObject>

- (void)videoPlayerControlViewDidTapedPlayButton:(KLVideoPlayerControlView *)controlView;
- (void)videoPlayerControlViewDidTapedVoiceButton:(KLVideoPlayerControlView *)controlView;
@optional
- (void)videoPlayerControlViewDidTapedFullScreen:(KLVideoPlayerControlView *)controlView;
- (void)videoPlayerControlViewDidHidden:(KLVideoPlayerControlView *)controlView;

@end


@protocol KLVideoPlayerViewDelegate <NSObject>
@required
- (void)videoPlayerView:(KLVideoPlayerView *)playerView didTapedPlay:(BOOL)isPlay;
- (void)videoPlayerView:(KLVideoPlayerView *)playerView didTapedMuted:(BOOL)isMuted;
- (BOOL)videoPlayerViewNeedShowControlView:(KLVideoPlayerView *)playerView;

@optional
- (BOOL)videoPlayerViewShouldPlay:(KLVideoPlayerView *)playerView;
- (void)videoPlayerView:(KLVideoPlayerView *)playerView showControlView:(BOOL)show;

@end

@protocol KLVideoPlayerDelegate <NSObject>
@optional
- (void)kl_videoPlayToTime:(Float64)time;

/**
 已经准备好可以播放，可获取视频时长了。
 */
- (void)kl_videoPlayerHasReadyToPlay;

/**
 播放器失败，不可恢复
 */
- (void)kl_videoPlayerHasPlayFailed:(NSError *)error;

/**
 缓冲区空
 */
- (void)kl_videoPlayerBufferEmpty;

/**
 缓冲区可以播放
 */
- (void)kl_videoPlayerLikelyKeepUp;

/**
 播放完成
 */
- (void)kl_videoPlayerHasPlayFinished;

/**
 播放状态改变，可通过isPlay属性获取状态
 */
- (void)kl_videoPlayerPlayStateHasChanged;

/**
 静音状态改变，可通过muted属性获取状态
 */
- (void)kl_videoPlayerMutedStateHasChanged;

/**
 耳机拔出了
 @attention 播放器内部默认暂停了视频，如果需要更改此行为，可在该方法内部调用播放方法.
 @note 耳机拔出时，系统暂停了播放器，而播放器无任何事件通知
 */
- (void)kl_headphonesUnavailable;

/**
 视频被其他任务阻断，如电话
 @attention 播放器内部，默认会暂停视频
 */
- (void)kl_videoHasBeenInterrupted;

/**
 视频中断可以恢复了
 */
- (void)kl_videoInterruptionCanResume;

@end


NS_ASSUME_NONNULL_END
