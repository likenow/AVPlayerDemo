//
//  KLSandBox.h
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KLSandBox : NSObject

+ (NSString *)homePath;
+ (NSString *)documentPath;
+ (NSString *)libraryPath;
+ (NSString *)tempPath;
+ (NSString *)cachePath;

/// 在folderPath创建一个文件夹
/// @param folderPath 文件夹路径
+ (BOOL)createFolderAtPath:(NSString *)folderPath;

/// 对指定路径的文件设置自定义的文件属性
/// @param filePath 文件路径
/// @param key 键值名称
/// @param value 值
/// @return 设置成功返回YES，否则返回NO
+ (BOOL)setCustomAttributeForFileAtPath:(NSString *)filePath key:(NSString *)key value:(NSString *)value;

/// 获取自定义的文件属性
/// @param filePath 文件路径
/// @param key 键值名称
/// @return 如果指定的key名不存在，返回nil，否则返回其值
+ (nullable NSString *)customAttributeForItemAtPath:(NSString *)filePath key:(NSString *)key;
@end

NS_ASSUME_NONNULL_END
