//
//  UIView+KLExtension.m
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import "UIView+KLExtension.h"
#import <objc/runtime.h>

static char kKLTapGestureHandlerKey;
static char kKLTapActionHandlerBlockKey;

@implementation UIView (KLExtension)

- (CGFloat)kl_x
{
    return CGRectGetMinX(self.frame);
}

- (void)setKl_x:(CGFloat)x
{
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (CGFloat)kl_y
{
    return CGRectGetMinY(self.frame);
}

- (void)setKl_y:(CGFloat)y
{
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (CGFloat)kl_w
{
    return CGRectGetWidth(self.frame);
}

- (void)setKl_w:(CGFloat)w
{
    CGRect frame = self.frame;
    frame.size.width = w;
    self.frame = frame;
}

- (CGFloat)kl_h
{
    return CGRectGetHeight(self.frame);
}

- (void)setKl_h:(CGFloat)h
{
    CGRect frame = self.frame;
    frame.size.height = h;
    self.frame = frame;
}

- (CGSize)kl_size
{
    return self.frame.size;
}

- (void)setKl_size:(CGSize)size
{
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

- (CGPoint)kl_position
{
    return self.frame.origin;
}

- (void)setKl_position:(CGPoint)position
{
    CGRect frame = self.frame;
    frame.origin = position;
    self.frame = frame;
}

- (CGFloat)kl_maxX
{
    return CGRectGetMaxX(self.frame);
}

- (CGFloat)kl_maxY
{
    return CGRectGetMaxY(self.frame);
}

- (CGFloat)kl_minX
{
    return CGRectGetMinX(self.frame);
}

- (CGFloat)kl_minY
{
    return CGRectGetMinY(self.frame);
}


- (void)kl_setTapActionWithBlock:(void (^)(void))block
{
    self.userInteractionEnabled = YES;
    UITapGestureRecognizer *gesture = objc_getAssociatedObject(self, &kKLTapGestureHandlerKey);
    
    if (!gesture) {
        gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(kl_handleActionForTapGesture:)];
        [self addGestureRecognizer:gesture];
        objc_setAssociatedObject(self, &kKLTapGestureHandlerKey, gesture, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    objc_setAssociatedObject(self, &kKLTapActionHandlerBlockKey, block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)kl_handleActionForTapGesture:(UITapGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded) {
        void(^tapAction)(void) = objc_getAssociatedObject(self, &kKLTapActionHandlerBlockKey);
        if (tapAction) {
            tapAction();
        }
    }
}

@end
