//
//  NSString+KLExtension.h
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGBase.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (KLExtension)

- (CGFloat)kl_widthWithFont:(UIFont *)font;

#pragma mark - md5
- (NSString *)kl_md5String;

@end

NS_ASSUME_NONNULL_END
