//
//  MBProgressHUD+TK_WeRecord.h
//  TKVRecordClass
//
//  Created by Frank_m on 2021/2/7.
//

#import "MBProgressHUD.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBProgressHUD (TK_WeRecord)

// 多行提示
+ (void)showMessage:(NSString *)message textLines:(NSInteger)lines;

+ (void)showMessage:(NSString *)message;

+ (void)showLowerMessage:(NSString *)message;

+ (void)showMessage:(NSString *)message inView:(UIView *)view;

+ (void)showCenterMessage:(NSString *)message;


+ (MBProgressHUD *)show;

+ (void)hide;

+ (instancetype)tk_showHUDAddedTo:(UIView *)view animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
