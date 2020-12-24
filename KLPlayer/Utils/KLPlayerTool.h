//
//  KLPlayerTool.h
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KLPlayerTool : NSObject

+ (UIImage *)imageWithName:(NSString *)imageName;
+ (NSString *)filePathInBundleForFileName:(NSString *)fileName;

+ (BOOL)isEmptyString:(NSString *)string;

/**
 将参数seconds格式化为小时:分钟:秒的格式,不足1小时，不显示小时
 @param seconds 总秒数
 @return 格式化后的字符串
 */
+ (NSString *)formatTimeWithTotalSeconds:(Float64)seconds;
@end

NS_ASSUME_NONNULL_END
