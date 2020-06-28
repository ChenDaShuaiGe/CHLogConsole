//
//  CHLogConfig.h
//  GoodBusiness
//
//  Created by cc on 2020/6/23.
//  Copyright © 2020 YeahKa. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CHLogType) {
    CHLogType_default,
    CHLogType_all,      //展示所有打印输出
    CHLogType_input,    //只展示addLog     需自己埋点
    CHLogType_max,
};

@interface CHLogConfig : NSObject

+ (instancetype)defaultConfig;

- (instancetype)init __unused;


/// default CHLogType_all 会拦截输出
@property (nonatomic, assign) CHLogType type;

/// 最大缓存log条数
@property (nonatomic, assign) NSInteger maxLog;
/// log存满时删除数
@property (nonatomic, assign) NSInteger delLog;

/// 缩小后圆圈半径 default 30
@property (nonatomic, assign) CGFloat radius;

@property (nonatomic, strong) UIColor *circleColor;

@end

NS_ASSUME_NONNULL_END
