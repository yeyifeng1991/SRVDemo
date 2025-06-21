//
//  MBProgressHUD+TK_WeRecord.m
//  TKVRecordClass
//
//  Created by Frank_m on 2021/2/7.
//

#import "MBProgressHUD+TK_WeRecord.h"
#import "SRVpnHeader.h"
#import "TKHelperUtil.h"

#define TKKeyWindow TKMainWindow?:TKMainRootView

@implementation MBProgressHUD (TK_WeRecord)

+ (void)showMessage:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showMessage:message inView:TKKeyWindow];
    });
}

+ (void)showLowerMessage:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showLowerMessage:message inView:TKKeyWindow];
    });
}

+ (void)showMessage:(NSString *)message textLines:(NSInteger)lines
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showMessage:message inView:TKKeyWindow textLines:lines];
    });
}

+ (void)showMessage:(NSString *)message inView:(UIView *)view textLines:(NSInteger)lines
{
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:view];
        hud.tag = 2023;
        hud.contentColor = UIColor.grayColor;
        hud.margin = 16;
        hud.mode = MBProgressHUDModeText;
        hud.removeFromSuperViewOnHide = YES;
        hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        hud.bezelView.backgroundColor = UIColor.blackColor;
        hud.animationType = MBProgressHUDAnimationFade;
        hud.label.font = [UIFont systemFontOfSize:14.0];
        hud.label.textColor = UIColor.whiteColor;
        hud.label.numberOfLines = lines;
        hud.label.text = message;
        hud.userInteractionEnabled = NO;
        [view addSubview:hud];
        if (IS_IPHONE_X) {
            hud.offset = CGPointMake(0, -(ScreenH)/2 + 168);
        } else {
            hud.offset = CGPointMake(0, -(ScreenH)/2 + 138);
        }
        
        [hud showAnimated:YES];
        float duration = 2.5;
        [hud hideAnimated:YES afterDelay:duration];
    });
    
}

+ (void)showMessage:(NSString *)message inView:(UIView *)view
{
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:view];
        hud.tag = 2023;
        hud.contentColor = UIColor.grayColor;
        hud.margin = 16;
        hud.mode = MBProgressHUDModeText;
        hud.removeFromSuperViewOnHide = YES;
        hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        hud.bezelView.backgroundColor = UIColor.blackColor;
        hud.animationType = MBProgressHUDAnimationFade;
        hud.label.font = [UIFont systemFontOfSize:14.0];
        hud.label.textColor = UIColor.whiteColor;
        hud.label.text = message;
        hud.userInteractionEnabled = NO;
        [view addSubview:hud];
        if (IS_IPHONE_X) {
            hud.offset = CGPointMake(0, -(ScreenH)/2 + 168);
        } else {
            hud.offset = CGPointMake(0, -(ScreenH)/2 + 138);
        }
        
        [hud showAnimated:YES];
        float duration = 2.0;
        [hud hideAnimated:YES afterDelay:duration];
    });
    
}

+ (void)showLowerMessage:(NSString *)message inView:(UIView *)view
{
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:view];
        hud.tag = 2023;
        hud.contentColor = UIColor.grayColor;
        hud.margin = 16;
        hud.mode = MBProgressHUDModeText;
        hud.removeFromSuperViewOnHide = YES;
        hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        hud.bezelView.backgroundColor = UIColor.blackColor;
        hud.animationType = MBProgressHUDAnimationFade;
        hud.label.font = [UIFont systemFontOfSize:14.0];
        hud.label.textColor = UIColor.whiteColor;
        hud.label.text = message;
        hud.userInteractionEnabled = NO;
        [view addSubview:hud];
        if (IS_IPHONE_X) {
            hud.offset = CGPointMake(0, -(ScreenH)/2 + 168-50-20);
        } else {
            hud.offset = CGPointMake(0, -(ScreenH)/2 + 138-50-20);
        }
        
        [hud showAnimated:YES];
        float duration = 2.0;
        [hud hideAnimated:YES afterDelay:duration];
    });
    
}

+ (void)showCenterMessage:(NSString *)message
{
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:TKKeyWindow];
    hud.contentColor = UIColor.grayColor;
    hud.margin = 16;
    hud.mode = MBProgressHUDModeText;
    hud.removeFromSuperViewOnHide = YES;
    hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    hud.bezelView.backgroundColor = UIColor.blackColor;
    hud.animationType = MBProgressHUDAnimationFade;
    hud.label.font = [UIFont systemFontOfSize:14.0];
    hud.label.text = message;
    hud.label.textColor = UIColor.whiteColor;
    hud.userInteractionEnabled = NO;
    [TKKeyWindow addSubview:hud];
    [hud showAnimated:YES];
    float duration = 2.0;
    [hud hideAnimated:YES afterDelay:duration];
}

+ (MBProgressHUD *)show
{
    MBProgressHUD *hud;
    if(TKKeyWindow){
        hud = [[MBProgressHUD alloc] initWithView:TKKeyWindow];
        hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        hud.bezelView.backgroundColor = UIColor.clearColor;
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.removeFromSuperViewOnHide = YES;
        hud.animationType = MBProgressHUDAnimationFade;
        [TKKeyWindow addSubview:hud];
        [hud showAnimated:YES];
    }
    return hud;
}

+ (void)hide
{
    MBProgressHUD *hud = [self HUDForView:TKKeyWindow];
    if (hud != nil) {
        hud.removeFromSuperViewOnHide = YES;
        [hud hideAnimated:YES];
    }
}

+ (instancetype)tk_showHUDAddedTo:(UIView *)view animated:(BOOL)animated
{
    MBProgressHUD *hud = [[self alloc] initWithView:view];
    hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    hud.bezelView.backgroundColor = UIColor.clearColor;
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.removeFromSuperViewOnHide = YES;
    [view addSubview:hud];
    [hud showAnimated:animated];
    return hud;
}

@end
