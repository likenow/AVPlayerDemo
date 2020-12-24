//
//  KLVideoProgressBar.m
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import "KLVideoProgressBar.h"
#import "KLVideoProgressView.h"
#import "NSString+KLExtension.h"
#import "UIView+KLExtension.h"
#import "KLPlayerMacros.h"

@interface KLVideoProgressBar ()

@property (nonatomic, strong) UILabel *leftLabel;
@property (nonatomic, strong) UILabel *rightLabel;
@property (nonatomic, strong) KLVideoProgressView *progressView;

@end

@implementation KLVideoProgressBar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIFont *font = [UIFont systemFontOfSize:11];
        NSString *initText = @"00:00";
        CGFloat width = [initText kl_widthWithFont:font];
        _leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, self.kl_h)];
        _leftLabel.font = font;
        _leftLabel.textAlignment = NSTextAlignmentLeft;
        _leftLabel.text = initText;
        _leftLabel.textColor = RGBAColor(255, 255, 255, 1.0);
        [self addSubview:_leftLabel];
        
        _rightLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.kl_w-width, 0, width, self.kl_h)];
        _rightLabel.font = font;
        _rightLabel.textColor = RGBAColor(255, 255, 255, 1.0);
        _rightLabel.textAlignment = NSTextAlignmentRight;
        _rightLabel.text = initText;
        [self addSubview:_rightLabel];
        
        CGFloat progressX = _leftLabel.kl_maxX+5;
        _progressView = [[KLVideoProgressView alloc] initWithFrame:CGRectMake(progressX, 0, self.kl_w-progressX * 2, self.kl_h)];
        _progressView.trackColor = RGBAColor(153, 153, 153, 1.0);
        _progressView.progressColor = RGBAColor(230, 230, 230, 1.0);
        [self addSubview:_progressView];
    }
    return self;
}

- (void)setLeftLabelText:(NSString *)text
{
    self.leftLabel.text = text;
}

- (void)setRightLabelText:(NSString *)text
{
    self.rightLabel.text = text;
}

- (void)setProgress:(CGFloat)progress
{
    self.progressView.progress = progress;
}

@end
