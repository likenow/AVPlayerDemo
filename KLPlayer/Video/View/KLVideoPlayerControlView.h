//
//  KLVideoPlayerControlView.h
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import <UIKit/UIKit.h>
#import "KLVideoProgressBar.h"
#import "KLVideoPlayerProtocols.h"

NS_ASSUME_NONNULL_BEGIN

@interface KLVideoPlayerControlView : UIView

@property (nonatomic, assign) BOOL muted;
@property (nonatomic, weak) id <KLVideoControlDelegate> delegate;

@property (nonatomic, assign) BOOL play;
@property (nonatomic, assign) BOOL fullScreen;

@property (nonatomic, assign) CGFloat externalBottomMargin;
@property (nonatomic, assign) BOOL needFullScreen;

@property (nonatomic, assign) BOOL showProgressBar;
@property (nonatomic, strong) KLVideoProgressBar *progressBar;

@end

NS_ASSUME_NONNULL_END
