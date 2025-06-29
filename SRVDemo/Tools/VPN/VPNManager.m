//
//  VPNManager.m
//  SRVDemo
//
//  Created by yyf on 2025/6/29.
//

#import "VPNManager.h"
#import "SRVDemo-Swift.h" // 主应用的Swift桥接头文件

@interface VPNManager ()
@property (nonatomic, copy) void (^statusHandler)(VPNStatus status);
@end

@implementation VPNManager

+ (instancetype)shared {
    static VPNManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[VPNManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[VPNConfigManager shared] addStatusObserverWithCompletion:^(NSInteger status) {
            VPNStatus vpnStatus = (VPNStatus)status;
            
            // 记录详细状态
            NSLog(@"[VPN] 状态变更: %ld", (long)vpnStatus);
            
            if (self.statusHandler) {
                self.statusHandler(vpnStatus);
            }
            
            // 将状态传递到 ViewController
            [[NSNotificationCenter defaultCenter]
                postNotificationName:@"VPNStatusChanged"
                object:nil
                userInfo:@{@"status": @(vpnStatus)}];
        }];
    }
    return self;
}

- (void)startVPNWithServer:(NSString *)server
                      port:(NSInteger)port
              protocolType:(NSString *)protocolType
                  password:(NSString *)password
                    method:(nullable NSString *)method
                completion:(void (^)(NSError * _Nullable))completion {
    
    // 记录启动参数
    NSLog(@"[VPN] 启动连接 - 服务器: %@:%ld, 协议: %@, 方法: %@",
          server, (long)port, protocolType, method ?: @"N/A");
    
    // 设置超时计时器 (15秒)
    __block BOOL completed = NO;
    __block BOOL timeoutOccurred = NO;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!completed) {
            timeoutOccurred = YES;
            completed = YES;
            NSError *timeoutError = [NSError errorWithDomain:@"VPN"
                                                        code:504
                                                    userInfo:@{NSLocalizedDescriptionKey: @"连接超时"}];
            NSLog(@"[VPN] 连接超时");
            completion(timeoutError);
        }
    });
    
    // 启动VPN
    [[VPNConfigManager shared] startVPNWithServer:server
                                            port:port
                                    protocolType:protocolType
                                        password:password
                                          method:method
                                      completion:^(NSError * _Nullable error) {
        if (!completed) {
            completed = YES;
            
            if (timeoutOccurred) {
                NSLog(@"[VPN] 连接完成但已超时");
                return;
            }
            
            if (error) {
                NSLog(@"[VPNManager] 启动失败: %@", error.localizedDescription);
            } else {
                NSLog(@"[VPNManager] 启动命令已成功发送到系统");
            }
            completion(error);
        }
    }];
}

- (void)stopVPNWithCompletion:(void (^)(NSError * _Nullable))completion {
    NSLog(@"[VPN] 停止连接");
    self.disconnectReason = VPNDisconnectReasonUserInitiated;
    [[VPNConfigManager shared] stopVPNWithCompletion:completion];
}

- (void)handleVPNStatusChange:(NSNotification *)notification {
    VPNStatus status = (VPNStatus)[notification.userInfo[@"status"] integerValue];
    
    // 记录状态转换
    NSLog(@"[VPN] 状态变更: %ld", (long)status);
    
    // 处理断开情况
    if (status == VPNStatusDisconnected) {
        NSLog(@"[VPN] 连接已断开，原因: %ld", (long)self.disconnectReason);
        
        // 重置断开原因
        VPNDisconnectReason reason = self.disconnectReason;
        self.disconnectReason = VPNDisconnectReasonUnknown;
        
        // 将断开原因传递到 ViewController
        [[NSNotificationCenter defaultCenter]
            postNotificationName:@"VPNDisconnected"
            object:nil
            userInfo:@{@"reason": @(reason)}];
    }
    
    if (self.statusHandler) {
        self.statusHandler(status);
    }
}
- (VPNStatus)currentStatus {
    return (VPNStatus)[[VPNConfigManager shared] getVPNStatus];
}

- (void)observeStatusChange:(void (^)(VPNStatus))statusHandler {
    self.statusHandler = statusHandler;
}

// 新增清理方法
- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}
@end
