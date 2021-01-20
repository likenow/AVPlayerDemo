//
//  KLVideoCache.m
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import "KLVideoCache.h"
#import "KLSandBox.h"
#import "NSString+KLExtension.h"
#import "KLPlayerTool.h"
#import "KLPlayerMacros.h"

#define MaxCacheSize 45*1000*1000


NSString *kKLVideoRelativePath = @"KLPlayer/Videos";
NSString *kKLCacheRelativePath = @"KLPlayer";

@interface KLVideoCache () {
    dispatch_queue_t _ioQueue;
}
@property (nonatomic, strong) NSFileManager *fileManager;

@end

@implementation KLVideoCache

KLSynthesizeSingletonForClass(KLVideoCache, sharedVideoCache);

- (instancetype)init
{
    self = [super init];
    if (self) {
        _ioQueue = dispatch_queue_create("com.dnduuhn.io", DISPATCH_QUEUE_SERIAL);
        self.fileManager = [[NSFileManager alloc] init];
    }
    return self;
}

- (NSString *)baseVideoPath
{
    return [[KLSandBox libraryPath] stringByAppendingPathComponent:kKLVideoRelativePath];
}

- (NSString *)basePath
{
    return [[KLSandBox libraryPath] stringByAppendingPathComponent:kKLCacheRelativePath];
}

- (NSString *)baseFolder
{
    return [self basePath];
}

- (NSString *)tempVideoPath
{
    return [[self baseVideoPath] stringByAppendingPathComponent:@"temp"];
}

- (void)removeVideoCacheWithURLString:(NSString *)urlString completion:(void (^)(BOOL))completion
{
    dispatch_async(_ioQueue, ^{
        NSString *filePath = [[self baseVideoPath] stringByAppendingPathComponent:[urlString kl_md5String]];
        BOOL removeNormalFile = YES;
        if ([self.fileManager fileExistsAtPath:filePath]) {
            removeNormalFile = [self.fileManager removeItemAtPath:filePath error:nil];
        }
        BOOL removeTempFile = YES;
        NSString *tempFilePath = [[self tempVideoPath] stringByAppendingPathComponent:[urlString kl_md5String]];
        if ([self.fileManager fileExistsAtPath:tempFilePath]) {
            removeTempFile = [self.fileManager removeItemAtPath:tempFilePath error:nil];
        }
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(removeNormalFile && removeTempFile);
            });
        }
    });
}

- (void)balanceCache
{
    [self balanceCacheWithRemainDays:7 completion:nil]; //默认保留7天的缓存
}

- (void)balanceCacheWithCompletion:(void (^)(void))comletion
{
    [self balanceCacheWithRemainDays:7 completion:comletion];
}

- (void)balanceCacheWithRemainDays:(NSInteger)day
{
    [self balanceCacheWithRemainDays:day completion:nil];
}

- (void)balanceCacheWithRemainDays:(NSInteger)day completion:(void (^)(void))completion
{
    dispatch_async(_ioQueue, ^{
        [self balanceCacheInDir:self.basePath remainDay:day];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), completion);
        }
    });
}

- (void)balanceCacheInDir:(NSString *)dirPath remainDay:(NSInteger)day
{
    if (day <= 0 || day >= 366) {
        day = 7;
    }
    BOOL isDir = NO;
    if (![self.fileManager fileExistsAtPath:dirPath isDirectory:&isDir] || !isDir) {
        return;
    }
    NSError *error = nil;
    NSArray *contents = [self.fileManager contentsOfDirectoryAtPath:dirPath error:&error];
    if (!contents) {
        return;
    }
    NSMutableArray *removedArray = [NSMutableArray array];
    for (NSString *subPath in contents) {
        NSString *fullPath = [dirPath stringByAppendingPathComponent:subPath];
        NSDictionary *attribute = [self.fileManager attributesOfItemAtPath:fullPath error:nil];
        if (!attribute) {
            continue;
        }
        NSString *fileType = attribute[NSFileType];
        if ([fileType isEqualToString:NSFileTypeRegular]) {
            NSDate *date = attribute[NSFileModificationDate];
            if ([[NSDate date] timeIntervalSinceDate:date] >= (day * 24 * 3600)) {
                [removedArray addObject:fullPath];
            }
        } else if ([fileType isEqualToString:NSFileTypeDirectory]) {
            [self balanceCacheInDir:fullPath remainDay:day];
        }
    }
    for (NSString *filePath in removedArray) {
        [self.fileManager removeItemAtPath:filePath error:nil];
    }
}

- (BOOL)videoCacheExistForURLString:(NSString *)urlString
{
    if ([KLPlayerTool isEmptyString:urlString]) {
        return NO;
    }
    NSString *filePath = [[self baseVideoPath] stringByAppendingPathComponent:[urlString kl_md5String]];
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

- (BOOL)removeAllTempVideoFilesWithError:(NSError **)error
{
    return [self removeDirAtPath:self.tempVideoPath error:error createAfterRemove:YES];
}

- (BOOL)removeAllCachesWithError:(NSError * _Nullable __autoreleasing *)error
{
    return [self removeDirAtPath:self.baseFolder error:error createAfterRemove:YES];
}

- (BOOL)removeAllVideoFilesWithError:(NSError * _Nullable __autoreleasing *)error
{
    return [self removeDirAtPath:self.baseVideoPath error:error createAfterRemove:YES];
}

- (BOOL)removeDirAtPath:(NSString *)dirPath error:(NSError **)error createAfterRemove:(BOOL)create
{
    BOOL success = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath]) {
        success = YES; //文件不存在，说明已移除.
    } else {
        success = [[NSFileManager defaultManager] removeItemAtPath:dirPath error:error];
    }
    if (create) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return success;
}
#pragma mark - 缓存清理策略
/// 缓存清理
- (void)lruCacheWithTargetPath:(NSString *)path {
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSArray *pathsArr = [fileMgr subpathsAtPath:path];/*取得文件列表*/
    NSArray *sortedPaths = [pathsArr sortedArrayUsingComparator:^(NSString * firstPath, NSString* secondPath) {
        NSString *firstUrl = [path stringByAppendingPathComponent:firstPath];/*获取前一个文件完整路径*/
        NSString *secondUrl = [path stringByAppendingPathComponent:secondPath];/*获取后一个文件完整路径*/
        NSDictionary *firstFileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:firstUrl error:nil];/*获取前一个文件信息*/
        NSDictionary *secondFileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:secondUrl error:nil];/*获取后一个文件信息*/
        id firstData = [firstFileInfo objectForKey:NSFileCreationDate];/*获取前一个文件创建时间*/
        id secondData = [secondFileInfo objectForKey:NSFileCreationDate];/*获取后一个文件创建时间*/
        return [firstData compare:secondData]; // 升序
//        return [secondData compare:firstData]; // 降序
    }];
    // 这样最后得到的sortedPaths就是我们按创建时间排序后的文件，然后我们就可以根据自己的需求来操作已经排序过的文件了，如删除最先创建的文件等：
    NSEnumerator *e = [sortedPaths objectEnumerator];
    NSString *filename;
    while ((filename = [e nextObject])) {
        NSInteger curCacheSize = [self cacheSizeWithFilePath:path];
        if (curCacheSize < MaxCacheSize) {
            break;
        }
        if ([filename containsString:@".DS"]) continue;
        if ([filename containsString:@"temp"]) continue;
        // 在>MaxCacheSize（45M）的情况下，优先删除最先创建的文件。由于文件夹是升序排列，每次删除都是删最先创建的文件
        [[NSFileManager defaultManager] removeItemAtPath:[path stringByAppendingPathComponent:filename] error:NULL];
    }
}

/// 获取缓存路径的文件大小
- (NSInteger)cacheSizeWithFilePath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
#ifdef DEBUG
    // 如果文件夹不存在或者不是一个文件夹那么就抛出一个异常
    BOOL isDirectory = NO;
    BOOL isExist = [fileManager fileExistsAtPath:path isDirectory:&isDirectory];
    if (!isExist || !isDirectory) {
        NSException *exception = [NSException exceptionWithName:@"fileError" reason:@"please check your filePath!" userInfo:nil];
        [exception raise];
    }
//    NSLog(@"debug");
#else
//    NSLog(@"release");
#endif
    // 获取“path”文件夹下面的所有文件
    NSArray *subpathArray = [fileManager subpathsAtPath:path];
    NSString *filePath = nil;
    NSInteger totleSize = 0;
    for (NSString *subpath in subpathArray) {
        // 拼接每一个文件的全路径
        filePath = [path stringByAppendingPathComponent:subpath];
        // isDirectory，是否是文件夹，默认不是
        BOOL isDirectory = NO;
        // isExist，判断文件是否存在
        BOOL isExist = [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
        if (!isExist || isDirectory || [filePath containsString:@".DS"]) continue;
        NSDictionary *dict = [fileManager attributesOfItemAtPath:filePath error:nil];
        NSInteger size = [dict[@"NSFileSize"] integerValue];
        totleSize += size;
    }
    return totleSize;
}


//以下为测试修改文件修改时间为当前的N天前，然后尝试balanceCache。
//- (void)tempTest
//{
//    [self tempTestForDir:self.basePath];
//}
//
//- (void)tempTestForDir:(NSString *)dirPath
//{
//    BOOL isDir = NO;
//    if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:&isDir] || !isDir) {
//        return;
//    }
//    NSError *error = nil;
//    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:&error];
//    if (!contents) {
//        return;
//    }
//    for (NSString *subPath in contents) {
//        NSString *fullPath = [dirPath stringByAppendingPathComponent:subPath];
//        NSDictionary *attribute = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:nil];
//        if (!attribute) {
//            continue;
//        }
//        NSString *fileType = attribute[NSFileType];
//        if ([fileType isEqualToString:NSFileTypeRegular]) {
//            NSDate *date = [NSDate dateWithTimeInterval:(-5 * 24 * 3600) sinceDate:[NSDate date]];
//            [[NSFileManager defaultManager] setAttributes:@{NSFileModificationDate : date} ofItemAtPath:fullPath error:nil];
//        } else if ([fileType isEqualToString:NSFileTypeDirectory]) {
//            [self tempTestForDir:fullPath];
//        }
//    }
//}

@end
