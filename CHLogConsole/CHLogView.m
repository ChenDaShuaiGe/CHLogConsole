//
//  CHLogView.m
//  CHLogView
//
//  Created by cc on 2020/6/9.
//  Copyright © 2020 chen. All rights reserved.
//

#import "CHLogView.h"
#import "CHLogUtil.h"
#import "CHLogConsole.h"

//上下按钮大小
#define kLogBtnHeight 40
//动画时间  s
#define kAnimationDuration 0.25
//滚动时间间隔 s
#define kScrollTimeInterval 1

#define kWeakSelf __weak typeof(self) weakSelf = self;
#define kAnimationKey_opacity @"opacity"

typedef NS_ENUM(NSInteger, CHLogBtnTag) {
    CHLogBtnTag_default,
    CHLogBtnTag_type,   //日志类型  全日志/输入日志
    CHLogBtnTag_close,  //关闭
    CHLogBtnTag_minimize, //最小化
    CHLogBtnTag_scroll, //滚屏
    CHLogBtnTag_share,  //分享
    
    CHLogBtnTag_expand, //扩大
};

#pragma mark -------圆圈Button
//log 小圈
@interface CHLogCircleBtn : UIButton
@end
@implementation CHLogCircleBtn
+ (instancetype)buttonWithType:(UIButtonType)buttonType{
    CHLogCircleBtn *b = [super buttonWithType:buttonType];
    b.backgroundColor = UIColor.whiteColor;
    
    return b;
}
- (void)drawRect:(CGRect)rect{
    CGFloat radius = self.frame.size.width/2;
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, radius*2, 2*radius) cornerRadius:radius];
    path.lineWidth = 6;
    path.lineCapStyle = kCGLineCapRound;
    path.lineJoinStyle = kCGLineJoinRound;

    [[CHLogConfig defaultConfig].circleColor set];
    [path stroke];
}
@end

#pragma mark -------Cell
@interface CHLogCell : UITableViewCell

@property (nonatomic, strong) UILabel *logLabel;

- (void)setLog:(id)log color:(UIColor *)color;

@end

@implementation CHLogCell

- (void)setLog:(id)log color:(UIColor *)color{
    self.logLabel.text = [NSString stringWithFormat:@"%@",log];
    self.logLabel.textColor = color;
}

- (UILabel *)logLabel{
    if (!_logLabel) {
        _logLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:_logLabel];
        _logLabel.numberOfLines = 0;
        _logLabel.font = [UIFont systemFontOfSize:15];
        [_logLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.bottom.equalTo(self.contentView);
            make.left.equalTo(self.contentView).offset(15);
            make.right.equalTo(self.contentView).offset(-15);
            make.height.greaterThanOrEqualTo(@40);
        }];
    }
    return _logLabel;
}

@end

#pragma mark -----------------------------------------
#pragma mark -------Log view

@interface CHLogView()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) CHLogCircleBtn *circleBtn;

@property (nonatomic, strong) NSMutableArray *dataSource;

@property (nonatomic, assign) CHLogViewStatus status;

@property (nonatomic, strong) UIImage *icon;

//动画状态记录
@property (nonatomic, assign)  CGRect fullBounds;
@property (nonatomic, assign)  CGRect circleBounds;

@property (nonatomic, assign)  CGPoint fullPosition;
@property (nonatomic, assign)  CGPoint circlePosition;

@property (nonatomic, assign)  CGFloat fullRadius;
@property (nonatomic, assign)  CGFloat circleRadius;

@end

@implementation CHLogView{
    
    BOOL _autoScroll;//是否滚屏
}
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initUI];
    }
    return self;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initUI];
    }
    return self;
}

- (void)initUI{
    self.autoresizesSubviews = YES;
    self.status = CHLogViewStatus_hide;
    self.clipsToBounds = YES;
    self.frame = [UIScreen mainScreen].bounds;
    
    CGFloat radius = [CHLogConfig defaultConfig].radius;
    _fullBounds = self.bounds;
    _circleBounds = CGRectMake(0, 0,radius *2 , radius *2);
    
    _fullPosition = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    _circlePosition = CGPointMake(radius, _fullPosition.y);
    
    _fullRadius = .0;
    _circleRadius = radius;
    
    self.dataSource = [NSMutableArray arrayWithCapacity:0];
    self.tableView.tableFooterView = nil;
    
    [self addAroundButtons];
    
    //TEST
    self.bgView.backgroundColor = [UIColor whiteColor];
    self.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.6];
    
}
#pragma mark - buttons
- (void)addAroundButtons{
    [self addButtons:@[@"全日志",@"关闭",@"最小化"] tags:@[@(CHLogBtnTag_type),@(CHLogBtnTag_close),@(CHLogBtnTag_minimize)] isTop:YES];
    [self addButtons:@[@"滚屏",@"分享"] tags:@[@(CHLogBtnTag_scroll),@(CHLogBtnTag_share)] isTop:NO];
}
- (void)addButtons:(NSArray<NSString *> *)titles tags:(NSArray<NSNumber *> *)tags isTop:(BOOL)isTop{
    NSAssert(titles.count == tags.count, @"titles count not equal to tags");
    UIView *superView = isTop?self.topView:self.bottomView;
    UIView *leftView = nil;
    for (NSInteger i = 0; i<titles.count; i++) {
        UIButton *btn = [self createBtn:titles[i] tag:tags[i].integerValue];
        [superView addSubview:btn];
        [btn mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(superView);
            if (leftView) {
                make.left.equalTo(leftView.mas_right);
                make.width.equalTo(leftView);
            }else{
                make.left.equalTo(superView);
            }
            if (i == titles.count -1) {
                make.right.equalTo(superView);
            }
        }];
        leftView = btn;
        
    }
}
- (UIButton *)createBtn:(NSString *)title tag:(NSInteger)tag{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    if (tag == CHLogBtnTag_type) {
        [btn setTitle:@"部分日志" forState:UIControlStateSelected];
        btn.selected = [CHLogConfig defaultConfig].type == CHLogType_input;
    }
    btn.contentMode = UIViewContentModeCenter;
    btn.tag = tag;
    [btn addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}
#pragma mark - actions
- (void)buttonAction:(UIButton *)sender{
    switch (sender.tag) {
        case CHLogBtnTag_type:
        {
            [CHLogConfig defaultConfig].type = sender.selected ?CHLogType_all:CHLogType_input;
            [CHLogConsole show];
            sender.selected = !sender.selected;
            [self.tableView reloadData];
            break;
        }
        case CHLogBtnTag_close:
            [self animateToStatus:CHLogViewStatus_hide];
            break;
        case CHLogBtnTag_minimize:
            [self animateToStatus:CHLogViewStatus_show_circle];
            break;
        case CHLogBtnTag_scroll:
        {
            _autoScroll = !_autoScroll;
            if (_autoScroll) {
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.dataSource.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }
        }
            break;
        case CHLogBtnTag_share:
        {
            [self animateToStatus:CHLogViewStatus_show_circle];
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSString *temp = NSTemporaryDirectory();
                NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%ld.txt",temp,(long)[[NSDate date] timeIntervalSince1970]]];
                NSMutableString *mut = [NSMutableString string];
                for (int i = 0; i<self.dataSource.count; i++) {
                    [mut appendString:[(CHLogModel *)[self.dataSource objectAtIndex:i] content]];
                    if (i < self.dataSource.count-1) {
                        [mut appendFormat:@"\n"];
                    }
                }
                NSError *error = nil;
                [mut writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:&error];
                if (error) {
                    NSLog(@"文件write fail error : %@",error);
                    return;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [CHLogUtil shareFromVC:nil fromView:self contents:@[url] success:^{
                        NSLog(@"分享成功");
                    } failure:^{
                        NSLog(@"分享失败");
                    }];
                });
            });
            break;
        }
        default:
            break;
    }
}
- (void)circleBtnAction{
    [self animateToStatus:CHLogViewStatus_show_full];
}
- (void)panAction:(UIPanGestureRecognizer *)pan{
    static CGPoint originCenter;
    if (pan.state == UIGestureRecognizerStateBegan) {
        originCenter = self.center;
    }else if (pan.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [pan translationInView:self.superview];
        self.center = CGPointMake(originCenter.x + translation.x, originCenter.y + translation.y);
    }else if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        CGFloat height = [UIScreen mainScreen].bounds.size.height;
        
        CGPoint target = self.center;
        int flag = 0;
        CGFloat minX = 0;
        CGFloat minY = 0;
        if (fabs(width-self.center.x) > fabs(self.center.x)) {
            flag = 1;
            minX = self.center.x;
        }else{
            flag = 2;
            minX = width-self.center.x;
        }
        if (fabs(height-self.center.y) > fabs(self.center.y)) {
            flag += 10;
            minY = self.center.y;
        }else{
            flag += 20;
            minY = height-self.center.y;
        }
        if (fabs(minX) < fabs(minY)) {
            target.x = flag%10==1 ? kLogBtnHeight:(width-kLogBtnHeight);
            target.y = MIN(MAX(target.y, kLogBtnHeight), height-kLogBtnHeight);
        }else{
            target.y = flag/10==1 ? kLogBtnHeight:(height-kLogBtnHeight);
            target.x = MIN(MAX(target.x, kLogBtnHeight), width-kLogBtnHeight);
        }
        CABasicAnimation *animat = [CABasicAnimation animationWithKeyPath:@"position"];
        animat.fromValue = @(self.center);
        animat.toValue = @(target);
        self.center = target;
        _circlePosition = self.center;
        [self.layer addAnimation:animat forKey:@"position"];
    }
}
#pragma mark - tableview delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataSource.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    CHLogModel *model = self.dataSource[indexPath.row];
    return model.rowHeight;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"CHLogCell";
    CHLogCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[CHLogCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    CHLogModel *model = self.dataSource[indexPath.row];
    [cell setLog:model.content color:model.color];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([CHLogConfig defaultConfig].type != CHLogType_input) {
        return;
    }
    CHLogModel *model = self.dataSource[indexPath.row];
    model.isFolded = !model.isFolded;
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}
#pragma mark - observe
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"rootViewController"] && [object isKindOfClass:UIWindow.class]) {
        [self bringToFront];
    }
}
#pragma mark - lazy load
- (UIImage *)icon{
    if (!_icon) {
//        NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[CHLogView class]] pathForResource:@"CHLogConsole" ofType:@"bundle"]];
        NSBundle *bundle = [NSBundle mainBundle];
        //颜色由btn控制
        _icon = [[UIImage imageWithContentsOfFile:[bundle pathForResource:@"ch_log_black@2x" ofType:@"png"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return _icon;
}
- (UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        [self addSubview:_bgView];
        [_bgView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
            make.width.height.equalTo(self).multipliedBy(0.8);
        }];
        //设置cell label计算文案时的最大宽度
        [CHLogModel setLabelMaxWidth:[UIScreen mainScreen].bounds.size.width *0.8 - 15*2];
    }
    return _bgView;
}
- (CHLogCircleBtn *)circleBtn{
    if (!_circleBtn) {
        _circleBtn = [CHLogCircleBtn buttonWithType:UIButtonTypeCustom];
        _circleBtn.frame = CGRectMake(0, 0, 2*kLogBtnHeight, 2*kLogBtnHeight);
        [self addSubview:_circleBtn];
        [_circleBtn addTarget:self action:@selector(circleBtnAction) forControlEvents:UIControlEventTouchUpInside];
        UIPanGestureRecognizer *gesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
        [_circleBtn addGestureRecognizer:gesture];
        [_circleBtn mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.bottom.equalTo(self);
        }];
        _circleBtn.tintColor = [UIColor blackColor];
    }
    return _circleBtn;
}
- (UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 100, 100) style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [self.bgView addSubview:_tableView];
        [_tableView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.bgView);
            make.top.equalTo(self.topView.mas_bottom);
            make.bottom.equalTo(self.bottomView.mas_top);
        }];
    }
    return _tableView;
}
- (UIView *)topView{
    if (!_topView) {
        _topView = [[UIView alloc] initWithFrame:CGRectZero];
        [self.bgView addSubview:_topView];
        [_topView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.top.right.equalTo(self.bgView);
            make.height.equalTo(@(kLogBtnHeight)).priorityLow();
        }];
    }
    return _topView;
}
- (UIView *)bottomView{
    if (!_bottomView) {
        _bottomView = [[UIView alloc]initWithFrame:CGRectZero];
        [self.bgView addSubview:_bottomView];
        [_bottomView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(self.bgView);
            make.height.equalTo(@(kLogBtnHeight)).priorityLow();
        }];
    }
    return _bottomView;
}
#pragma mark - private
- (void)bringToFront{
    if (self.superview) {
        [self.superview bringSubviewToFront:self];
    }
}
- (void)hide{
    kWeakSelf
    self.layer.opacity = 1;
    [UIView animateWithDuration:kAnimationDuration animations:^{
        weakSelf.layer.opacity = 0.2;
    } completion:^(BOOL finished) {
        [weakSelf removeFromSuperview];
        weakSelf.layer.opacity = 0.5;
        weakSelf.userInteractionEnabled = YES;
    }];
    
}
- (void)show:(CHLogViewStatus)status{
    if (self.superview) {
        return;
    }
    NSArray<UIWindow *> *arr = [UIApplication sharedApplication].windows;
    UIWindow *window = nil;
    for (UIWindow *temp in arr) {
        if (temp.windowLevel == UIWindowLevelNormal && temp.rootViewController) {
            window = temp;
            break;
        }
    }
    if (!window) {
        self.status =  CHLogViewStatus_hide;
        return;
    }
    [window addSubview:self];
    //window 可能是创建的alert window
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        [window addObserver:self forKeyPath:@"rootViewController" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    });
    
    kWeakSelf
    if(status == CHLogViewStatus_show_circle){
        self.bounds = weakSelf.circleBounds;
        self.layer.position = weakSelf.circlePosition;
        self.layer.cornerRadius = weakSelf.circleRadius;
        self.circleBtn.hidden = NO;
        
        [self.circleBtn setImage:self.icon forState:UIControlStateNormal];
    }
    self.layer.opacity = 0.5;
    [UIView animateWithDuration:kAnimationDuration animations:^{
        weakSelf.layer.opacity = 1;
    } completion:^(BOOL finished) {
        weakSelf.userInteractionEnabled = YES;
        weakSelf.layer.opacity = 1;
    }];
    
}
- (void)shrink{
    if (self.superview) {
        
        kWeakSelf
        [UIView animateWithDuration:kAnimationDuration delay:0 options:UIViewAnimationOptionLayoutSubviews animations:^{
            
            weakSelf.bounds = weakSelf.circleBounds;
            weakSelf.layer.position = weakSelf.circlePosition;
            weakSelf.layer.cornerRadius = weakSelf.circleRadius;
            
        } completion:^(BOOL finished) {
            weakSelf.userInteractionEnabled = YES;
            weakSelf.circleBtn.hidden = NO;
            [weakSelf.circleBtn setImage:self.icon forState:UIControlStateNormal];
        }];
    }
}

- (void)expand{
    if (self.superview) {
        kWeakSelf
        [self.circleBtn setImage:nil forState:UIControlStateNormal];
        [UIView animateWithDuration:kAnimationDuration delay:0 options:UIViewAnimationOptionLayoutSubviews animations:^{
            
            weakSelf.circleBtn.hidden = YES;
            weakSelf.bounds = weakSelf.fullBounds;
            weakSelf.layer.position = weakSelf.fullPosition;
            weakSelf.layer.cornerRadius = weakSelf.fullRadius;
            
        } completion:^(BOOL finished) {
            weakSelf.userInteractionEnabled = YES;
            weakSelf.circleBtn.hidden = YES;
        }];
    }
}
- (void)animateToStatus:(CHLogViewStatus)status{
    if (self.status == status) {
        return;
    }
    
    _autoScroll = NO;
    self.userInteractionEnabled = NO;
    switch (status) {
        case CHLogViewStatus_hide:
            [self hide];
            break;
        case CHLogViewStatus_show_full:
        {
            if (self.status == CHLogViewStatus_hide) {
                [self show:status];
            }else{
                [self expand];
            }
        }
            break;
        case CHLogViewStatus_show_circle:
        {
            if (self.status == CHLogViewStatus_hide) {
                [self show:status];
            }else{
                [self shrink];
            }
        }
            break;
        default:
            break;
    }
    self.status = status;
}

#pragma mark - public
- (void)showInWindow{
    if (!self.superview) {
        [self animateToStatus:CHLogViewStatus_show_circle];
    }
}
- (void)close{
    [self hide];
}
- (void)addData:(NSArray<CHLogModel *> *)data{
    static NSTimeInterval lastScroll = 0;
    if (self.dataSource.count > [CHLogConfig defaultConfig].maxLog) {
        [self.dataSource removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [CHLogConfig defaultConfig].delLog)]];
    }
    [self.dataSource addObjectsFromArray:data];
    [self.tableView reloadData];
    
    if (_autoScroll) {
        NSTimeInterval curr = [[NSDate date]timeIntervalSince1970];
        if ( curr - lastScroll > kScrollTimeInterval) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.dataSource.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            lastScroll = curr;
        }
    }
}

@end
