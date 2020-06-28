//
//  CHLogConfig.m
//  GoodBusiness
//
//  Created by cc on 2020/6/23.
//  Copyright © 2020 YeahKa. All rights reserved.
//

#import "CHLogConfig.h"

@implementation CHLogConfig

+ (instancetype)defaultConfig{
    static dispatch_once_t onceToken;
    static CHLogConfig *config;
    dispatch_once(&onceToken, ^{
        config = [CHLogConfig new];
    });
    return config;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.type = CHLogType_all;
        self.maxLog = 200;
        self.delLog = 40;
        self.radius = 30;
        self.circleColor = [UIColor.redColor colorWithAlphaComponent:0.9];
    }
    return self;
}

@end
