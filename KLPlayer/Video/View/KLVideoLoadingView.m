//
//  KLVideoLoadingView.m
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import "KLVideoLoadingView.h"
#import "KLPlayerMacros.h"

@implementation KLVideoLoadingView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = RGBAColor(0, 0, 0, 0.5);
        _indicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        _indicator.center = self.center;
        [_indicator startAnimating];
        [self addSubview:_indicator];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.indicator.center = self.center;
}

- (void)setHidden:(BOOL)hidden
{
    if (hidden) {
        [self.indicator stopAnimating];
    } else {
        [self.indicator startAnimating];
    }
    [super setHidden:hidden];
}

@end
