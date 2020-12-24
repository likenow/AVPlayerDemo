//
//  KLVideoPlayer.h
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "KLVideoPlayerProtocols.h"

NS_ASSUME_NONNULL_BEGIN

@class KLVideoLoader;
@interface KLVideoPlayer : NSObject

- (instancetype)initWithVideoURL:(NSURL *)videoURL;

/// 初始化方法
/// @param videoURL 视频地址
/// @param download 是否需要自定义的下载功能，将下载到磁盘，需要为YES，否则为NO.
- (instancetype)initWithVideoURL:(NSURL *)videoURL downloadWhilePlay:(BOOL)download;

@property (nonatomic, assign, readonly) BOOL readyToPlay;
@property (nonatomic, assign, readonly) Float64 totalTime; //视频总时长，在readToPlay之后才能获取到。
@property (nonatomic, strong, readonly) NSURL *videoURL;
@property (nonatomic, assign, readonly) Float64 currentPlayTime; //当前播放时间
@property (nonatomic, assign, readonly) BOOL hasPlayed; //是否已经播放过

- (void)addDelegate:(id <KLVideoPlayerDelegate>)delegate;
- (void)removeDelegate:(id <KLVideoPlayerDelegate>)delegate;

- (void)clearCurrentVideoResource;

- (AVPlayerLayer *)createPlayerLayerForCurrenPlayer;

- (void)seekToTime:(Float64)seconds completion:(void(^)(BOOL finished))handler;

@property (nonatomic, assign, readonly) BOOL isPlay; //指示当前播放、暂停状态
- (void)play;
- (void)pause;
@property (nonatomic, assign) BOOL muted;

///如果videoLoaderd进度已经为1，播放器并没有回调readyToPlay，尝试重新加载播放器
@property (nonatomic, strong, readonly, nullable) KLVideoLoader *videoLoader;

/// 重新播放当前条目
/// @param block 回调
- (void)replayCurrentItemWithCompletion:(void (^ _Nullable)(BOOL finished))block;

/// 替换当前的播放条目
/// @param videoURL 视频的地址
- (void)replacePlayerItemWithVideoURL:(NSURL *)videoURL;

- (void)replacePlayerItemWithVideoURL:(NSURL *)videoURL downloadWhilePlay:(BOOL)download;

@end

NS_ASSUME_NONNULL_END
