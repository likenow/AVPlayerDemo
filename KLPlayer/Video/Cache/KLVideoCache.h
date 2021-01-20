//
//  KLVideoCache.h
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KLVideoCache : NSObject

+ (instancetype)sharedVideoCache;

/// 缓存的基础路径
- (NSString *)baseFolder;

/// 视频缓存的基础路径
- (NSString *)baseVideoPath;

/// 视频临时文件存放路径
- (NSString *)tempVideoPath;

/// 移除超过7天的缓存(以修改时间为准)
- (void)balanceCache;

/// 移除超过7天的缓存(以修改时间为准)
/// @param comletion 当移除完成后在主线程回调该block
- (void)balanceCacheWithCompletion:(void(^)(void))comletion;

/// 移除修改时间超过day天的缓存
/// @param day 需要保留的天数(0<day<=365)
- (void)balanceCacheWithRemainDays:(NSInteger)day;

/// 移除修改时间超过day天的缓存
/// @param day 需要保留的天数(0<day<=365)
/// @param completion 当移除完成后在主线程回调该block
- (void)balanceCacheWithRemainDays:(NSInteger)day completion:(void(^ _Nullable)(void))completion;

/// 检测某个url对应的缓存，是否存在
/// @param urlString 远程下载地址
- (BOOL)videoCacheExistForURLString:(NSString *)urlString;

/// 移除某个url对应的缓存
/// @param urlString 远程下载地址
/// @param completion 完成的回调，移除成功为YES。该block在主线程回调
- (void)removeVideoCacheWithURLString:(NSString *)urlString completion:(void (^) (BOOL success))completion;

/// 移除所有的临时视频文件
/// @param error 如果移除过程发生错误，通过该参数返回错误信息
- (BOOL)removeAllTempVideoFilesWithError:(NSError * _Nullable*)error;

/// 移除所有的视频文件
/// @param error 如果移除过程发生错误，通过该参数返回错误信息
- (BOOL)removeAllVideoFilesWithError:(NSError * _Nullable*)error;

/// 移除所有的缓存文件
/// @param error 如果移除过程发生错误，通过该参数返回错误信息
- (BOOL)removeAllCachesWithError:(NSError * _Nullable*)error;

/// 获取路径下缓存文件大小
- (NSInteger)cacheSizeWithFilePath:(NSString *)path;

/// 清理路径的文件
- (void)lruCacheWithTargetPath:(NSString *)path;



@end

NS_ASSUME_NONNULL_END
