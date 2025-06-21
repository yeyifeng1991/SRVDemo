//
//  ClashProxyModel.m
//  SRVDemo
//
//  Created by yyf on 2025/6/17.
//

#import "ClashProxyModel.h"
#import <YYModel/YYModel.h>

@implementation ClashProxyModel


+ (NSArray<ClashProxyModel *> *)parseFromArray:(NSArray *)array {
    NSMutableArray *result = [NSMutableArray array];
    ClashProxyModel *currentProxy = nil;
    NSString *currentKey = nil;
    
    for (id item in array) {
        if ([item isKindOfClass:[NSString class]]) {
            NSString *stringItem = (NSString *)item;
            
            // 检查是否是键名
            if ([stringItem isEqualToString:@"name"] ||
                [stringItem isEqualToString:@"type"] ||
                [stringItem isEqualToString:@"server"] ||
                [stringItem isEqualToString:@"port"] ||
                [stringItem isEqualToString:@"cipher"] ||
                [stringItem isEqualToString:@"password"] ||
                [stringItem isEqualToString:@"udp"] ||
                [stringItem isEqualToString:@"sni"] ||
                [stringItem isEqualToString:@"skip-cert-verify"]) {
                
                currentKey = stringItem;
                
                // 如果遇到新的name，表示开始新的代理
                if ([stringItem isEqualToString:@"name"] && currentProxy) {
                    [result addObject:currentProxy];
                    currentProxy = nil;
                }
            } else {
                // 这是值不是键
                if (!currentProxy) {
                    currentProxy = [[ClashProxyModel alloc] init];
                }
                
                if ([currentKey isEqualToString:@"name"]) {
                    currentProxy.name = stringItem;
                } else if ([currentKey isEqualToString:@"type"]) {
                    if ([stringItem isEqualToString:@"ss"]) {
                        currentProxy.type = ClashProxyTypeSS;
                    } else if ([stringItem isEqualToString:@"trojan"]) {
                        currentProxy.type = ClashProxyTypeTrojan;
                    } else {
                        currentProxy.type = ClashProxyTypeUnknown;
                    }
                } else if ([currentKey isEqualToString:@"server"]) {
                    currentProxy.server = stringItem;
                } else if ([currentKey isEqualToString:@"port"]) {
                    currentProxy.port = [stringItem integerValue];
                } else if ([currentKey isEqualToString:@"cipher"]) {
                    currentProxy.cipher = stringItem;
                } else if ([currentKey isEqualToString:@"password"]) {
                    currentProxy.password = stringItem;
                } else if ([currentKey isEqualToString:@"udp"]) {
                    currentProxy.udp = [stringItem boolValue];
                } else if ([currentKey isEqualToString:@"sni"]) {
                    currentProxy.sni = stringItem;
                } else if ([currentKey isEqualToString:@"skip-cert-verify"]) {
                    currentProxy.skipCertVerify = [stringItem boolValue];
                }
                
                currentKey = nil;
            }
        }
    }
    
    // 添加最后一个代理
    if (currentProxy) {
        [result addObject:currentProxy];
    }
    
    return result;
}

- (NSString *)description {
    NSMutableString *desc = [NSMutableString stringWithFormat:@"<%@: %p>\n", [self class], self];
    [desc appendFormat:@"name: %@\n", self.name ?: @"(null)"];
    [desc appendFormat:@"type: %ld\n", (long)self.type];
    [desc appendFormat:@"server: %@\n", self.server ?: @"(null)"];
    [desc appendFormat:@"port: %ld\n", (long)self.port];
    [desc appendFormat:@"cipher: %@\n", self.cipher ?: @"(null)"];
    [desc appendFormat:@"password: %@\n", self.password ?: @"(null)"];
    [desc appendFormat:@"udp: %d\n", self.udp];
    [desc appendFormat:@"sni: %@\n", self.sni ?: @"(null)"];
    [desc appendFormat:@"skipCertVerify: %d", self.skipCertVerify];
    return desc;
}
@end

@implementation ClashRuleProviderModel
@end

@implementation ClashConfigModel
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"socksPort": @"socks-port",
        @"allowLan": @"allow-lan",
        @"logLevel": @"log-level",
        @"externalController": @"external-controller",
        @"cfwLatencyTimeout": @"cfw-latency-timeout",
        @"cfwLatencyUrl": @"cfw-latency-url",
        @"dnsEnable": @"dns.enable",
        @"dnsIpv6": @"dns.ipv6",
        @"defaultNameserver": @"dns.default-nameserver",
        @"dnsUseHosts": @"dns.use-hosts",
        @"nameserver": @"dns.nameserver",
        @"fallback": @"dns.fallback",
        @"fakeIpFilter": @"dns.fake-ip-filter",
        @"ruleProviders": @"rule-providers"
    };
}

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dict {
    // 特殊处理 proxies 数组
    NSArray *proxiesArray = dict[@"proxies"];
    if ([proxiesArray isKindOfClass:[NSArray class]]) {
        _proxies = [ClashProxyModel parseFromArray:proxiesArray];
        NSLog(@"成功解析出 %lu 个代理", (unsigned long)_proxies.count);
        for (ClashProxyModel *proxy in _proxies) {
            NSLog(@"%@", proxy);
        }
    }
    return YES;
}
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{
        @"ruleProviders": [ClashRuleProviderModel class]
    };
}

+ (instancetype)modelWithDictionary:(NSDictionary *)dict {
    return [ClashConfigModel yy_modelWithDictionary:dict];
}
@end
