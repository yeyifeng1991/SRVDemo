//
//  VPNManager.m
//  SRVDemo
//
//  Created by yyf on 2025/6/29.
//

#import "VPNManager.h"
#import "SRVDemo-Swift.h"
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
    
    [[VPNConfigManager shared] startVPNWithServer:server
                                            port:port
                                    protocolType:protocolType
                                        password:password
                                          method:method
                                      completion:completion];
}

- (void)stopVPNWithCompletion:(void (^)(NSError * _Nullable))completion {
    [[VPNConfigManager shared] stopVPNWithCompletion:completion];
}

- (VPNStatus)currentStatus {
    return (VPNStatus)[[VPNConfigManager shared] getVPNStatus];
}

- (void)observeStatusChange:(void (^)(VPNStatus))statusHandler {
    self.statusHandler = statusHandler;
}

@end
