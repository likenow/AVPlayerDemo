//
//  KLVideoLoader.h
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KLVideoLoader : NSObject <AVAssetResourceLoaderDelegate>

/// 初始化一个loader对象
/// @param videoURL 需要下载的远程地址
+ (instancetype)loaderWithVideoURL:(NSURL *)videoURL;

/// 设置下载进度、成功、失败的回调
/// @param progressBlock 下载进度[0-1]
/// @param successBlock 下载成功，参数为文件路径
/// @param failedBlock 下载失败，参数为错误原因
- (void)setProgress:(void(^)(CGFloat progress))progressBlock success:(void(^)(NSString *filePath))successBlock failed:(void(^)(NSError *error))failedBlock;

@end

NS_ASSUME_NONNULL_END
