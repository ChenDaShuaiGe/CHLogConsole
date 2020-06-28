//
//  CHLogView.h
//  CHLogView
//
//  Created by cc on 2020/6/9.
//  Copyright © 2020 chen. All rights reserved.
//

#import "CHLogModel.h"
#import "CHLogConfig.h"

//最大log数
#define kMaxLogNum 200
//达到最大后删除数
#define kDelLogPer kMaxLogNum/5

#define chlog_async_main(...) if ([NSThread isMainThread]) {\
    __VA_ARGS__\
}else{\
    dispatch_async(dispatch_get_main_queue(), ^{\
        __VA_ARGS__\
    });\
}

typedef NS_ENUM(NSUInteger, CHLogViewStatus) {
    CHLogViewStatus_hide,       //隐藏不显示
    CHLogViewStatus_show_full,  //全屏显示
    CHLogViewStatus_show_circle,//悬浮显示
};


NS_ASSUME_NONNULL_BEGIN

@interface CHLogView : UIView

@property (nonatomic, assign, readonly) CHLogViewStatus status;

- (void)showInWindow;
- (void)close;
- (void)addData:(NSArray<CHLogModel *> *)data;

@end

NS_ASSUME_NONNULL_END
