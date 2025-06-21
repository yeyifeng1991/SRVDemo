//
//  SRVpnHeader.h
//  SRVDemo
//
//  Created by yyf on 2025/6/18.
//

#ifndef SRVpnHeader_h
#define SRVpnHeader_h
#define TKMainWindow  [TKHelperUtil keyWindow]
#define TKMainRootViewController (TKMainWindow ? TKMainWindow.rootViewController : nil)
#define TKMainRootView  (TKMainRootViewController ? TKMainRootViewController.view : nil)

// 设备判断
#define IS_IPHONE_X ([TKHelperUtil isiPhoneX] && IS_IPHONE)
#define IS_IPHONE ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
#define IS_IPAD ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#define TKISBangsScreen ({\
    BOOL isBangsScreen = NO; \
    if (@available(iOS 11.0, *)) { \
    UIWindow *window = [[UIApplication sharedApplication].windows firstObject]; \
    isBangsScreen = window.safeAreaInsets.bottom > 0; \
    } \
    isBangsScreen; \
})
// 横向的尺寸适配
#define Fit(height) (IS_IPAD ? (height) : (height) * 0.8)
#define FitPhone(height) (IS_IPAD ? (height) * 1.25 : (height))

#define FitW(width)  (ScreenW / 1024.0 * width)
#define FitH(height) (ScreenH / 768.0 * height)

#define TK_Screen_Margin (IS_IPAD ? 30 : 20)

#define TK_Screen_16Margin (IS_IPAD ? 16 : 12)

#define TK_Screen_12Margin 12

#define TK_NavigationBar_Height (IS_IPHONE_X?98.0:(IS_IPAD?98.0:74.0))
#define TK_TabBar_Height (IS_IPHONE_X?83.0:49.0)
#define TK_IndicatorBar_Height (IS_IPHONE_X?34.0:0.0)
#define TK_StatusBar_Height [TZCommonTools tz_statusBarHeight]
#define TK_OriginNavigationBar_Height (IS_IPAD?50.0:44.0)



// 屏幕 尺寸
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define ScreenW (IS_IPAD ? (MAX((SCREEN_WIDTH), (SCREEN_HEIGHT))) : (MIN((SCREEN_WIDTH), (SCREEN_HEIGHT))))
#define ScreenH (IS_IPAD ? (MIN((SCREEN_WIDTH), (SCREEN_HEIGHT))) : (MAX((SCREEN_WIDTH), (SCREEN_HEIGHT))))
//#define ScreenH [UIScreen mainScreen].bounds.size.height
//#define ScreenW [UIScreen mainScreen].bounds.size.width

// 获取屏幕的较大和较小值
#define ScreenMax MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)
#define ScreenMin MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)

#define TK_DEFAULT_COLUMNWIDTHFRACTION (210/1024.0)

// 设备判断
#define IS_IPHONE_X ([TKHelperUtil isiPhoneX] && IS_IPHONE)
#define IS_IPHONE ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
#define IS_IPAD ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#define TKISBangsScreen ({\
    BOOL isBangsScreen = NO; \
    if (@available(iOS 11.0, *)) { \
    UIWindow *window = [[UIApplication sharedApplication].windows firstObject]; \
    isBangsScreen = window.safeAreaInsets.bottom > 0; \
    } \
    isBangsScreen; \
})

#define LoginMargin (IS_PAD ?100 : 33)

#define FitPhoneW(width)  (ScreenW / 375 * width)
#define FitPhoneH(height) (ScreenH / 667 * height)
#define FitUIPhoneH(height) (ScreenH / 812 * height)


// 字体
#define TKSYSTEMFONT(size) [UIFont systemFontOfSize:(size)]
#define TKSYSTEMBLODFONT(size) [UIFont boldSystemFontOfSize:(size)]
#define TKNUMBERFONT(S) [UIFont fontWithName:@"DINAlternate-Bold" size:(S)]
#define TKMEDIUMFONT(S) [UIFont fontWithName:@"PingFangSC-Medium" size:(S)]
#define TKREGULARFONT(S) [UIFont fontWithName:@"PingFangSC-Regular" size:(S)]
#define TKSEMIBOLDFONT(S) [UIFont fontWithName:@"PingFangSC-Semibold" size:(S)]
#define TKHELVETICAFONT(S) [UIFont fontWithName:@"HelveticaNeue-Medium" size:(S)]

//App信息
//APP版本号
#define TKAppVersion [[[NSBundle mainBundle] infoDictionary] objectForKey:@"sys-clientVersion"]
//系统版本号
#define TKSystemVersion [[UIDevice currentDevice] systemVersion]
//获取当前语言
#define TKCurrentLanguage ([[NSLocale preferredLanguages] objectAtIndex:0])
//app名字
#define kInfoDict [NSBundle mainBundle].localizedInfoDictionary ?: [NSBundle mainBundle].infoDictionary
#define TKAPPName [kInfoDict valueForKey:@"CFBundleDisplayName"] ?: [kInfoDict valueForKey:@"CFBundleName"]

// 引用
#define tk_weakify(var)   __weak typeof(var) weakSelf = var
#define tk_strongify(var) __strong typeof(var) strongSelf = var

#define TKMTLocalized(s) [NSBundle tkns_localizedStringForKey:(s)]

// 延迟时间
#define TKDisTime(time) dispatch_time(DISPATCH_TIME_NOW, (int64_t)time * NSEC_PER_SEC)

// 延迟执行
#define TKDisMainAfter(disTime,block) dispatch_after(disTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){dispatch_async(dispatch_get_main_queue(), block);});

#define TKAppStoreFormat @"https://apps.apple.com/cn/app/id%ld"

#endif /* SRVpnHeader_h */
