//
//  KLPlayerTool.m
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import "KLPlayerTool.h"

@implementation KLPlayerTool

+ (UIImage *)imageWithName:(NSString *)imageName
{
    NSString *bundlePath = [KLPlayerTool bundlePath];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    UIImage *image = [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:nil];
    return image?:[[UIImage alloc] init];
}

+ (NSString *)bundlePath
{
    return [[NSBundle mainBundle] pathForResource:@"KLPlayer" ofType:@"bundle"];
}
+ (NSString *)filePathInBundleForFileName:(NSString *)fileName
{
    return [[self bundlePath] stringByAppendingPathComponent:fileName];
}

+ (BOOL)isEmptyString:(NSString *)string
{
    if ([string isKindOfClass:[NSString class]]) {
        return (!string.length || [string isEqualToString:@"(null)"] || [string isEqualToString:@"null"] || [string isEqualToString:@"<null>"]);
    }
    return YES;
}

+ (NSString *)formatTimeWithTotalSeconds:(Float64)seconds
{
    int hour = 0, minute = 0;
    int finalSeconds = seconds;
    hour = finalSeconds/3600;
    minute = (finalSeconds % 3600)/60;
    finalSeconds = finalSeconds % 60;
    if (hour <= 0) {
        return [NSString stringWithFormat:@"%02d:%02d", minute, finalSeconds];
    }
    return [NSString stringWithFormat:@"%02d:%02d:%02d", hour, minute, finalSeconds];
}

@end
