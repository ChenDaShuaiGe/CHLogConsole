//
//  CHLogModel.h
//  CHLogView
//
//  Created by cc on 2020/6/9.
//  Copyright © 2020 chen. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHLogModel : NSObject

@property (nonatomic, copy) NSString *content;
/// text color
/// default black
@property (nonatomic, strong) UIColor *color;

@property (nonatomic, assign) CGFloat rowHeight;

@property (nonatomic, assign) BOOL isFolded;

+ (instancetype)logWith:(NSString *)content color:(UIColor *)color;


/// 设置label文案计算时的最大宽度
/// @param maxWidth maxWidth description
+ (void)setLabelMaxWidth:(CGFloat)maxWidth;

@end

NS_ASSUME_NONNULL_END
