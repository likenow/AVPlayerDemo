//
//  NSString+KLExtension.m
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import "NSString+KLExtension.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation NSString (KLExtension)

- (CGFloat)kl_widthWithFont:(UIFont *)font
{
    NSStringDrawingOptions opts = NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading;
    CGRect rect = [self boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, font.pointSize) options:opts attributes:@{NSFontAttributeName:font} context:nil];
    return ceil(CGRectGetWidth(rect));
}


- (NSString *)kl_md5String
{
    const char *cStr = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    return [self kl_hexStringForCString:result digestLength:CC_MD5_DIGEST_LENGTH];
}
- (NSString *)kl_hexStringForCString:(unsigned char *)cStr digestLength:(NSInteger)length
{
    NSMutableString *hashStr = [NSMutableString stringWithCapacity:length*2];
    for (int i = 0; i < length; i++) {
        [hashStr appendFormat:@"%02x", cStr[i]];
    }
    return [[hashStr copy] lowercaseString];
}
@end
