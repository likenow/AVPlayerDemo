//
//  KLSandBox.m
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import "KLSandBox.h"

static NSString *kKLFileExtendedAttributesKey = @"NSFileExtendedAttributes";

@implementation KLSandBox

+ (NSString *)homePath
{
    return NSHomeDirectory();
}

+ (NSString *)libraryPath
{
    NSArray *array = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    return [array firstObject];
}

+ (NSString *)documentPath
{
    NSArray *array = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [array firstObject];
}

+ (NSString *)tempPath
{
    return NSTemporaryDirectory();
}

+ (NSString *)cachePath
{
    NSArray *array = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [array firstObject];
}

+ (BOOL)createFolderAtPath:(NSString *)path
{
    BOOL isDir;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
        NSError *error = nil;
        BOOL isCreate = [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:@{} error:&error];
        if (isCreate) {
            [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:path]];
        }
        return isCreate;
    }
    
    return isDir;
}
+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)fileURL
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]]) {
        return NO;
    }
    NSError *error = nil;
    BOOL success = [fileURL setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:&error];
#if DEBUG
    if (!success) {
        NSLog(@"Exclude %@ from backup error:%@", fileURL, error);
    }
#endif
    return success;
}

+ (BOOL)setCustomAttributeForFileAtPath:(NSString *)filePath key:(NSString *)key value:(NSString *)value
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return NO;
    }
    
    NSError *error = nil;
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    // 以下写法，并不会每次都覆盖kKLFileExtendedAttributesKey对应的值，如果key不同，为增加，如果相同，仅覆盖key的值。
    BOOL success = [[NSFileManager defaultManager] setAttributes:@{
        kKLFileExtendedAttributesKey : @{
                key : data
        }
    } ofItemAtPath:filePath error:&error];
    if (!success) {
        NSLog(@"set attributes failed, Error->%@, file->%@", error, filePath);
    }
    return success;
}

+ (NSString *)customAttributeForItemAtPath:(NSString *)filePath key:(NSString *)key
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return nil;
    }
    
    NSError *error = nil;
    NSDictionary *attribtues = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
    if (!attribtues) {
        NSLog(@"read file attributes failed, error->%@", error);
        return nil;
    }
    NSDictionary *extendedAttributes = attribtues[kKLFileExtendedAttributesKey];
    if (!extendedAttributes) {
        return nil;
    }
    NSData *data = extendedAttributes[key];
    if (!data || ![data isKindOfClass:[NSData class]]) {
        return nil;
    }
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return string;
}
@end
