//
//  KLGCDTimer.m
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import "KLGCDTimer.h"

static const uint64_t TimerLeewayMedium = 100 * 1000 * 1000;
static const uint64_t TimerLeewayHigh = 1000 * 1000 * 1000;

@interface KLGCDTimer () {
    dispatch_source_t _gcdTimer;
    dispatch_semaphore_t _semaphore;
}

@property (nonatomic, assign, getter=isValid) BOOL valid;
@property (nonatomic, assign) uint64_t leeway;
@property (nonatomic, copy) NSString *name;

@end

@implementation KLGCDTimer

- (void)dealloc
{
    [self invalidate];
}

+ (instancetype)timerOnMainQueue
{
    return [self timerOnMainQueueWithName:@""];
}

+ (instancetype)timerOnMainQueueWithName:(NSString *)name
{
    return [self timerOnMainQueueWithLeeway:TimerLeewayMedium name:name];
}

+ (instancetype)timerOnMainQueueWithLeeway:(uint64_t)leeaay name:(NSString *)name
{
    return [self timerOnQueue:dispatch_get_main_queue() leeway:leeaay name:name];
}

+ (instancetype)timerOnQueue:(dispatch_queue_t)queue leeway:(uint64_t)leeway name:(NSString *)name
{
    return [[self alloc] initWithQueue:queue leeway:leeway name:name];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.name = @"";
        self.valid = NO;
        
        _semaphore = dispatch_semaphore_create(1);
    }
    return self;
}

- (instancetype)initWithQueue:(dispatch_queue_t)queue leeway:(uint64_t)leeway name:(NSString *)name
{
    self = [self init];
    if (self) {
        self.name = name ? : @"";
        _gcdTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        self.leeway = leeway;
    }
    return self;
}

- (void)scheduleBlock:(void(^)(void))block afterTimeInterval:(NSTimeInterval)interval
{
    [self scheduleBlock:block afterTimeInterval:interval repeat:NO];
}

- (void)scheduleBlock:(void(^)(void))block afterTimeInterval:(NSTimeInterval)interval repeat:(BOOL)repeat
{
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    if (self.isValid || !_gcdTimer) {
        NSLog(@"Attempt to schedule block while timer is valid or you have called incorrect method to init");
        dispatch_semaphore_signal(_semaphore);
        return;
    }
    dispatch_time_t startTime;
    dispatch_time_t intervalInNanoseconds = (NSEC_PER_SEC * interval);
    if (self.leeway >= TimerLeewayHigh) {
        startTime = dispatch_walltime(NULL, intervalInNanoseconds);
    } else {
        startTime = dispatch_time(DISPATCH_TIME_NOW, intervalInNanoseconds);
    }
    
    dispatch_source_set_timer(_gcdTimer, startTime, intervalInNanoseconds, self.leeway);
    void (^eventHandler)(void) = ^{
        if (!repeat) {
            [self invalidate];
        }
        block();
    };
    dispatch_source_set_event_handler(_gcdTimer, eventHandler);
    dispatch_resume(_gcdTimer);
    //        dispatch_source_set_cancel_handler(_gcdTimer, <#^(void)handler#>)
    self.valid = YES;
    dispatch_semaphore_signal(_semaphore);
}

- (void)invalidate
{
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    if (self.isValid) {
        dispatch_source_cancel(_gcdTimer);
        self.valid = NO;
    }
    dispatch_semaphore_signal(_semaphore);
}

@end

@implementation KLGCDTimer (Convenience)

+ (instancetype)scheduleGCDTimerAfterTimeInterval:(NSTimeInterval)interval block:(void (^)(void))block
{
    return [self scheduleGCDTimerAfterTimeInterval:interval repeat:NO block:block];
}

+ (instancetype)scheduleGCDTimerAfterTimeInterval:(NSTimeInterval)interval repeat:(BOOL)repeat block:(void (^)(void))block
{
    KLGCDTimer *timer = [self timerOnMainQueue];
    [timer scheduleBlock:block afterTimeInterval:interval repeat:repeat];
    return timer;
}

@end
