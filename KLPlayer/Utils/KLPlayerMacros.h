//
//  KLPlayerMacros.h
//  KLPlayer
//
//  Created by kaili on 2020/12/24.
//

#ifndef KLPlayerMacros_h
#define KLPlayerMacros_h

#define RGBAColor(r, g, b, a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]

/// 单例
#define KLSynthesizeSingletonForClass(className,methodName) \
static className *shared##className = nil; \
+ (className *)methodName \
{ \
    static dispatch_once_t onceToken; \
    dispatch_once(&onceToken, ^{ \
        shared##className = [[self alloc] init]; \
    }); \
    return shared##className; \
} \
+ (id)allocWithZone:(NSZone *)zone \
{ \
    static dispatch_once_t onceToken; \
    dispatch_once(&onceToken, ^{ \
        shared##className = [super allocWithZone:zone]; \
    }); \
    return shared##className; \
} \
- (id)copyWithZone:(NSZone *)zone \
{ \
    return self; \
} \
- (id)mutableCopyWithZone:(struct _NSZone *)zone \
{ \
    return self; \
}

#endif /* KLPlayerMacros_h */
