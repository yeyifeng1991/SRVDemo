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
        // 添加状态监听
        [[VPNConfigManager shared] addStatusObserverWithCompletion:^(NSInteger status) {
            if (self.statusHandler) {
                self.statusHandler((VPNStatus)status);
            }
            
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
                NSLog(@"[VPN] 启动失败: %@", error.localizedDescription);
            } else {
                NSLog(@"[VPN] 启动成功");
            }
            completion(error);
        }
    }];
}

- (void)stopVPNWithCompletion:(void (^)(NSError * _Nullable))completion {
    NSLog(@"[VPN] 停止连接");
    [[VPNConfigManager shared] stopVPNWithCompletion:completion];
}

- (VPNStatus)currentStatus {
    return (VPNStatus)[[VPNConfigManager shared] getVPNStatus];
}

- (void)observeStatusChange:(void (^)(VPNStatus))statusHandler {
    self.statusHandler = statusHandler;
}

@end
