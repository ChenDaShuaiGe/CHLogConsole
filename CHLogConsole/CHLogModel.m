//
//  CHLogModel.m
//  CHLogView
//
//  Created by cc on 2020/6/9.
//  Copyright © 2020 chen. All rights reserved.
//

#import "CHLogModel.h"
#import "CHLogConfig.h"

@implementation CHLogModel

static CGFloat ch_maxWidth;

+ (instancetype)logWith:(NSString *)content color:(UIColor *)color{
    CHLogModel *model = [CHLogModel new];
    model.content = content;
    if (color) {
        model.color = color;
    }
    return model;
}

+ (void)setLabelMaxWidth:(CGFloat)maxWidth{
    ch_maxWidth = maxWidth;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.color = UIColor.blackColor;
        self.rowHeight = 0;
        self.isFolded = true;
    }
    return self;
}

- (void)setColor:(UIColor *)color{
    if (color) {
        _color = color;
    }
}

- (CGFloat)rowHeight{
    if (self.content) {
        if (_rowHeight <= 0) {
            CGSize size = CGSizeMake(ch_maxWidth, 0);
            NSDictionary *attribute = @{NSFontAttributeName:[UIFont systemFontOfSize:15]};
            CGRect frame = [self.content boundingRectWithSize:size options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attribute context:nil];
            _rowHeight = frame.size.height+2;
        }
        
        if (self.isFolded && _rowHeight > 100 && [CHLogConfig defaultConfig].type == CHLogType_input) {
            return 60;
        }
        
        return _rowHeight;
    }else{
        return 40;
    }
}

@end
