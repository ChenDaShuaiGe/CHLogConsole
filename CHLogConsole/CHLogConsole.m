//
//  CHLogConsole.m
//  CHLogView
//
//  Created by cc on 2020/6/11.
//  Copyright © 2020 chen. All rights reserved.
//

#import "CHLogConsole.h"
#import "CHLogView.h"
#import "CHLogUtil.h"

@interface CHLogConsole()

@property (nonatomic, strong) NSMutableArray *cacheList;
@property (nonatomic, strong) CHLogView *logView;

@property (nonatomic, assign) BOOL stop;

@property (nonatomic, strong) NSFileHandle *outHandle;
@property (nonatomic, strong) NSFileHandle *errHandle;
@end

@implementation CHLogConsole{
    dispatch_queue_t _queue;
    
    NSThread *_logThread;
    NSMachPort *_machPort;
    CFRunLoopRef _runLoop;
}
#pragma mark - init
- (void)initOnce{
    _machPort = (NSMachPort *)[NSMachPort port];
    _logThread = [[NSThread alloc] initWithTarget:self selector:@selector(threadStart) object:nil];
    [_logThread start];
    _queue = dispatch_queue_create("CHLog serial queue", DISPATCH_QUEUE_SERIAL);
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initOnce];
        self.cacheList = [NSMutableArray arrayWithCapacity:0];
        
        self.logView = [[CHLogView alloc] initWithFrame:CGRectZero];
        
        [self.logView addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    }
    return self;
}
+ (instancetype)defaultConsole{
    static CHLogConsole *console = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        console = [[CHLogConsole alloc] init];
    });
    return console;
}
- (void)setStop:(BOOL)stop{
    @synchronized (self) {
        _stop = stop;
    }
}
#pragma mark - observe
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([object isEqual:self.logView] && [keyPath isEqualToString:@"status"]) {
//        NSLog(@"%@",change);
        CHLogViewStatus oldS = [[change objectForKey:NSKeyValueChangeOldKey] integerValue];
        CHLogViewStatus newS = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        if (oldS != CHLogViewStatus_show_full && newS == CHLogViewStatus_show_full) {
            //从非全屏 -> 全屏展示
            [self threadActionStart];
        }else if(oldS == CHLogViewStatus_show_full && newS != CHLogViewStatus_show_full){
            //全屏展示 -> 关闭|缩小
            self.stop = true;
        }
    }
}
- (void)threadStart{
    [[NSThread currentThread] setName:@"CHLog cycle thread"];
    if (!_runLoop) {
        _runLoop = CFRunLoopGetCurrent();
    }
    [[NSRunLoop currentRunLoop] addPort:_machPort forMode:NSRunLoopCommonModes];
    CFRunLoopRun();
}
- (void)threadActionStart{
    self.stop = false;
    [self performSelector:@selector(cycleAction) onThread:_logThread withObject:nil waitUntilDone:NO];
}
- (void)threadStop{
    [[NSRunLoop currentRunLoop] removePort:_machPort forMode:NSRunLoopCommonModes];
    CFRunLoopStop(_runLoop);
}
- (void)cycleAction{
    if (self.stop) {
        return;
    }
    @autoreleasepool {
        int count = 0;
        while (!self.stop) {
            NSArray *arr = [self readLogs];
            if (arr && arr.count) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.logView addData:arr];
                });
                count = 0;
            }else{
                count++;
            }
            int msec = 100;
            if (count > 5 * 1000/msec) {
                //5s没数据停
                self.stop = true;
            }
            usleep(1000*msec);//100ms
        }
    }
}

#pragma mark - private
- (void)addLogModel:(CHLogModel *)model{
    dispatch_async(_queue, ^{
        if (self.cacheList.count > [CHLogConfig defaultConfig].maxLog) {
            [self.cacheList removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [CHLogConfig defaultConfig].delLog)]];
        }
        model.content = [CHLogUtil replaceUnicode:model.content];
        [self.cacheList addObject:model];
        if (self.stop && self.logView.status == CHLogViewStatus_show_full) {
            [self threadActionStart];
        }
    });
}
- (NSArray *)readLogs{
    __block NSArray *res = nil;
    dispatch_sync(_queue, ^{
        res = [self.cacheList copy];
        [self.cacheList removeAllObjects];
    });
    return res;
}
#pragma mark - public
+ (void)show{
    chlog_async_main({
        CHLogConsole *console = [CHLogConsole defaultConsole];
        if ([CHLogConfig defaultConfig].type == CHLogType_all) [console startReadOutput];
        [console.logView showInWindow];
    })
}
+ (void)close{
    chlog_async_main({
        CHLogConsole *console = [CHLogConsole defaultConsole];
        [console.logView close];
    })
}
+ (void)addLog:(NSString *)log showColor:(UIColor *)color{
    if (log) {
        log = [NSString stringWithFormat:@"%@",log];
        CHLogConsole *console = [self defaultConsole];
        [console addLogModel:[CHLogModel logWith:log color:color]];
    }
}

#pragma mark - STDOUT_FILENO STDERR_FILENO
- (void)redirectNotificationHandle:(NSNotification *)sender{
    NSData *data = [[sender userInfo] objectForKey:NSFileHandleNotificationDataItem];

    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSFileHandle *handle = sender.object;
    if (str && str.length > 0) {
        //NSLog 属于 std error log
        //printf 属于 std out
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSString *sep = @"\n\n";
            if ([str rangeOfString:@"\n\n"].location != NSNotFound) {
                NSArray *arr = [str componentsSeparatedByString:sep];
                for (NSString *temp in arr) {
                    [self addLogModel:[CHLogModel logWith:temp color:UIColor.blackColor]];
                }
            }else{
                [self addLogModel:[CHLogModel logWith:str color:UIColor.blackColor]];
            }
        });
        
    }
    if ([CHLogConfig defaultConfig].type == CHLogType_all) {
        [handle readInBackgroundAndNotify];
    }
}
- (NSFileHandle *)errHandle{
    if (!_errHandle) {
        NSPipe * pipe = [NSPipe pipe] ;
        _errHandle = [pipe fileHandleForReading];
        dup2([[pipe fileHandleForWriting] fileDescriptor], STDERR_FILENO);
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(redirectNotificationHandle:)
                                                     name:NSFileHandleReadCompletionNotification
                                                   object:_errHandle];
    }
    return _errHandle;
}
- (NSFileHandle *)outHandle{
    if (!_outHandle) {
        NSPipe * pipe = [NSPipe pipe] ;
        _outHandle = [pipe fileHandleForReading];
        dup2([[pipe fileHandleForWriting] fileDescriptor], STDOUT_FILENO);
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(redirectNotificationHandle:)
                                                     name:NSFileHandleReadCompletionNotification
                                                   object:_outHandle];
    }
    return _outHandle;
}
- (void)startReadOutput{
    if ([CHLogConfig defaultConfig].type == CHLogType_all) {
        [self.errHandle readInBackgroundAndNotify];
        [self.outHandle readInBackgroundAndNotify];
    }
}

@end
