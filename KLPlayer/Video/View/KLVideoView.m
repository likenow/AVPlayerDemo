//
//  KLVideoView.m
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import "KLVideoView.h"

@implementation KLVideoView

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;
}

- (void)setPlayerLayer:(AVPlayerLayer *)playerLayer
{
    [_playerLayer removeFromSuperlayer];
    if (playerLayer) {
        [self.layer addSublayer:playerLayer];
        [self setNeedsLayout];
    }
    _playerLayer = playerLayer;
}

@end
