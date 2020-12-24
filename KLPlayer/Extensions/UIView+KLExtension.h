//
//  UIView+KLExtension.h
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (KLExtension)

@property (nonatomic, assign) CGFloat kl_x;
@property (nonatomic, assign) CGFloat kl_y;
@property (nonatomic, assign) CGFloat kl_w;
@property (nonatomic, assign) CGFloat kl_h;

@property (nonatomic, assign) CGPoint kl_position;
@property (nonatomic, assign) CGSize kl_size;

- (CGFloat)kl_maxX;
- (CGFloat)kl_maxY;
- (CGFloat)kl_minX;
- (CGFloat)kl_minY;

- (void)kl_setTapActionWithBlock:(void (^_Nullable)(void))block;
@end

NS_ASSUME_NONNULL_END
