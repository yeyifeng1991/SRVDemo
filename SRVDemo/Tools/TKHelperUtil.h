//
//  TKHelperUtil.h
//  EduClass
//
//  Created by lyy on 2018/4/27.
//  Copyright © 2018年 talkcloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MJRefresh/MJRefresh.h>
#import <WebKit/WebKit.h>


@interface TKHelperUtil : NSObject

+ (NSAttributedString *)convertHtmlStringToLinkAttributedString:(NSString *)htmlString linkBlock:(void(^)(NSString *linkString))linkBlock;

+ (BOOL)isPWDValid:(NSString *)pwdString;

+ (BOOL)isEmailValid:(NSString *)emailString;

//keyWindow
+ (UIWindow*)keyWindow;

/**
 *  当前控制器
 */
+ (UIViewController *)TopVC;
/**
 *  改变行间距
 */
+ (void)changeLineSpaceForLabel:(UILabel *)label WithSpace:(float)space;

/**
 *  改变字间距
 */
+ (void)changeWordSpaceForLabel:(UILabel *)label WithSpace:(float)space;

/**
 * 计算字体宽高度
 */
+ (CGSize)sizeForString:(NSString *)string font:(UIFont *)font size:(CGSize)size;

/**
 *  改变行间距和字间距
 */
+ (void)changeSpaceForLabel:(UILabel *)label withLineSpace:(float)lineSpace WordSpace:(float)wordSpace;

// url编码
+(NSString *)URLEncodedString:(NSString *)string;

// url解码
+(NSString *)URLDecodedString:(NSString *)string;

// data转换为字典
+ (NSDictionary *)convertWithData:(id)data;

// id类型转换为字符串数据
+ (NSString *)convertObject:(id)responseObject;

// 读取本地JSON文件
+ (NSDictionary *)readLocalFileWithName:(NSString *)name;

// 字典转成data
+ (NSData *)convertWithParams:(NSMutableDictionary*)param;

// json转成字典
+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;

// 活动公共路径
+ (NSString *)publicParamPath;

// 判断是否手机号
+ (BOOL)isPhone:(NSString *)number;

// 判断是合格密码
+ (BOOL)isSecPwd:(NSString *)number;
// 判断是否控制
+  (BOOL)isBlank:(NSString *)aStr;

//判断是否是图片
+  (BOOL)isImage:(NSString *)typeStr;
//判断是否是视频
+  (BOOL)isVideo:(NSString *)typeStr;
//判断是否是音频
+  (BOOL)isAudio:(NSString *)typeStr;


//去掉首尾空格
+(NSString *)removeSpaceRealandTail:(NSString *)string;

//  设置圆角
+ (void)layerRadiusWithView:(UIView*)layerView radius:(CGSize)size byRoundingCorners:(UIRectCorner)corners;
// 取消圆角效果
+ (void)removeLayerRadiusWithView:(UIView *)layerView;

// 获取富文本验证码文字
+ (NSMutableAttributedString * )verCodeTitle;
// 获取富文本隐私政策
+ (NSMutableAttributedString * )loginAgreementTitle;


// 获取安全显示的手机号 150****3945
+ (NSString *)securityPhone:(NSString*)mobileNum;

// 加密显示邮箱
+ (NSString *)securityEmail:(NSString*)emailString;

/*!
 *  添加 cell 圆角 与 边线（willDisplayCell 中添加）
 *
 *  @param radius    圆角
 *  @param tableView tableView
 *  @param  setupTableView 用户传递过来的tableView
 *  @param cell      cell
 *  @param indexPath index
 */
+ (void)addRoundedCornersWithRadius:(CGFloat)radius forTableView:(UITableView *)tableView  VCTableView:(UITableView*)setupTableView forCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

/*!
 *  添加 cell 圆角 与 边线（willDisplayCell 中添加）
 *
 *  @param radius    圆角
 *  @param tableView tableView
 *  @param cell      cell
 *  @param indexPath index
 */
+ (void)addRoundedShadowCornersWithRadius:(CGFloat)radius forTableView:(UITableView *)tableView  forCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

// 初始化键盘管理类
+ (void)initIQKeyboardManager;

//格式 2020-03-15~2020-06-01 -> 03月15日-06月01日
+ (NSString *)formatStringDate:(NSString *)dateString;

//格式 06月01日 周二 10:40
+ (NSString *)getDateDisplayString:(long long) miliSeconds;

// 护眼模式
+ (void)protectEye;
// 护眼模式 初始化护眼模式
+ (void)initProtectEye;
// 关闭护眼模式
+ (void)closeProtctEye;
// 初始化时间
+ (void)initIndexTime ;
// 获取当前协议
+ (NSString*)privacyPolicyUrl;
// 兒童隱私協議
+ (NSString*)childPrivacyPolicyUrl;
// 用户协议
+ (NSString*)userAgreementUrl;
// 门课AppStore id
+ (NSInteger)appStoreId;
// 检查版本号
+ (void)checkVersion;

// 检查AppStore更新
+ (void)checkAppstoreVersionIsLaunch:(BOOL)isLaunch;

// 根据后台返回版本号解析成本地数据需要的版本号 示例：20210707110 - 1.1.0
+ (NSString *)versionByNetVersion:(NSString*)str;


// 是否是登录板块
+ (BOOL)isLoginPlate;
// 状态栏高度
+ (CGFloat)statusBarHeight;

+ (UIEdgeInsets)tk_safeAreaInsets;

// 存储手机号
+ (void)savePhone:(NSString*)telephone;

+ (void)saveEmail:(NSString*)email;

+ (void)saveAccount:(NSString*)account;

+ (NSString * )userEmail;

+ (NSString * )userAccount;

// 获取用户手机号
+ (NSString * )userPhone;

//判断一个字符串是都是纯数字
+ (BOOL)judgePureInt:(NSString *)content;

//判断是否为iPhoneX
+ (BOOL)isiPhoneX;

//获取文字size
+ (CGSize)titleSize:(NSString *)title withFont:(UIFont*)font fitSize:(CGSize)size;

// 创建label 
+ (UILabel *)labelWithTitle:(NSString *)title Font:(UIFont *)font color:(UIColor *)color;
// 创建button
+ (UIButton *)buttonWithTitle:(NSString *)title Font:(UIFont *)font color:(UIColor *)color;


+ (NSString *)labelScoreTitle:(NSInteger )score;
+ (NSString *)workDetailLabelScoreTitle:(NSInteger )score;


+(NSMutableAttributedString *)convertContainHtmlString:(NSString *)htmlString font:(UIFont*)font;

// 时间戳—>字符串时间
// MM-dd HH:mm
+ (NSString*)TkStringFromTimestamp:(NSString*)timestamp;
// yyyy-MM-dd HH:mm
+ (NSString *)TkStringFromTimestampYMDHM:(NSString *)timestamp;

// yyyy-MM-dd HH:mm:ss
+ (NSString *)TkStringFromTimestampYMDHMSS:(NSString *)timestamp;

// 字符串时间—>时间戳
+ (NSString*)TkTimestampFromString:(NSString*)theTime;
+ (NSTimeInterval)timestampFromString:(NSString *)dateString;
+ (NSTimeInterval)timestampYMDHMSFromString:(NSString *)dateString;
/**
 时间戳字符串转年月日 固定转换格式(年-月-日 时:分:秒 毫秒)

 @param date 时间戳字符串
 @return 年 月 日 时 分 秒 毫秒
 */
+ (NSString *)dateToString:(NSString *)date;
/**
 时间戳字符串转年月日 固定格式

 @param dateStr 时间戳字符串(eg:1368082020)
 @return 年月日
 */
+ (NSString *)stringToDate:(NSString *)dateStr;

/**
 年月日转时间戳字符串 自定义格式(yyyy-MM-dd hh:mm:ss zzz)

 @param date 时间戳字符串
 @param format 格式(yyyy-MM-dd hh:mm:ss zzz)
 @return 时间戳字符串
 */
+ (NSString *)dateToString:(NSString *)date Format:(NSString *)format;
/**
 年月日转时间戳字符串

 @param dateStr 字符串(2001-11-11 12:11:44 565)
 @param format 格式(yyyy-MM-dd hh:mm:ss zzz)
 @return 时间戳时间戳
 */
+ (NSString *)stringToDate:(NSString *)dateStr Format:(NSString *)format;

+ (NSString *)dateStyleCommentTimeIntervalToDateString:(NSString *)timeInterval;

/// 获取指定日期
+ (NSString *)getDayDateWithToadd:(NSInteger)addDay;

/// 根据时间获取指定日期
+ (NSString *)getDayDateWithToadd:(NSInteger)addDay dateString:(NSString *)dateString;

/// 根据时间获取指定日期
+ (NSString *)getDayDateHHMMSSWithToadd:(NSInteger)addDay dateString:(NSString *)dateString;

// 设置黑暗模式
+ (void)setUserInterfaceStyle:(UIUserInterfaceStyle)style API_AVAILABLE(ios(13.0));

// 刷新尾部
+ (MJRefreshAutoNormalFooter *)defaultFooterWithRefreshingTarget:(id)target refreshingAction:(SEL)action;

//
+ (void)textViewMaxTextView:(UITextView *)textView AndMaxCount:(NSInteger)maxCount;

// 版本号比较
+ (int)compareWithVersion1:(NSString *)version1 version2:(NSString *)version2;

// 获取登录时的传入字典的url
+ (NSString*)queryEnterpriseIDWithPath:(NSString*)url;

//  获取url最终路径
+ (NSString *)queryStringWithUrl:(NSString*)url;

+ (NSAttributedString *)convertHtmlStringToAttributedString:(NSString *)htmlString;

//简化附件URL
+ (NSURL *)simplifyAttachmentUrl:(NSURL *)fileNameURL;

+ (UIView *)TKViewWithcornerRadius:(float )cornerRadius color:(UIColor *)color;

+(UILabel *)TKlabelWithTitle:(NSString *)title Font:(UIFont *)font color:(UIColor *)color;

@end


