//
//  SRVpnConfig.h
//  SRVDemo
//
//  Created by yyf on 2025/6/17.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSInteger, ClashProxyType) {
    ClashProxyTypeSS,
    ClashProxyTypeTrojan,
    ClashProxyTypeUnknown
};

typedef NS_ENUM(NSInteger, ClashConnectType) {
    ClashConnectDefault, // 默认连接
    ClashConnectFail, // 链接失败
    ClashConnectSuccess // 链接成功
};
NS_ASSUME_NONNULL_BEGIN

@interface ClashProxyModel : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) ClashProxyType type;
@property (nonatomic, copy) NSString *server;
@property (nonatomic, assign) NSInteger port;
@property (nonatomic, copy) NSString *cipher;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, assign) BOOL udp;
@property (nonatomic, copy) NSString *sni;
@property (nonatomic, assign) BOOL skipCertVerify;
@property (nonatomic,assign) ClashConnectType connectType ; // 是否连接


+ (NSArray<ClashProxyModel *> *)parseFromArray:(NSArray *)array;
- (NSString *)description;
@end

@interface ClashRuleProviderModel : NSObject
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *behavior;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, assign) NSInteger interval;
@end

@interface ClashConfigModel : NSObject
@property (nonatomic, assign) NSInteger port;
@property (nonatomic, assign) NSInteger socksPort;
@property (nonatomic, assign) BOOL allowLan;
@property (nonatomic, copy) NSString *mode;
@property (nonatomic, copy) NSString *logLevel;
@property (nonatomic, copy) NSString *secret;
@property (nonatomic, copy) NSString *externalController;
@property (nonatomic, assign) NSInteger cfwLatencyTimeout;
@property (nonatomic, copy) NSString *cfwLatencyUrl;

// DNS 配置
@property (nonatomic, assign) BOOL dnsEnable;
@property (nonatomic, assign) BOOL dnsIpv6;
@property (nonatomic, strong) NSArray<NSString *> *defaultNameserver;
@property (nonatomic, assign) BOOL dnsUseHosts;
@property (nonatomic, strong) NSArray<NSString *> *nameserver;
@property (nonatomic, strong) NSArray<NSString *> *fallback;
@property (nonatomic, strong) NSArray<NSString *> *fakeIpFilter;

// 代理和规则
@property (nonatomic, strong) NSArray<ClashProxyModel *> *proxies;
@property (nonatomic, strong) NSArray<NSString *> *rules;
@property (nonatomic, strong) NSDictionary<NSString *, ClashRuleProviderModel *> *ruleProviders;

+ (instancetype)modelWithDictionary:(NSDictionary *)dict;
@end

NS_ASSUME_NONNULL_END
