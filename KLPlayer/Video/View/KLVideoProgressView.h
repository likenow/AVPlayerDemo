//
//  KLVideoProgressView.h
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KLVideoProgressView : UIView

@property (nonatomic, strong) UIColor *trackColor; //轨道的背景色
@property (nonatomic, strong) UIColor *progressColor; //进度条的颜色
@property (nonatomic, assign) CGFloat progress; //当前进度，默认为0

@end

NS_ASSUME_NONNULL_END
