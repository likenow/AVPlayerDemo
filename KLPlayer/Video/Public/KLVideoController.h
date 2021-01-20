//
//  KLVideoController.h
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "KLVideoPlayer.h"
#import "KLVideoPlayerView.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSNotificationName kKLVideoPlayStateDidChangeNotification;

@interface KLVideoController : NSObject
/// 是否循环播放，默认会循环播放
@property (nonatomic, assign) BOOL isLooping;
@property (nonatomic, assign) BOOL isAutoDispose;

@property (nonatomic, strong, readonly) KLVideoPlayer *videoPlayer;
@property (nonatomic, strong, readonly) KLVideoPlayerView *playerView;

- (void)setVideoPlayTimeBlock:(void (^)(Float64 playTime))block;
- (void)setVideoHasReadBlock:(void (^)(void))block;
- (void)setVideoHasPlayFailedBlock:(void(^)(NSError *error))block;

- (void)setVideoPlayStateBlock:(void (^) (BOOL play))block;
- (void)setVideoHasPlayFinishedBlock:(void (^) (void))block;

- (void)setVideoFirstFrameHasLoadCompletionBlock:(void (^) (BOOL success, UIImage *image, NSError *error, NSURL *imageURL))block;

- (instancetype)initWithVideoURL:(NSURL *)videoURL viewFrame:(CGRect)frame;
- (instancetype)initWithVideoURL:(NSURL *)videoURL videoFirstFrameImageURL:(nullable NSString *)firstFrameImage viewFrame:(CGRect)frame;
/// 边下边播
- (instancetype)initWithVideoURL:(NSURL *)videoURL videoFirstFrameImageURL:(nullable NSString *)firstFrameImage viewFrame:(CGRect)frame downloadWhilePlay:(BOOL)download;

@end

NS_ASSUME_NONNULL_END
