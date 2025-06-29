//
//  VPNManager.h
//  SRVDemo
//
//  Created by yyf on 2025/6/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, VPNStatus) {
    VPNStatusInvalid = 0,
    VPNStatusDisconnected = 1,
    VPNStatusConnecting = 2,
    VPNStatusConnected = 3,
    VPNStatusReasserting = 4,
    VPNStatusDisconnecting = 5
};
@interface VPNManager : NSObject
+ (instancetype)shared;

- (void)startVPNWithServer:(NSString *)server
                     port:(NSInteger)port
             protocolType:(NSString *)protocolType
                 password:(NSString *)password
                   method:(nullable NSString *)method
               completion:(void (^)(NSError * _Nullable error))completion;

- (void)stopVPNWithCompletion:(void (^)(NSError * _Nullable error))completion;

- (VPNStatus)currentStatus;

- (void)observeStatusChange:(void (^)(VPNStatus status))statusHandler;
@end

NS_ASSUME_NONNULL_END
