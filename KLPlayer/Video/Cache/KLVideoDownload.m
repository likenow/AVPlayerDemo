//
//  KLVideoDownload.m
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import "KLVideoDownload.h"
#import "NSString+KLExtension.h"
#import "KLVideoCache.h"
#import "KLPlayerTool.h"
#import "KLSandBox.h"

NSString *kKLVideoMIMETypeKey = @"kKLVideoMIMETypeKey";

@interface KLVideoDownload () <NSURLSessionDelegate>

@property (nonatomic, assign) long long requestOffset;
@property (nonatomic, assign) long long cachedLength;

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionTask *sessionTask;
@property (nonatomic, strong) NSFileHandle *fileHandle;

@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;

@property (nonatomic, copy) NSString *MIMEType;

@property (nonatomic, assign) long long totalLength;

@property (nonatomic, copy) NSString *tempFilePath;
@property (nonatomic, copy) NSString *realFilePath;

@property (nonatomic, strong) NSFileHandle *readFileHandle;

@end

@implementation KLVideoDownload

- (void)dealloc
{
    [self releaseReadHandle];
}

- (void)releaseReadHandle
{
    if (self.readFileHandle) {
        if (@available(iOS 13.0, *)) {
            NSError *error = nil;
            BOOL success = [self.readFileHandle closeAndReturnError:&error];
            if (!success) {
                NSLog(@"close read file handle failed, error->%@", error);
            }
        } else {
            [self.readFileHandle closeFile];
        }
        self.readFileHandle = nil;
    }
}

- (void)releaseWriteHandle
{
    if (self.fileHandle) {
        if (@available(iOS 13.0, *)) {
            NSError *error = nil;
            BOOL closed = [self.fileHandle closeAndReturnError:&error];
            if (!closed) {
                NSLog(@"The file %@ could not be closed. ERROR->%@", self.tempFilePath, error);
            }
        } else {
            [self.fileHandle closeFile];
        }
        self.fileHandle = nil;
    }
}

- (instancetype)initWithDownloadURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        self.cachedLength = 0;
        self.downloadURL = url;
    }
    return self;
}

- (void)cancel
{
    [self releaseWriteHandle];
    if (self.session) {
        [self.sessionTask cancel];
        self.sessionTask = nil;
        
        [self.session invalidateAndCancel];
        self.session = nil;
    }
}

- (void)setCachePaths
{
    [KLSandBox createFolderAtPath:[[KLVideoCache sharedVideoCache] tempVideoPath]];
    NSString *fileName = [self.downloadURL.absoluteString kl_md5String];
    self.tempFilePath = [NSString stringWithFormat:@"%@/%@", [[KLVideoCache sharedVideoCache] tempVideoPath], fileName];
    self.realFilePath = [NSString stringWithFormat:@"%@/%@", [[KLVideoCache sharedVideoCache] baseVideoPath], fileName];
}

- (NSString *)tempFilePath
{
    return _tempFilePath;
}

- (NSString *)finialFilePath
{
    return self.realFilePath;
}

- (void)setDownloadURL:(NSURL * _Nonnull)downloadURL
{
    _downloadURL = downloadURL;
    
    [self setCachePaths];
}

- (void)startDownload
{
    if (!self.downloadURL) {
        return;
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.realFilePath]) {
        NSError *error = nil;
        
        BOOL success = [[NSFileManager defaultManager] setAttributes:@{NSFileModificationDate : [NSDate date]} ofItemAtPath:self.realFilePath error:&error];
        if (!success) {
            NSLog(@"set modification date failed for file at path %@, error->%@", self.realFilePath, error);
        }
        NSDictionary *attrDic = [[NSFileManager defaultManager] attributesOfItemAtPath:self.realFilePath error:nil];
        self.cachedLength = [attrDic[NSFileSize] longLongValue];
        self.totalLength = self.cachedLength;
        self.readFileHandle = [NSFileHandle fileHandleForReadingAtPath:self.realFilePath];
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloader:didUpdateProgress:)]) {
            [self.delegate downloader:self didUpdateProgress:[NSNumber numberWithFloat:1.0]];
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloader:didFinishWithError:filePath:)]) {
            [self.delegate downloader:self didFinishWithError:nil filePath:self.realFilePath];
        }
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.downloadURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60];
    if (!self.fileHandle) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.tempFilePath]) {
            [[NSFileManager defaultManager] createFileAtPath:self.tempFilePath contents:[NSData data] attributes:nil];
        }
        self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.tempFilePath];
        self.cachedLength = [self.fileHandle seekToEndOfFile];
        [request addValue:[NSString stringWithFormat:@"bytes=%lld-", self.cachedLength] forHTTPHeaderField:@"Range"];
//        [request addValue:[NSString stringWithFormat:@"bytes=%d-%d", 0, 0] forHTTPHeaderField:@"Range"];
    }
    if (!self.readFileHandle) {
        self.readFileHandle = [NSFileHandle fileHandleForReadingAtPath:self.tempFilePath];
    }

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    //notice self.session has a strong reference to the delegate object.
    self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    self.sessionTask = [self.session dataTaskWithRequest:request];
    [self.sessionTask resume];
}

//https://zh.wikipedia.org/wiki/%E4%BA%92%E8%81%94%E7%BD%91%E5%AA%92%E4%BD%93%E7%B1%BB%E5%9E%8B
//对application/octet-stream以及application/ogg不处理
- (NSString *)MIMEType
{
    if (_MIMEType) {
        return _MIMEType;
    }
    _MIMEType = [KLSandBox customAttributeForItemAtPath:self.tempFilePath key:kKLVideoMIMETypeKey];
    if (!_MIMEType) {
        _MIMEType = [KLSandBox customAttributeForItemAtPath:self.realFilePath key:kKLVideoMIMETypeKey];
    }
    return _MIMEType;
}

#pragma mark - NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didReceiveResponse:(nonnull NSURLResponse *)response completionHandler:(nonnull void (^)(NSURLSessionResponseDisposition))completionHandler
{
    if (!self.MIMEType) {
        self.MIMEType = response.MIMEType;
    }
    if (self.MIMEType) {
        if (![[self.MIMEType lowercaseString] hasPrefix:@"video"]) {
            completionHandler(NSURLSessionResponseCancel);
            return;
        } else {
            completionHandler(NSURLSessionResponseAllow);
        }
    } else {
        completionHandler(NSURLSessionResponseCancel);
        return;
    }
    [KLSandBox setCustomAttributeForFileAtPath:self.tempFilePath key:kKLVideoMIMETypeKey value:self.MIMEType];
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (![httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
        completionHandler(NSURLSessionResponseCancel);
        return;
    }
    
    NSString *contentRange = [[httpResponse allHeaderFields] objectForKey:@"Content-Range"];
    NSString *totalLength = [[contentRange componentsSeparatedByString:@"/"] lastObject];//"Content-Range" = "bytes 100-200/6027815";
    if ([KLPlayerTool isEmptyString:totalLength]) {
        if (self.cachedLength > 0) {
            self.totalLength = httpResponse.expectedContentLength + self.cachedLength;
        } else {
            self.totalLength = httpResponse.expectedContentLength;
        }
    } else {
        long long filelength = totalLength.longLongValue;
        if (self.cachedLength > 0) {
            self.totalLength = (filelength > 0) ? filelength : (httpResponse.expectedContentLength + self.cachedLength);
        } else {
            self.totalLength = (filelength > 0) ? filelength : httpResponse.expectedContentLength;
        }
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloaderDidReceiveResponse:)]) {
        [self.delegate downloaderDidReceiveResponse:self];
    }
    if (self.cachedLength > 0) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloader:didUpdateProgress:)]) {
            if (self.totalLength <= 0) {
                return;
            }
            CGFloat progress = self.cachedLength/(self.totalLength * 1.0);
            [self.delegate downloader:self didUpdateProgress:[NSNumber numberWithFloat:progress]];
        }
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    long long fileSize = [self.fileHandle seekToEndOfFile];
    [self.fileHandle writeData:data];
    
    self.cachedLength = fileSize + data.length;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloader:didUpdateProgress:)]) {
        if (self.totalLength <= 0) {
            NSLog(@"KLVideoDownloadError, cacheLen->%@, total->%@", @(self.cachedLength), @(self.totalLength));
        } else {
            CGFloat progress = self.cachedLength / (self.totalLength * 1.0);
            [self.delegate downloader:self didUpdateProgress:[NSNumber numberWithFloat:progress]];
        }
    }
}

#pragma mark - NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error
{
    [self releaseWriteHandle];
    if (error) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloader:didFinishWithError:filePath:)]) {
            [self.delegate downloader:self didFinishWithError:error filePath:nil];
        }
    } else {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = nil;
        BOOL moved = [fileManager moveItemAtPath:self.tempFilePath toPath:self.realFilePath error:&error];
        if (moved) {
            [KLSandBox setCustomAttributeForFileAtPath:self.realFilePath key:kKLVideoMIMETypeKey value:self.MIMEType];
            [self releaseReadHandle];
            self.readFileHandle = [NSFileHandle fileHandleForReadingAtPath:self.realFilePath];
            if (self.delegate && [self.delegate respondsToSelector:@selector(downloader:didFinishWithError:filePath:)]) {
                [self.delegate downloader:self didFinishWithError:nil filePath:self.realFilePath];
            }
        } else {
            NSLog(@"[Error], The file at %@ can not be moved to %@, error->%@", self.tempFilePath, self.realFilePath, error);
            if (self.delegate && [self.delegate respondsToSelector:@selector(downloader:didFinishWithError:filePath:)]) {
                [self.delegate downloader:self didFinishWithError:error filePath:nil];
            }
        }
    }
}

@end
