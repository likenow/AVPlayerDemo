//
//  KLVideoProgressView.m
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import "KLVideoProgressView.h"
#import "UIView+KLExtension.h"


@interface KLVideoProgressView ()

@property (nonatomic, strong) UIView *trackView;
@property (nonatomic, strong) UIView *progressView;

@end


@implementation KLVideoProgressView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _trackView = [[UIView alloc] initWithFrame:CGRectMake(0, (self.kl_h-3)/2.0, self.kl_w, 3)];
        _trackView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _trackView.backgroundColor = [UIColor whiteColor];
        _trackView.layer.cornerRadius = CGRectGetHeight(_trackView.frame)/2.0;
        [self addSubview:_trackView];
        
        _progressView = [[UIView alloc] initWithFrame:CGRectMake(0, _trackView.kl_minY, 0, 3)];
        _progressView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        _progressView.backgroundColor = [UIColor redColor];
        _progressView.layer.cornerRadius = CGRectGetHeight(_progressView.frame)/2.0;
        [self addSubview:_progressView];
    }
    return self;
}

- (void)setTrackColor:(UIColor *)trackColor
{
    _trackColor = trackColor;
    self.trackView.backgroundColor = trackColor;
}

- (void)setProgressColor:(UIColor *)progressColor
{
    _progressColor = progressColor;
    self.progressView.backgroundColor = progressColor;
}

- (void)setProgress:(CGFloat)progress
{
    if (progress < 0) {
        progress = 0;
    }
    if (progress > 1) {
        progress = 1;
    }
    _progress = progress;
    self.progressView.frame = CGRectMake(0, self.trackView.kl_minY, self.frame.size.width * _progress, 3);
}

@end
