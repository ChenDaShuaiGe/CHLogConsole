//
//  CHLogConsole.h
//  CHLogView
//
//  Created by cc on 2020/6/11.
//  Copyright © 2020 chen. All rights reserved.
//

#import <UIKit/UIKit.h>

//#import <Masonry.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHLogConsole : NSObject

+ (void)addLog:(NSString *)log showColor:(UIColor *)color;

+ (void)show;
+ (void)close;

@end

NS_ASSUME_NONNULL_END
