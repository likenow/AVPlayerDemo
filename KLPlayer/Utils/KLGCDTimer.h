//
//  KLGCDTimer.h
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KLGCDTimer : NSObject
//以下为GCD定时器接口
@property (nonatomic, readonly, getter=isValid) BOOL valid;
@property (nonatomic, copy, readonly) NSString *name;

+ (instancetype)timerOnMainQueue;
+ (instancetype)timerOnMainQueueWithName:(NSString *)name;

+ (instancetype)timerOnMainQueueWithLeeway:(uint64_t)leeaay name:(NSString *)name;
+ (instancetype)timerOnQueue:(dispatch_queue_t)queue leeway:(uint64_t)leeway name:(NSString *)name;

- (instancetype)initWithQueue:(dispatch_queue_t)queue leeway:(uint64_t)leeway name:(NSString *)name;

//先使用+方法或减号初始化方法得到实例对象之后，调用以下方法获取回调
- (void)scheduleBlock:(void(^)(void))block afterTimeInterval:(NSTimeInterval)interval;
- (void)scheduleBlock:(void(^)(void))block afterTimeInterval:(NSTimeInterval)interval repeat:(BOOL)repeat;

- (void)invalidate;

@end

@interface KLGCDTimer (Convenience)

+ (instancetype)scheduleGCDTimerAfterTimeInterval:(NSTimeInterval)interval block:(void (^)(void))block;
+ (instancetype)scheduleGCDTimerAfterTimeInterval:(NSTimeInterval)interval repeat:(BOOL)repeat block:(void (^)(void))block;
@end

NS_ASSUME_NONNULL_END
