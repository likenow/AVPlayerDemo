//
//  KLVideoPlayer.m
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import "KLVideoPlayer.h"
#import "KLVideoLoader.h"

@interface KLVideoPlayer ()

@property (nonatomic, strong) NSURL *videoURL;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, assign) Float64 totalTime;
@property (nonatomic, assign) BOOL readyToPlay;
@property (nonatomic, strong) NSHashTable *hashTable;
@property (nonatomic, assign) BOOL isPlay;
@property (nonatomic, assign) Float64 currentPlayTime;
@property (nonatomic, assign) BOOL hasPlayed;
@property (nonatomic, assign) BOOL playWhenInBackground;

@property (nonatomic, strong) KLVideoLoader *videoLoader;
@property (nonatomic, strong) AVURLAsset *urlAsset;

@property (nonatomic, strong) id playbackObserver;

@end

@implementation KLVideoPlayer

- (void)dealloc
{
    [self clearCurrentVideoResource];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithVideoURL:(NSURL *)videoURL
{
    return [self initWithVideoURL:videoURL downloadWhilePlay:YES];
}

- (instancetype)initWithVideoURL:(NSURL *)videoURL downloadWhilePlay:(BOOL)download
{
    if (self = [super init]) {
        self.videoURL = videoURL;
        if (!videoURL) {
            [self clearCurrentVideoResource];
            return nil;
        }
        self.currentPlayTime = 0;
        self.hasPlayed = NO;
        AVURLAsset *asset = nil;
        if (download) {
            NSURLComponents *components = [[NSURLComponents alloc] initWithURL:videoURL resolvingAgainstBaseURL:NO];
            components.scheme = @"klp";
            NSURL *fakeURL = [components URL];
            
            asset = [AVURLAsset URLAssetWithURL:fakeURL options:nil];
            self.videoLoader = [KLVideoLoader loaderWithVideoURL:videoURL];
            [asset.resourceLoader setDelegate:self.videoLoader queue:dispatch_get_main_queue()];
        } else {
            asset = [AVURLAsset assetWithURL:videoURL];
        }
        self.urlAsset = asset;
        self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
        self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
        [self addPlayItemObserver];
        
        __weak typeof(self) weakSelf = self;
        self.playbackObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            [weakSelf playToTime:time];
        }];
        
        self.readyToPlay = NO;
        self.hashTable = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
        self.totalTime = 0;
        self.playWhenInBackground = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPlayFinish:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        self.isPlay = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackground:) name:NSExtensionHostDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterForeground:) name:NSExtensionHostDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeCallback:)  name:AVAudioSessionRouteChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioInterruption:) name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
    }
    return self;
}

- (void)addDelegate:(id<KLVideoPlayerDelegate>)delegate
{
    [self.hashTable addObject:delegate];
}

- (void)removeDelegate:(id<KLVideoPlayerDelegate>)delegate
{
    [self.hashTable removeObject:delegate];
}



- (void)clearCurrentVideoResource
{
    if (self.playerItem) {
        // 释放一个正在播放的视频时，需要先调用pause方法
        [self pause];
        // 释放资源
        [self.playerItem cancelPendingSeeks];
        [self.playerItem.asset cancelLoading];
        if (self.player) {
            [self.player replaceCurrentItemWithPlayerItem:nil];
        }
    }
    
    
    if (self.playbackObserver) {
        [self.player removeTimeObserver:self.playbackObserver];
        self.playbackObserver = nil;
    }
    
    // 释放资源
    self.videoURL = nil;
    self.urlAsset = nil;
    self.videoLoader = nil;
    [self removePlayItemObserver];
    self.player = nil;
    self.playerItem = nil;
    self.readyToPlay = NO;
    self.totalTime = 0;
    self.isPlay = NO;
}

- (AVPlayerLayer *)createPlayerLayerForCurrenPlayer
{
    if (!self.player) {
        return nil;
    }
    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    layer.videoGravity = AVLayerVideoGravityResizeAspect;
    return layer;
}

- (void)replacePlayerItemWithVideoURL:(NSURL *)videoURL
{
    [self replacePlayerItemWithVideoURL:videoURL downloadWhilePlay:NO];
}

- (void)replacePlayerItemWithVideoURL:(NSURL *)videoURL downloadWhilePlay:(BOOL)download
{
    if (!videoURL) {
        [self pause];
        return;
    }
    [self removePlayItemObserver];
    AVURLAsset *asset = nil;
    if (download) {
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:videoURL resolvingAgainstBaseURL:NO];
        components.scheme = @"klp";
        NSURL *fakeURL = [components URL];
        
        asset = [AVURLAsset URLAssetWithURL:fakeURL options:nil];
        self.videoLoader = [KLVideoLoader loaderWithVideoURL:videoURL];
        [asset.resourceLoader setDelegate:self.videoLoader queue:dispatch_get_main_queue()];
    } else {
        asset = [AVURLAsset assetWithURL:videoURL];
    }
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    [self addPlayItemObserver];
    [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
}

- (void)play
{
    if (!self.readyToPlay) {
        return;
    }
    if (self.player && !self.isPlay) {
        [self.player play];
        self.isPlay = YES;
        [self notifyDelegatePlayStateChanged];
    }
}

- (void)pause
{
    if (!self.readyToPlay) {
        return;
    }
    if (self.player && self.isPlay) {
        [self.player pause];
        self.isPlay = NO;
        [self notifyDelegatePlayStateChanged];
    }
}

- (void)setMuted:(BOOL)muted
{
    if (_muted == muted) {
        return;
    }
    _muted = muted;
    self.player.muted = muted;
    [self notifyDelegateMuteStateChanged];
}

- (void)seekToTime:(Float64)seconds completion:(void (^)(BOOL))handler
{
    CMTime time = CMTimeMakeWithSeconds(seconds, 1);
    __weak typeof(self) weakSelf = self;
    [self.playerItem seekToTime:time completionHandler:^(BOOL finished) {
        if (finished) {
            [weakSelf play];
        }
        if (handler) {
            handler(finished);
        }
    }];
}

- (void)replayCurrentItemWithCompletion:(void(^)(BOOL finished))block
{
    __weak typeof(self) weakSelf = self;
    [self seekToTime:0 completion:^(BOOL finished) {
        if (finished) {
            [weakSelf play];
        }
        if (block) {
            block(finished);
        }
    }];
}

#pragma mark - Private
- (void)enumerateAllDelegates:(void (^) (id<KLVideoPlayerDelegate>delegate))block
{
    NSArray <id<KLVideoPlayerDelegate>> *allDelegates = [self.hashTable allObjects];
    for (id<KLVideoPlayerDelegate>delegate in allDelegates) {
        block(delegate);
    }
}

- (void)playToTime:(CMTime)time
{
    if (!self.readyToPlay) {
        return;
    }
    Float64 seconds = CMTimeGetSeconds(time);
    self.hasPlayed = YES;
    self.currentPlayTime = seconds;
    [self enumerateAllDelegates:^(id<KLVideoPlayerDelegate> delegate) {
        if ([delegate respondsToSelector:@selector(kl_videoPlayToTime:)]) {
            [delegate kl_videoPlayToTime:seconds];
        }
    }];
}

- (void)addPlayItemObserver
{
    if (!self.playerItem) {
        return;
    }
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
}

- (void)removePlayItemObserver
{
    if (self.playerItem) {
        @try {
            [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
            [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
            [self.playerItem removeObserver:self forKeyPath:@"status"];
            [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        } @catch (NSException *exception) {
            NSLog(@"videoException-->%@", exception);
        } @finally {
            
        }
    }
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status) {
            case AVPlayerStatusReadyToPlay: {
                self.readyToPlay = YES;//到此状态时，视频画面已经出现。普通视频，只调用一次，若是m3u8直播文件切片，可能调用多次
                CMTime duration = self.playerItem.duration;
                if (!CMTIME_IS_INDEFINITE(duration) && CMTIME_IS_VALID(duration)) {
                    Float64 seconds = CMTimeGetSeconds(duration);
                    self.totalTime = seconds;
                }
                [self notifyDelegateReadyToPlay];
            }
                break;
            case AVPlayerStatusFailed:  {
                NSError *error = self.playerItem.error;
                [self notifyDelegatePlayFailedWithError:error];
            }
                break;
            case AVPlayerStatusUnknown:
                break;
            default:
                break;
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        //        NSArray *loadTimeRanges = self.playerItem.loadedTimeRanges;
        //        //        NSLog(@"loadTimeRanges->%@", loadTimeRanges);
        //        CMTimeRange timeRange = [[loadTimeRanges firstObject] CMTimeRangeValue];
        //        Float64 startSeconds = CMTimeGetSeconds(timeRange.start);
        //        Float64 durationSeconds = CMTimeGetSeconds(timeRange.duration);
        //        Float64 totalTime = startSeconds + durationSeconds;
        
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        if (self.playerItem.playbackBufferEmpty) {
            [self notifyDelegateBufferEmpty];
        }
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        if (self.playerItem.playbackLikelyToKeepUp) {
            [self notifyDelegateKeepUp];
        }
    }
}

- (void)videoPlayFinish:(NSNotification *)noti
{
    AVPlayerItem *item = noti.object;
    if ([item isEqual:self.playerItem]) {
        [self pause];
        [self notifyDelegatePlayFinished];
    }
}

- (void)enterBackground:(NSNotification *)noti
{
    self.playWhenInBackground = self.isPlay;
    [self pause];
}

- (void)enterForeground:(NSNotification *)noti
{
    if (self.playWhenInBackground) {
        [self play];
    }
}

- (void)audioRouteChangeCallback:(NSNotification *)noti
{
    NSDictionary *userInfo = noti.userInfo;
    AVAudioSessionRouteChangeReason reason = [userInfo[AVAudioSessionRouteChangeReasonKey] integerValue];
    __weak typeof(self) weakSelf = self;
    switch (reason) {
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable: {
            dispatch_async(dispatch_get_main_queue(), ^{
                AVAudioSessionRouteDescription *description = userInfo[AVAudioSessionRouteChangePreviousRouteKey];
                NSArray<AVAudioSessionPortDescription *> *outputs = description.outputs;
                for (AVAudioSessionPortDescription *portDescription in outputs) {
                    if ([portDescription.portType isEqualToString:AVAudioSessionPortHeadphones]) {
                        [weakSelf pause];
                        [weakSelf notifyDelegateHeadphonesUnavailable];
                    }
                }
            });
        }
            break;
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
        default:
            break;
    }
}

- (void)audioInterruption:(NSNotification *)noti
{
    NSDictionary *userInfo = noti.userInfo;
    AVAudioSessionInterruptionType type = [userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    if (type == AVAudioSessionInterruptionTypeBegan) {
        [self pause];
        [self notifyDelegateVideoHasBeenInterrupted];
    } else if (type == AVAudioSessionInterruptionTypeEnded) {
        AVAudioSessionInterruptionOptions options = [userInfo[AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
        if (options == AVAudioSessionInterruptionOptionShouldResume) {
            //可以激活
            [self notifyDelegateVideoInterruptionCanResume];
        }
    }
}

#pragma mark - Notify Delegate
- (void)notifyDelegateReadyToPlay
{
    [self enumerateAllDelegates:^(id<KLVideoPlayerDelegate> delegate) {
        if ([delegate respondsToSelector:@selector(kl_videoPlayerHasReadyToPlay)]) {
            [delegate kl_videoPlayerHasReadyToPlay];
        }
    }];
}

- (void)notifyDelegatePlayFailedWithError:(NSError *)error
{
    [self enumerateAllDelegates:^(id<KLVideoPlayerDelegate> delegate) {
        if ([delegate respondsToSelector:@selector(kl_videoPlayerHasPlayFailed:)]) {
            [delegate kl_videoPlayerHasPlayFailed:error];
        }
    }];
}

- (void)notifyDelegateBufferEmpty
{
    [self enumerateAllDelegates:^(id<KLVideoPlayerDelegate> delegate) {
        if ([delegate respondsToSelector:@selector(kl_videoPlayerBufferEmpty)]) {
            [delegate kl_videoPlayerBufferEmpty];
        }
    }];
}

- (void)notifyDelegateKeepUp
{
    [self enumerateAllDelegates:^(id<KLVideoPlayerDelegate> delegate) {
        if ([delegate respondsToSelector:@selector(kl_videoPlayerLikelyKeepUp)]) {
            [delegate kl_videoPlayerLikelyKeepUp];
        }
    }];
}

- (void)notifyDelegatePlayFinished
{
    [self enumerateAllDelegates:^(id<KLVideoPlayerDelegate> delegate) {
        if ([delegate respondsToSelector:@selector(kl_videoPlayerHasPlayFinished)]) {
            [delegate kl_videoPlayerHasPlayFinished];
        }
    }];
}

- (void)notifyDelegatePlayStateChanged
{
    [self enumerateAllDelegates:^(id<KLVideoPlayerDelegate> delegate) {
        if ([delegate respondsToSelector:@selector(kl_videoPlayerPlayStateHasChanged)]) {
            [delegate kl_videoPlayerPlayStateHasChanged];
        }
    }];
}

- (void)notifyDelegateMuteStateChanged
{
    [self enumerateAllDelegates:^(id<KLVideoPlayerDelegate> delegate) {
        if ([delegate respondsToSelector:@selector(kl_videoPlayerMutedStateHasChanged)]) {
            [delegate kl_videoPlayerMutedStateHasChanged];
        }
    }];
}

- (void)notifyDelegateHeadphonesUnavailable
{
    [self enumerateAllDelegates:^(id<KLVideoPlayerDelegate> delegate) {
        if ([delegate respondsToSelector:@selector(kl_headphonesUnavailable)]) {
            [delegate kl_headphonesUnavailable];
        }
    }];
}

- (void)notifyDelegateVideoHasBeenInterrupted
{
    [self enumerateAllDelegates:^(id<KLVideoPlayerDelegate> delegate) {
        if ([delegate respondsToSelector:@selector(kl_videoHasBeenInterrupted)]) {
            [delegate kl_videoHasBeenInterrupted];
        }
    }];
}

- (void)notifyDelegateVideoInterruptionCanResume
{
    [self enumerateAllDelegates:^(id<KLVideoPlayerDelegate> delegate) {
        if ([delegate respondsToSelector:@selector(kl_videoInterruptionCanResume)]) {
            [delegate kl_videoInterruptionCanResume];
        }
    }];
}

@end
