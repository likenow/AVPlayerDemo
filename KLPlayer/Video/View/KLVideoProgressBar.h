//
//  KLVideoProgressBar.h
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KLVideoProgressBar : UIView

- (void)setRightLabelText:(NSString *)text;
- (void)setLeftLabelText:(NSString *)text;
- (void)setProgress:(CGFloat)progress;

@end

NS_ASSUME_NONNULL_END
