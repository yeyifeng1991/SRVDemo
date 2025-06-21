//
//  YAMLParser.h
//  SRVDemo
//
//  Created by yyf on 2025/6/17.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface YAMLParser : NSObject
+ (NSDictionary *)parseYAMLFromURL:(NSURL *)url;
+ (NSDictionary *)parseYAMLFromString:(NSString *)yamlString;

@end

NS_ASSUME_NONNULL_END
