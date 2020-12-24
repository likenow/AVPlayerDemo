//
//  KLVideoDownload.h
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString *kKLVideoRelativeBasePath;

@class KLVideoDownload;
@protocol KLVideoDownloadDelegate <NSObject>
@optional

/// 接收到服务端的响应
- (void)downloaderDidReceiveResponse:(KLVideoDownload *)downloader;

/// 更新下载进度
/// @param downloader 下载者
/// @param progress 下载进度[0-1]
- (void)downloader:(KLVideoDownload *)downloader didUpdateProgress:(NSNumber *)progress;

/// 下载完成
/// @param downloader 下载者
/// @param error 如果下载完成，该值为nil，如果下载错误，指示错误信息。
/// @param filePath 如果下载完成，该值为文件的路径；如果下载失败，该值为nil
- (void)downloader:(KLVideoDownload *)downloader didFinishWithError:(nullable NSError *)error filePath:(nullable NSString *)filePath;

@end

@interface KLVideoDownload : NSObject

- (instancetype)initWithDownloadURL:(NSURL *)url;

@property (nonatomic, weak, nullable) id <KLVideoDownloadDelegate> delegate;

@property (nonatomic, strong, readonly) NSURL *downloadURL;//download url passed through the initialization method

@property (nonatomic, assign, readonly) long long cachedLength;//the cached fize size in bytes
@property (nonatomic, assign, readonly) long long totalLength;//the entire file size in bytes

@property (nonatomic, copy, readonly, nullable) NSString *MIMEType;//when the 'downloadURL' is first downloaded and no respose has been received yet,this property may be nil.

@property (nonatomic, strong, readonly, nullable) NSFileHandle *readFileHandle;//You can use this attribute to read data from downloaded file. this attribute is non-nil after you called `-startDownload` method

/// 临时文件路径
- (NSString *)tempFilePath;
///正式文件路径
- (NSString *)finialFilePath;

/// start download file from the 'downloadURL'
- (void)startDownload;

/// cancel the download task
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
