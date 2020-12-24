//
//  KLVideoView.h
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KLVideoView : UIView
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@end

NS_ASSUME_NONNULL_END
