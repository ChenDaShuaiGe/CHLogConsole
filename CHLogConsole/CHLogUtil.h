//
//  CHLogUtil.h
//  CHLogView
//
//  Created by cc on 2020/6/11.
//  Copyright © 2020 chen. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHLogUtil : NSObject

//share
+ (void)shareFromVC:(nullable UIViewController *)fromVC
           fromView:(UIView *)fromView // for iPad
           contents:(NSArray *)contents
            success:(void(^)(void))success
            failure:(void(^)(void))failure;

//screenshot
+ (UIImage *)screenShot:(UIView *)view;

//中文处理
+ (NSString *)replaceUnicode:(NSString *)unicodeStr;

@end

NS_ASSUME_NONNULL_END
