//
//  TKHelperUtil.m
//  EduClass
//
//  Created by lyy on 2018/4/27.
//  Copyright © 2018年 talkcloud. All rights reserved.
//

#import "TKHelperUtil.h"
#import "sys/utsname.h"
#import <mach/mach.h>
#import <sys/sysctl.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <IQKeyboardManager/IQKeyboardManager.h>

static TKHelperUtil *instance;
static dispatch_once_t onceToken;
@implementation TKHelperUtil
+ (instancetype)shareHelperUtil
{
    dispatch_once(&onceToken, ^{
        instance = [[TKHelperUtil alloc] init];
    });
    return instance;
}

+ (BOOL)isEmailValid:(NSString *)emailString {
    
    if (!emailString.length) return NO;
    
    NSString *emailRegex = @"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *pre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",emailRegex];
    return [pre evaluateWithObject:emailString];
}

+ (BOOL)isPWDValid:(NSString *)pwdString {
    
    if (!pwdString.length) return NO;
    
    NSString *emailRegex1 = @"^(?![\\d]+$)(?![a-zA-Z]+$)(?![^\\da-zA-Z]+$).{8,16}$";
    NSPredicate *pre1 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",emailRegex1];
    return [pre1 evaluateWithObject:pwdString];
}
+ (UIWindow*)keyWindow {
    UIWindow *keyWindow = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                keyWindow = scene.windows.firstObject;
                break;
            }
        }
    } else {
        keyWindow = [UIApplication sharedApplication].keyWindow;
    }
    // 如果未找到 keyWindow，则返回全局窗口的第一项（备用处理）
    if (!keyWindow) {
        keyWindow = UIApplication.sharedApplication.windows.firstObject;
    }
    return keyWindow;
}
+ (UIViewController *)TopVC {
    UIViewController *resultVC = [self _TopVC:UIApplication.sharedApplication.keyWindow.rootViewController];
    while (resultVC.presentedViewController != nil) {
        resultVC = [self _TopVC:resultVC.presentedViewController];
    }
    return resultVC;
}

+ (UIViewController *)_TopVC:(UIViewController *)vc {
    if ([vc isKindOfClass:UINavigationController.class]) {
        return [self _TopVC:((UINavigationController *)vc).topViewController ];
    } else if ([vc isKindOfClass:UITabBarController.class]) {
        return [self _TopVC:((UITabBarController *)vc).selectedViewController];
    } else {
        return vc;
    }
}

+ (void)changeLineSpaceForLabel:(UILabel *)label WithSpace:(float)space {
    NSString *labelText = label.text;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:labelText];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:space];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [labelText length])];
    label.attributedText = attributedString;
    [label sizeToFit];
}

+ (void)changeWordSpaceForLabel:(UILabel *)label WithSpace:(float)space {
    NSString *labelText = label.text;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:labelText attributes:@{NSKernAttributeName:@(space)}];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [labelText length])];
    label.attributedText = attributedString;
    [label sizeToFit];
}

+ (void)changeSpaceForLabel:(UILabel *)label withLineSpace:(float)lineSpace WordSpace:(float)wordSpace {
    NSString *labelText = label.text;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:labelText attributes:@{NSKernAttributeName:@(wordSpace)}];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:lineSpace];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [labelText length])];
    label.attributedText = attributedString;
    [label sizeToFit];
}
// url编码
+(NSString *)URLEncodedString:(NSString *)string {
    NSString *encodedString = (NSString *)
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                              (CFStringRef)string,
                                                              NULL,
                                                              (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                              kCFStringEncodingUTF8));
    
    return encodedString;
}

//计算字体宽高度
+ (CGSize)sizeForString:(NSString *)string font:(UIFont *)font size:(CGSize)size
{
    /*
     
     NSStringDrawingUsesLineFragmentOrigin   //整个文本将以每行组成的矩形为单位计算整个文本的尺寸
     NSStringDrawingUsesFontLeading      //使用字体的行间距来计算文本占用的范围，即每一行的底部到下一行的底部的距离计算
     NSStringDrawingUsesDeviceMetrics        //将文字以图像符号计算文本占用范围，而不是以字符计算。也即是以每一个字体所占用的空间来计算文本范围
     NSStringDrawingTruncatesLastVisibleLine     //当文本不能适合的放进指定的边界之内，则自动在最后一行添加省略符号。如果NSStringDrawingUsesLineFragmentOrigin没有设置，则该选项不生效
     */
    
    
    return [string boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : font} context:nil].size;
}


+(NSString *)removeSpaceRealandTail:(NSString *)string{
    if(string == nil) return string;
    return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

// url解码
+(NSString *)URLDecodedString:(NSString *)string {
    NSString *decodedString=(__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (__bridge CFStringRef)string, CFSTR(""), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    
    return decodedString;
    
}

#pragma mark 是否是iPhoneX
+ (BOOL)isiPhoneX {
    BOOL result = NO;
    if (UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPhone) {
        return result;
    }
    if (CGRectGetHeight([UIApplication sharedApplication].statusBarFrame)>=44.0f) {
        result = YES;
    }
    
    if (@available(iOS 11.0, *)) {
        UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];
        if (mainWindow.safeAreaInsets.bottom > 0.0) {
            result = YES;
        }
    }
    return result;
}

+ (CGFloat)statusBarHeight {
    CGFloat statusBarHeight = 0;
    if (@available(iOS 13.0, *)) {
        statusBarHeight = [UIApplication sharedApplication].windows.firstObject.windowScene.statusBarManager.statusBarFrame.size.height;
    } else {
        statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    }
    return statusBarHeight;
}

+ (UIEdgeInsets)tk_safeAreaInsets {
    UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
    if (![window isKeyWindow]) {
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        if (CGRectEqualToRect(keyWindow.bounds, [UIScreen mainScreen].bounds)) {
            window = keyWindow;
        }
    }
    if (@available(iOS 11.0, *)) {
        UIEdgeInsets insets = [window safeAreaInsets];
        return insets;
    }
    return UIEdgeInsetsZero;
}


+ (NSDictionary *)convertWithData:(id)data {
    NSDictionary *dataDic = @{};
    if ([data isKindOfClass:[NSString class]]) {
        NSString *tDataString = [NSString stringWithFormat:@"%@", data];
        NSData *tJsData       = [tDataString dataUsingEncoding:NSUTF8StringEncoding];
        dataDic               = [NSJSONSerialization JSONObjectWithData:tJsData
                                                                options:NSJSONReadingMutableContainers
                                                                  error:nil];
    } else if ([data isKindOfClass:[NSDictionary class]]) {
        dataDic = (NSDictionary *)data;
    }
    return dataDic;
}

// 读取本地JSON文件
+ (NSDictionary *)readLocalFileWithName:(NSString *)name {
    // 获取文件路径
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"json"];
    // 将文件数据化
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
    // 对数据进行JSON格式化并返回字典形式
    return [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
}

// id类型转换为字符串数据
+ (NSString *)convertObject:(id)responseObject{
    NSString * jonsStr = @"";
    NSData * data = [NSJSONSerialization dataWithJSONObject:responseObject options:NSJSONWritingPrettyPrinted error:nil];
    jonsStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return  jonsStr;
}
// 字典转成data
+ (NSData *)convertWithParams:(NSMutableDictionary*)param
{
    NSMutableString *postString = [[NSMutableString alloc] init];
    if (param && [param isKindOfClass:[NSMutableDictionary class]]) {
        for (id key in [param allKeys]) {
            [postString appendFormat:@"%@=%@&", key, [param objectForKey:key]];
        }
        [postString deleteCharactersInRange:NSMakeRange([postString length] - 1, 1)];
    }
    //将请求参数字符串转成NSData类型
    NSData *postData = [postString dataUsingEncoding:NSUTF8StringEncoding];
    return  postData;
    
}

//json格式字符串转字典：

+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
    
    if (jsonString == nil) {
        
        return nil;
        
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *err;
    
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                         
                                                        options:NSJSONReadingMutableContainers
                         
                                                          error:&err];
    
    if(err) {
        
        NSLog(@"json解析失败：%@",err);
        
        return nil;
        
    }
    
    return dic;
    
}


+ (BOOL)isPhone:(NSString *)number
{
    if ([self isBlank:number]) {
        return NO;
    }
    NSString *phoneRegex = @"^(1[3-9])\\d{9}$";
    NSPredicate *phoneTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",phoneRegex];
    return [phoneTest evaluateWithObject:number];
}

// 判断是合格密码
+ (BOOL)isSecPwd:(NSString *)number{
    if ([self isBlank:number]) {
        return NO;
    }
    if (number.length >= 8 && number.length <= 20) {
        return  YES;
    }else{
        return  NO;
    }
}

// 是否是空白
+  (BOOL)isBlank:(NSString *)aStr {
    if (!aStr) {
        return YES;
    }
    if ([aStr isKindOfClass:[NSNull class]]) {
        return YES;
    }
    NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *trimmedStr = [aStr stringByTrimmingCharactersInSet:set];
    if (!trimmedStr.length) {
        return YES;
    }
    return NO;
}

//判断是否是图片
+  (BOOL)isImage:(NSString *)typeStr{
    if([typeStr containsString:@"png"] ||
       [typeStr containsString:@"jpeg"]||
       [typeStr containsString:@"jpg"] ||
       [typeStr containsString:@"gif"]||
       [typeStr containsString:@"bmp"]){
        return YES;
    }
    return NO;
}

//判断是否是视频
+  (BOOL)isVideo:(NSString *)typeStr{
    if([typeStr containsString:@"mp4"] ||
       [typeStr containsString:@"mov"]){
        return YES;
    }
    return NO;
}

+  (BOOL)isAudio:(NSString *)typeStr{
    if([typeStr isEqualToString:@"mp3"]||  //音频
       [typeStr isEqualToString:@"aac"]||
       [typeStr isEqualToString:@"AAC"]||
       [typeStr isEqualToString:@"caf"]){
        return YES;
    }
    return NO;
}


+ (void)layerRadiusWithView:(UIView*)layerView radius:(CGSize)size byRoundingCorners:(UIRectCorner)corners;
{
    
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:layerView.bounds byRoundingCorners:corners cornerRadii:size];
    CAShapeLayer *layer = [[CAShapeLayer alloc]init];
    layer.frame = layerView.bounds;
    layer.path = maskPath.CGPath;
    layerView.layer.mask = layer;
}
+ (void)removeLayerRadiusWithView:(UIView *)layerView {
    layerView.layer.mask = nil;
}
// 获取安全显示的手机号 150****3945
+ (NSString *)securityPhone:(NSString*)mobileNum;
{
    if ([self isBlank:mobileNum]) {
        return @""; // 如果为空直接返回
    }
    if (mobileNum.length < 8) {
        return mobileNum;
    }
    NSString *secNum = [mobileNum stringByReplacingCharactersInRange:NSMakeRange(3, 4) withString:@"****"];
    return secNum ;
}

+ (NSString *)securityEmail:(NSString*)emailString;
{
    if ([self isBlank:emailString]) {
        return @""; // 如果为空直接返回
    }
    
    NSRange atRange = [emailString rangeOfString:@"@"];
    
    if (atRange.location == NSNotFound) {
        return emailString;
    }
    
    // 加密range
    NSInteger securlength = MIN((atRange.location+1)/2, 4);
    NSRange securRange = NSMakeRange(atRange.location-securlength,securlength);
    
    NSString *secNum = [emailString stringByReplacingCharactersInRange:securRange withString:@"****"];
    
    return secNum ;
}



/*!
 *  添加 cell 圆角 与 边线（willDisplayCell 中添加）
 *
 *  @param radius    圆角
 *  @param tableView tableView
 *  @param  setupTableView 用户传递过来的tableView
 *  @param cell      cell
 *  @param indexPath index
 */
+ (void)addRoundedCornersWithRadius:(CGFloat)radius forTableView:(UITableView *)tableView  VCTableView:(UITableView*)setupTableView forCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
    if ([cell respondsToSelector:@selector(tintColor)]) {
        
        if (tableView == setupTableView) {
            
            NSInteger sectionCount = [tableView numberOfRowsInSection:indexPath.section] - 1;// section row 个数
            //            重点 30 为正数时 缩减2 *30的距离
            CGRect bounds = CGRectInset(cell.bounds, 30, 0); // 显示的cell 点击区域
            
            // 1.新 layer 用于添加 cell 边线
            CAShapeLayer *newlayer = [[CAShapeLayer alloc] init];
            UIView *testView = [[UIView alloc] initWithFrame:bounds];
            
            CGMutablePathRef pathRef = CGPathCreateMutable();
            
            
            // 2.再盖一个 mask
            CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];// 用于蒙板
            
            // 贝塞尔曲线
            UIBezierPath *bezierPath = nil;
            
            CGRect shadowRect = CGRectZero;
            
            
            // section 只有一个时
            if (indexPath.row == 0 && indexPath.row == sectionCount) {
                CGPathAddRoundedRect(pathRef, nil, bounds, radius, radius);
                shadowRect = bounds;
                
                
                bezierPath = [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:radius];
                [maskLayer setPath:bezierPath.CGPath];
                
                
                // 第一个 row
            } else if (indexPath.row == 0) {
                
                
                CGPathMoveToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMaxY(bounds));//左下
                CGPathAddArcToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMinY(bounds), CGRectGetMidX(bounds), CGRectGetMinY(bounds), radius);// 左上
                CGPathAddArcToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMinY(bounds), CGRectGetMaxX(bounds), CGRectGetMidY(bounds), radius);// 右上
                CGPathAddLineToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMaxY(bounds));// 右下
                CGPathAddLineToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMaxY(bounds));// 下线
                
                bezierPath = [UIBezierPath bezierPathWithRoundedRect:bounds
                                                   byRoundingCorners:(UIRectCornerTopLeft|UIRectCornerTopRight)
                                                         cornerRadii:CGSizeMake(radius, radius)];
                [maskLayer setPath:bezierPath.CGPath];
                shadowRect = CGRectMake(bounds.origin.x, bounds.origin.y - 7.5, bounds.size.width, 15);
                
                // 最后一个 row
            } else if (indexPath.row == sectionCount) {
                
                
                CGPathMoveToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMinY(bounds));// 左上
                CGPathAddArcToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMaxY(bounds), CGRectGetMidX(bounds), CGRectGetMaxY(bounds), radius);// 左下
                CGPathAddArcToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMaxY(bounds), CGRectGetMaxX(bounds), CGRectGetMidY(bounds), radius);// 右下
                CGPathAddLineToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMinY(bounds));// 右上
                
                bezierPath = [UIBezierPath bezierPathWithRoundedRect:bounds
                                                   byRoundingCorners:(UIRectCornerBottomLeft|UIRectCornerBottomRight)
                                                         cornerRadii:CGSizeMake(radius, radius)];
                
                [maskLayer setPath:bezierPath.CGPath];
                shadowRect = CGRectMake(bounds.origin.x, bounds.size.height - 7.5, bounds.size.width, 15);
                
                
                // 中间 row
            } else {
                
                CGPathMoveToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMinY(bounds));// 左上
                CGPathAddLineToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMaxY(bounds));// 左下
                CGPathAddLineToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMaxY(bounds));// 右下
                CGPathAddLineToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMinY(bounds));// 右上
                
                UIBezierPath *path = [UIBezierPath bezierPathWithRect:bounds];
                [maskLayer setPath:path.CGPath];
                
            }
            // 1.新添加的layer 设置属性
            //            newlayer.path = pathRef;
            //
            //            CFRelease(pathRef);
            //            newlayer.fillColor = [UIColor whiteColor].CGColor;
            //            newlayer.strokeColor = [UIColor whiteColor].CGColor;
            //            newlayer.lineWidth = 1.0f;
            //
            //            [testView.layer insertSublayer:newlayer atIndex:0];
            //            testView.backgroundColor = [UIColor clearColor];
            //            cell.backgroundView = testView;
            
            // 2.mask 切圆角
            [cell setMaskView:[[UIView alloc] initWithFrame:cell.bounds]];
            [cell.maskView.layer insertSublayer:maskLayer atIndex:0];
            maskLayer.borderColor = [UIColor clearColor].CGColor;
            
            [cell.maskView.layer setMasksToBounds:YES];
            [cell setClipsToBounds:YES];
            
            
        }
    }
}

/*!
 *  添加 cell 圆角 与 边线（willDisplayCell 中添加）
 *
 *  @param radius    圆角
 *  @param tableView tableView
 *  @param cell      cell
 *  @param indexPath index
 */
+ (void)addRoundedShadowCornersWithRadius:(CGFloat)radius forTableView:(UITableView *)tableView  forCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath{
    
    if ([cell respondsToSelector:@selector(tintColor)]) {
        
        // 圆角角度
        // 设置cell 背景色为透明
        cell.backgroundColor = UIColor.clearColor;
        // 创建两个layer
        CAShapeLayer *normalLayer = [[CAShapeLayer alloc] init];
        CAShapeLayer *selectLayer = [[CAShapeLayer alloc] init];
        // 获取显示区域大小
        CGRect bounds = CGRectInset(cell.bounds, 16, 0);
        // cell的backgroundView
        UIView *normalBgView = [[UIView alloc] initWithFrame:bounds];
        // 获取每组行数
        NSInteger rowNum = [tableView numberOfRowsInSection:indexPath.section];
        // 贝塞尔曲线
        UIBezierPath *bezierPath = nil;
        
        if (rowNum == 1) {
            // 一组只有一行（四个角全部为圆角）
            bezierPath = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(radius, radius)];
            normalBgView.clipsToBounds = NO;
        }else {
            //             有多行
            normalBgView.clipsToBounds = YES;
            if (indexPath.row == 0) { // 第一行
                normalBgView.frame = UIEdgeInsetsInsetRect(bounds, UIEdgeInsetsMake(-5, 0, 0, 0));
                CGRect rect = UIEdgeInsetsInsetRect(bounds, UIEdgeInsetsMake(5, 0, 0, 0));
                // 每组第一行（添加左上和右上的圆角）
                bezierPath = [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:(UIRectCornerTopLeft|UIRectCornerTopRight) cornerRadii:CGSizeMake(radius, radius)];
            }else if (indexPath.row == rowNum - 1) {
                normalBgView.frame = UIEdgeInsetsInsetRect(bounds, UIEdgeInsetsMake(0, 0, -5, 0));
                CGRect rect = UIEdgeInsetsInsetRect(bounds, UIEdgeInsetsMake(0, 0, 5, 0));
                // 每组最后一行（添加左下和右下的圆角）
                bezierPath = [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:(UIRectCornerBottomLeft|UIRectCornerBottomRight) cornerRadii:CGSizeMake(radius, radius)];
            }else {
                // 每组不是首位的行不设置圆角
                bezierPath = [UIBezierPath bezierPathWithRect:bounds];
            }
        }
        
        // 阴影
        //        if (indexPath.section != 2) {
        //            normalLayer.shadowColor = UIColorRGB(0x004080).CGColor;
        //            normalLayer.shadowOpacity = 0.04;
        //            normalLayer.shadowOffset = CGSizeMake(0, 5);
        //            normalLayer.path = bezierPath.CGPath;
        //            normalLayer.shadowPath = bezierPath.CGPath;
        //
        //        }
        
        
        // 把已经绘制好的贝塞尔曲线路径赋值给图层，然后图层根据path进行图像渲染render
        normalLayer.path = bezierPath.CGPath;
        selectLayer.path = bezierPath.CGPath;
        
        // 设置填充颜色
        normalLayer.fillColor = [UIColor whiteColor].CGColor;
        normalLayer.strokeColor = [UIColor whiteColor].CGColor;
        
        // 添加图层到nomarBgView中
        [normalBgView.layer insertSublayer:normalLayer atIndex:0];
        normalBgView.backgroundColor = UIColor.clearColor;
        cell.backgroundView = normalBgView;
        
        // 替换cell点击效果
        UIView *selectBgView = [[UIView alloc] initWithFrame:bounds];
        selectLayer.fillColor = [UIColor colorWithWhite:0.95 alpha:1.0].CGColor;
        [selectBgView.layer insertSublayer:selectLayer atIndex:0];
        selectBgView.backgroundColor = UIColor.clearColor;
        cell.selectedBackgroundView = selectBgView;
    }
}


+ (void)initIQKeyboardManager
{
    // 使用智能键盘
    IQKeyboardManager *manager = [IQKeyboardManager sharedManager];
    // 控制整个功能是否启用
    manager.enable = YES;
    // 控制是否显示键盘上的自动工具条,当需要支持内联编辑(Inline Editing), 这就需要隐藏键盘上的工具条(默认打开)
    manager.enableAutoToolbar = YES;
    //        manager.toolbarDoneBarButtonItemText = @"完成";
    
    // 启用手势触摸:控制点击背景是否收起键盘。
    manager.shouldResignOnTouchOutside = YES;
    // 是否显示提示文字
    manager.shouldShowToolbarPlaceholder = YES;
    // 控制键盘上的工具条文字颜色是否用户自定义,(使用TextField的tintColor属性IQToolbar，否则色调的颜色是黑色 )
    manager.shouldToolbarUsesTextFieldTintColor = YES;
    
}


@end


