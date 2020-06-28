//
//  CHLogUtil.m
//  CHLogView
//
//  Created by cc on 2020/6/11.
//  Copyright © 2020 chen. All rights reserved.
//

#import "CHLogUtil.h"
#import <sys/sysctl.h>

@implementation CHLogUtil

+ (UIViewController *)getCurrentRootViewController{
    return [UIApplication sharedApplication].keyWindow.rootViewController;
}

+ (NSString *)platform {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    free(machine);
    return platform;
}

+ (BOOL)isIPad{
    NSString *platform = [self platform];
    if ([platform.uppercaseString rangeOfString:@"IPAD"].location != NSNotFound) {
        return YES;
    }
    return NO;
}

+ (void)shareFromVC:(UIViewController *)fromVC
           fromView:(UIView *)fromView // for iPad
           contents:(NSArray *)contents
            success:(void(^)(void))success
            failure:(void(^)(void))failure{
    
    if (!fromVC) {
        fromVC = [self getCurrentRootViewController];
    }
    
    // 服务类型控制器
    UIActivityViewController *activityViewController =
    [[UIActivityViewController alloc] initWithActivityItems:contents applicationActivities:nil];
    activityViewController.modalInPopover = true;
    [fromVC presentViewController:activityViewController animated:YES completion:nil];
    //不出现在活动项目
    activityViewController.excludedActivityTypes = @[UIActivityTypePrint,UIActivityTypeAssignToContact,UIActivityTypeSaveToCameraRoll,UIActivityTypeAddToReadingList,UIActivityTypePostToFlickr,UIActivityTypePostToVimeo,UIActivityTypeOpenInIBooks,UIActivityTypeSaveToCameraRoll];

    if([self isIPad]){
        UIPopoverPresentationController *popover = activityViewController.popoverPresentationController;
        popover.sourceView = fromView;
        popover.sourceRect = fromView.bounds;
        popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }

    // 选中分享类型
    [activityViewController setCompletionWithItemsHandler:^(NSString * __nullable activityType, BOOL completed, NSArray * __nullable returnedItems, NSError * __nullable activityError){

        // 显示选中的分享类型
        NSLog(@"share type %@",activityType);

        if (completed) {
            if (success) {
                success();
            }
        }else {
            if (failure) {
                failure();
            }
        }
    }];
}

+ (UIImage *)screenShot:(UIView *)view{
    // 开启图片上下文
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0);
    // 获取当前上下文
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    // 截图:实际是把layer上面的东西绘制到上下文中
    [view.layer renderInContext:ctx];
    //iOS7+ 推荐使用的方法，代替上述方法
    // [self.view drawViewHierarchyInRect:self.view.frame afterScreenUpdates:YES];
    // 获取截图
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    // 关闭图片上下文
    UIGraphicsEndImageContext();
    return image;
}

+ (NSString *)replaceUnicode:(NSString *)unicodeStr{
    if ([unicodeStr.lowercaseString rangeOfString:@"\\u"].location == NSNotFound) {
        //不包含中文
        return unicodeStr;
    }
    NSString *tempStr1 = [unicodeStr stringByReplacingOccurrencesOfString:@"\\u"withString:@"\\U"];
    NSString *tempStr2 = [tempStr1 stringByReplacingOccurrencesOfString:@"\""withString:@"\\\""];
    NSString *tempStr3 = [[@"\""stringByAppendingString:tempStr2]stringByAppendingString:@"\""];
    NSData *tempData = [tempStr3 dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *error = nil;
    NSString *returnStr = [NSPropertyListSerialization propertyListWithData:tempData options:NSPropertyListImmutable format:nil error:&error];
//    NSLog(@"error %@",error);
    return [returnStr stringByReplacingOccurrencesOfString:@"\\r\\n"withString:@"\n"];
}

@end
