//
//  KLVideoLoader.m
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import "KLVideoLoader.h"
#import "KLVideoDownload.h"
#import <CoreServices/CoreServices.h>

typedef NS_ENUM (NSInteger, KLVideoDownloadStatus) {
    KLVideoDownloadStatusDownload,
    KLVideoDownloadStatusSuccess,
    KLVideoDownloadStatusError,
} ;

@interface KLVideoLoader () <KLVideoDownloadDelegate>

@property (nonatomic, strong) NSURL *videoURL;

@property (nonatomic, copy) void (^progressBlock) (CGFloat);
@property (nonatomic, copy) void (^successBlock) (NSString *);
@property (nonatomic, copy) void (^failedBlock) (NSError *);

@property (nonatomic, strong) KLVideoDownload *downloader;
@property (nonatomic, strong) NSMutableArray *loadingRequests;

@property (nonatomic, assign) KLVideoDownloadStatus downloadStatus;
@property (nonatomic, assign) CGFloat progress;

@property (nonatomic, strong) NSError *downloadError;

@end

@implementation KLVideoLoader

- (void)dealloc
{
    [self.downloader cancel];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.loadingRequests = [NSMutableArray array];
        self.downloadStatus = KLVideoDownloadStatusDownload;
    }
    return self;
}

+ (instancetype)loaderWithVideoURL:(NSURL *)videoURL
{
    KLVideoLoader *loader = [[KLVideoLoader alloc] init];
    loader.videoURL = videoURL;
    return loader;
}

- (void)setProgress:(void (^)(CGFloat))progressBlock success:(void (^)(NSString * _Nonnull))successBlock failed:(void (^)(NSError * _Nonnull))failedBlock
{
    self.progressBlock = progressBlock;
    self.successBlock = successBlock;
    self.failedBlock = failedBlock;
}

#pragma mark - Private
- (void)startDownload
{
    if (!self.downloader) {
        self.downloader = [[KLVideoDownload alloc] initWithDownloadURL:self.videoURL];
        self.downloader.delegate = self;
        [self.downloader startDownload];
    }
}

- (void)checkWhetherCanFinishLoadingRequests
{
    NSMutableArray *finishedRequest = [NSMutableArray array];
    for (AVAssetResourceLoadingRequest *loadingRequest in self.loadingRequests) {
        if ([self configLoadingRequestAndFinish:loadingRequest]) {
            [finishedRequest addObject:loadingRequest];
        }
    }
    [self.loadingRequests removeObjectsInArray:finishedRequest];
}

- (void)finishAllRequestWithError:(NSError *)error
{
    for (AVAssetResourceLoadingRequest *loadingRequest in self.loadingRequests) {
        [loadingRequest finishLoadingWithError:error];
    }
    [self.loadingRequests removeAllObjects];
}

- (BOOL)configLoadingRequestAndFinish:(AVAssetResourceLoadingRequest *)loadingRequest
{
    AVAssetResourceLoadingContentInformationRequest *contentRequest = loadingRequest.contentInformationRequest;
    if (contentRequest) {
        NSString *mimeType = [self.downloader MIMEType];
        if (!mimeType) {
            mimeType = @"video/mp4";
        }
        CFStringRef contentTypeRef = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef _Nonnull)(mimeType), NULL);
        NSString *contentType = (__bridge_transfer NSString *)contentTypeRef;
        if (@available(iOS 11.2, *)) {
            if (contentRequest.allowedContentTypes) {
                if ([contentRequest.allowedContentTypes containsObject:contentType]) {
                    contentRequest.contentType = contentType;
                }
            } else {
                contentRequest.contentType = contentType;
            }
        } else {
            contentRequest.contentType = contentType;
        }
        contentRequest.byteRangeAccessSupported = YES;
        contentRequest.contentLength = self.downloader.totalLength;
    }
    long long requestOffset = loadingRequest.dataRequest.requestedOffset;
    if (loadingRequest.dataRequest.currentOffset > 0) {
        requestOffset = loadingRequest.dataRequest.currentOffset;
    }
    long long canReadLength = 0;
    if (self.downloader.cachedLength > requestOffset) {
        canReadLength = self.downloader.cachedLength - requestOffset;
    }
    long long needWriteLength = loadingRequest.dataRequest.requestedLength + loadingRequest.dataRequest.requestedOffset - loadingRequest.dataRequest.currentOffset;
    NSFileHandle *readHandle = self.downloader.readFileHandle;
    if (!readHandle) {
        NSLog(@"This code should not be called, read handle is nil");
        return NO;
    }
    [readHandle seekToFileOffset:requestOffset];
    
    if (canReadLength >= needWriteLength) {
        NSUInteger respondLength = 0;
        while (respondLength < needWriteLength) {
            @autoreleasepool {
                NSUInteger maxReadLengthPerTime = 500 * 1024;
                NSUInteger currentReadLength = MIN(needWriteLength-respondLength, maxReadLengthPerTime);
                [readHandle seekToFileOffset:requestOffset+respondLength];
                NSData *data = [readHandle readDataOfLength:currentReadLength];
                [loadingRequest.dataRequest respondWithData:data];
                respondLength += currentReadLength;
            }
        }
        [loadingRequest finishLoading];
    } else {
        NSUInteger respondLength = 0;
        while (respondLength < canReadLength) {
           @autoreleasepool {
               NSUInteger maxReadLengthPerTime = 500 * 1024;
               NSUInteger currentReadLength = MIN(canReadLength-respondLength, maxReadLengthPerTime);
               [readHandle seekToFileOffset:requestOffset+respondLength];
               NSData *data = [readHandle readDataOfLength:currentReadLength];
               [loadingRequest.dataRequest respondWithData:data];
               respondLength += currentReadLength;
           }
        }
        if (self.downloadStatus == KLVideoDownloadStatusError) {
            [loadingRequest finishLoadingWithError:self.downloadError];
        }
    }
    return loadingRequest.finished;
}

#pragma mark - AVAssetResourceLoaderDelegate
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    /*
     1、可边下边播的前提是，视频文件的moov(container for all the metadata)需要在最前面，后面跟随mdat(media data container)
     2、如果moov在最后，则需要整个文件下载完成才可以播放，此时超时时间大约18s
     */
    [self.loadingRequests addObject:loadingRequest];
    if (self.downloader) {
        if (self.downloader.cachedLength > 0) {
            [self checkWhetherCanFinishLoadingRequests];
        }
    } else {
        [self startDownload];
    }
    return YES;
}

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForRenewalOfRequestedResource:(AVAssetResourceRenewalRequest *)renewalRequest
{
    //这个代理不应该被调用，如发生调用，需要关注issue。
    NSLog(@"This delegate should not be called: %s", __FUNCTION__);
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    if ([self.loadingRequests containsObject:loadingRequest]) {
        [self.loadingRequests removeObject:loadingRequest];
    }
}

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForResponseToAuthenticationChallenge:(NSURLAuthenticationChallenge *)authenticationChallenge
{
    //This method should not be called
    if ([authenticationChallenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
       if ([authenticationChallenge.sender respondsToSelector:@selector(performDefaultHandlingForAuthenticationChallenge:)]) {
           [authenticationChallenge.sender performDefaultHandlingForAuthenticationChallenge:authenticationChallenge];
       } else {
           NSURLCredential *credential = [NSURLCredential credentialForTrust:authenticationChallenge.protectionSpace.serverTrust];
           [[authenticationChallenge sender] useCredential:credential forAuthenticationChallenge:authenticationChallenge];
       }
    } else {
       if ([authenticationChallenge previousFailureCount] <= 0) {
           [[authenticationChallenge sender] continueWithoutCredentialForAuthenticationChallenge:authenticationChallenge];
       } else {
           [[authenticationChallenge sender] continueWithoutCredentialForAuthenticationChallenge:authenticationChallenge];
       }
    }
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)authenticationChallenge {}

#pragma mark - KLVideoDownloadDelegate
- (void)downloader:(KLVideoDownload *)downloader didUpdateProgress:(NSNumber *)progress
{
    self.progress = progress.floatValue;
    [self checkWhetherCanFinishLoadingRequests];
    if (self.progressBlock) {
        self.progressBlock(progress.floatValue);
    }
}

- (void)downloader:(KLVideoDownload *)downloader didFinishWithError:(nullable NSError *)error filePath:(nullable NSString *)filePath
{
    if (error) {
        self.downloadError = error;
        self.downloadStatus = KLVideoDownloadStatusError;
        [self finishAllRequestWithError:error];
        if (self.failedBlock) {
            self.failedBlock(error);
        }
    } else {
        self.downloadStatus = KLVideoDownloadStatusSuccess;
        [self checkWhetherCanFinishLoadingRequests];
        if (self.successBlock) {
            self.successBlock(filePath);
        }
    }
}

@end
