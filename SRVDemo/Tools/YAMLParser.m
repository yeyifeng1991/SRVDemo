//
//  YAMLParser.m
//  SRVDemo
//
//  Created by yyf on 2025/6/17.
//

#import "YAMLParser.h"
#import "yaml.h"

@implementation YAMLParser

+ (NSDictionary *)parseYAMLFromURL:(NSURL *)url {
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSString *yamlString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return [self parseYAMLFromString:yamlString];
}

+ (NSDictionary *)parseYAMLFromString:(NSString *)yamlString {
    yaml_parser_t parser;
    yaml_event_t event;
    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSMutableArray *currentArray = nil;
    NSString *currentKey = nil;
    NSMutableDictionary *currentDict = nil;
    NSMutableArray *proxyArray = [NSMutableArray array];
    
    // 初始化解析器
    yaml_parser_initialize(&parser);
    const char *input = [yamlString UTF8String];
    yaml_parser_set_input_string(&parser, (const unsigned char *)input, strlen(input));
    
    int done = 0;
    while (!done) {
        if (!yaml_parser_parse(&parser, &event)) {
            NSLog(@"Parser error %d\n", parser.error);
            break;
        }
        
        switch (event.type) {
            case YAML_SCALAR_EVENT: {
                NSString *value = [[NSString alloc] initWithUTF8String:(const char *)event.data.scalar.value];
                
                if (!currentKey) {
                    currentKey = value;
                } else {
                    if (currentDict) {
                        currentDict[currentKey] = value;
                        currentKey = nil;
                    } else if ([currentKey isEqualToString:@"proxies"] && [value isEqualToString:@"-"]) {
                        // 开始新的代理项
                        currentDict = [NSMutableDictionary dictionary];
                        [proxyArray addObject:currentDict];
                    } else {
                        if (currentArray) {
                            [currentArray addObject:value];
                        } else {
                            result[currentKey] = value;
                            currentKey = nil;
                        }
                    }
                }
                break;
            }
            case YAML_MAPPING_START_EVENT:
                if ([currentKey isEqualToString:@"proxies"]) {
                    // 代理列表开始
                    currentArray = proxyArray;
                } else if (currentKey) {
                    currentDict = [NSMutableDictionary dictionary];
                }
                break;
            case YAML_MAPPING_END_EVENT:
                if (currentDict) {
                    currentDict = nil;
                }
                break;
            case YAML_SEQUENCE_START_EVENT:
                currentArray = [NSMutableArray array];
                break;
            case YAML_SEQUENCE_END_EVENT:
                if (currentKey && currentArray) {
                    result[currentKey] = currentArray;
                    currentKey = nil;
                    currentArray = nil;
                }
                break;
            case YAML_DOCUMENT_END_EVENT:
                done = 1;
                break;
            default:
                break;
        }
        
        yaml_event_delete(&event);
    }
    
    yaml_parser_delete(&parser);
    
    // 将代理数组添加到最终结果
    if (proxyArray.count > 0) {
        result[@"proxies"] = proxyArray;
    }
    
    return result;
}

@end
