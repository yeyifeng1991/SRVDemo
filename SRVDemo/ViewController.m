//
//  ViewController.m
//  SRVDemo
//
//  Created by yyf on 2025/6/16.
//

#import "ViewController.h"
#import "YAMLParser.h"
#import "ClashProxyModel.h"
#import <NetworkExtension/NetworkExtension.h>
#import <Masonry/Masonry.h>
#import <NEKit/NEKit-Swift.h>
#import "SRVDemo-Swift.h"
#import "SRVpnTableCell.h"
#import "VPNManager.h"
#import "MBProgressHUD+TK_WeRecord.h"


@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic,strong) UITableView  * tableView ;

@property (nonatomic,strong) UIButton  * startVpnBtn ;
@property (nonatomic,strong) UIButton  * disconnectVpnBtn ;


@property (nonatomic, strong) NEKitProxyWrapper *proxyWrapper;
@property (nonatomic,strong) NSArray <ClashProxyModel*> * proxyArray ;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self fetchSubscriptionAsync];
    [self setUI];
 
    // 创建 Shadowsocks 配置
//    NEKitProxyWrapper *proxyWrapper = [[NEKitProxyWrapper alloc] init];
  

}
- (void)setUI{
    
//    UIButton * startVpnBtn = [[UIButton alloc]init];
//    [startVpnBtn setTitle:@"开始连接" forState:UIControlStateNormal];
//    [startVpnBtn addTarget:self action:@selector(startConnect) forControlEvents:UIControlEventTouchUpInside];
//    [startVpnBtn setBackgroundColor:[UIColor blueColor]];
//    [startVpnBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [self.view addSubview:startVpnBtn];
//    self.startVpnBtn = startVpnBtn;
//    [self.startVpnBtn mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.centerX.mas_equalTo(self.view);
//        make.bottom.mas_equalTo(self.view.mas_centerY).offset(-10);
//        make.size.mas_equalTo(CGSizeMake(200, 40));
//    }];
//    
//    UIButton * disconnectBtn = [[UIButton alloc]init];
//    [disconnectBtn setTitle:@"断开连接" forState:UIControlStateNormal];
//    [disconnectBtn addTarget:self action:@selector(startConnect) forControlEvents:UIControlEventTouchUpInside];
//    [disconnectBtn setBackgroundColor:[UIColor redColor]];
//    [disconnectBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [self.view addSubview:disconnectBtn];
//    [disconnectBtn mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.centerX.mas_equalTo(self.view);
//        make.top.mas_equalTo(self.view.mas_centerY).offset(10);
//        make.size.mas_equalTo(CGSizeMake(200, 40));
//    }];
//    self.disconnectVpnBtn = disconnectBtn;
    
    // 初始化 tableView
   self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
   self.tableView.dataSource = self;
   self.tableView.delegate = self;
   // 注册自定义 cell
   [self.tableView registerClass:[SRVpnTableCell class] forCellReuseIdentifier:NSStringFromClass([SRVpnTableCell class])];
   [self.view addSubview:self.tableView];
    
    
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.proxyArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SRVpnTableCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SRVpnTableCell class]) forIndexPath:indexPath];
    cell.proxyModel = self.proxyArray[indexPath.row];
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 70;
}

#pragma mark - UITableViewDelegate

// 处理 cell 点击事件（这里主要依靠 setSelected 方法处理左侧圆圈显示，也可在此做更多自定义逻辑）
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ClashProxyModel * model = self.proxyArray[indexPath.row];
    self.proxyWrapper = [[NEKitProxyWrapper alloc] init];
    
    // 从订阅数据中提取 Shadowsocks 配置
    NSString *serverAddress = model.server; // 从订阅数据中获取
    UInt16 port = model.port; // 从订阅数据中获取
    NSString *password = model.password; // 从订阅数据中获取
    NSString *encryption = model.cipher; // 从订阅数据中获取
    NSLog(@"model.server:%@\n port:%ld\n password:%@\n encryption: %@ \n %ld",serverAddress,model.port,password,encryption,model.type);
    // 检查协议类型
      if (model.type != ClashProxyTypeTrojan &&
          model.type != ClashProxyTypeSS) {
          NSLog(@"不支持的协议类型: %ld", model.type);
          return;
      }
    NSString * protocol = model.type == ClashProxyTypeTrojan?@"trogan":@"ss";
    // 调用VPN管理器
       [[VPNManager shared] startVPNWithServer:serverAddress
                                         port:port
                                 protocolType:protocol
                                     password:password
                                       method:encryption
                                   completion:^(NSError * _Nullable error) {
           if (error) {
               NSLog(@"VPN启动失败: %@", error.localizedDescription);
               // 显示错误提示
               [self showErrorAlert:error.localizedDescription];
           } else {
               NSLog(@"VPN启动成功");
               // 更新UI显示连接状态
               [self updateConnectionUI];
           }
       }];
    /**
     旧逻辑
     // 尝试多次启动
     for (int i = 0; i < 3; i++) {
         [self.proxyWrapper setupShadowSocksProxyWithServerAddress:serverAddress
                                                             port:port
                                                         password:password
                                                       encryption:encryption];
         
         NSError *error = nil;
         [self.proxyWrapper startProxyAndReturnError:&error];
         
         if (!error) {
             NSLog(@"✅ VPN 成功启动 (尝试 %d)", i+1);
             model.connectType = ClashConnectSuccess;
             break;
         }
         
         NSLog(@"⚠️ 启动失败 (尝试 %d): %@", i+1, error.localizedDescription);
         [NSThread sleepForTimeInterval:0.5]; // 等待0.5秒后重试
     }

     if (model.connectType != ClashConnectSuccess) {
         NSLog(@"❌ VPN 启动失败");
         model.connectType = ClashConnectFail;
     }
     
     */
    
}
- (void)showErrorAlert:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"VPN错误"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                                  style:UIAlertActionStyleDefault
                                                handler:nil]];
        
        // 获取当前视图控制器并显示弹窗
        UIViewController *topVC = [self topViewController];
        [topVC presentViewController:alert animated:YES completion:nil];
    });
}

- (UIViewController *)topViewController {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    UIViewController *vc = keyWindow.rootViewController;
    while (vc.presentedViewController) {
        vc = vc.presentedViewController;
    }
    return vc;
}

- (void)updateConnectionUI {
    // 更新UI显示连接状态
    dispatch_async(dispatch_get_main_queue(), ^{
        VPNStatus status = [[VPNManager shared] currentStatus];
        NSString *statusText = @"";
        
        switch (status) {
            case VPNStatusConnecting:
                statusText = @"连接中...";
                break;
            case VPNStatusConnected:
                statusText = @"已连接";
                break;
            case VPNStatusDisconnecting:
                statusText = @"断开中...";
                break;
            case VPNStatusDisconnected:
                statusText = @"已断开";
                break;
            default:
                statusText = @"未知状态";
                break;
        }
        NSLog(@"[VPN]%@",statusText);
        
        [MBProgressHUD showMessage:statusText];
    });
}
// 开始链接
- (void)startConnect{
    NSLog(@"xh开始链接");
    [self startSSVPN];
    
}

// 断开链接
- (void)disConnect{
    NSLog(@"xh断开链接");
}
- (void)fetchSubscriptionAsync {
    NSURL *url = [NSURL URLWithString:@"http://subscribe.ayouran.com/cc60f6fe9d774792b031665496911234/subscribe"];
    
    // 创建配置（解决ATS问题）
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
    // 创建会话
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    // 创建数据任务
    NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"请求失败: %@", error);
            return;
        }
    
        NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        // 回到主线程更新UI
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleSubscriptionContent:content];
        });
    }];
    
    // 启动任务
    [task resume];
}
- (void)handleSubscriptionContent:(NSString *)content {
    // 后台线程解析YAML（如果是耗时操作）
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *configDict = [YAMLParser parseYAMLFromString:content];
        ClashConfigModel *config = [ClashConfigModel modelWithDictionary:configDict];
        self.proxyArray = config.proxies;
    dispatch_async(dispatch_get_main_queue(), ^{
          [self.tableView reloadData];
        });
    });
}





// MARK: - 配置vpn IKEv协议

- (void)setupVPNManager {
    NEVPNManager *vpnManager = [NEVPNManager sharedManager];
    
    [vpnManager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error loading VPN preferences: %@", error.localizedDescription);
        } else {
            NSLog(@"VPN preferences loaded successfully.");
            // 初始化协议配置
            NEVPNProtocolIKEv2 *protocol = [[NEVPNProtocolIKEv2 alloc] init];
            protocol.serverAddress = @"example.com"; // 替换为实际的服务器地址
            protocol.remoteIdentifier = @"example.com"; // 替换为实际的标识符 用于验证身份
            protocol.localIdentifier = @""; // 本地标识符
            protocol.username = @"username"; // 替换为实际的用户名
            protocol.passwordReference = [self createPasswordReference:@"password"]; // 密码的 Keychain 数据引用（安全存储)
            protocol.authenticationMethod = NEVPNIKEAuthenticationMethodSharedSecret; // 认证方法
            protocol.useExtendedAuthentication = YES; // 是否使用扩展认证
            protocol.disconnectOnSleep = NO;

            vpnManager.protocolConfiguration = protocol;
            vpnManager.localizedDescription = @"My Custom VPN";
            vpnManager.enabled = YES;

            [vpnManager saveToPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                if (error) {
                    NSLog(@"tk Error saving VPN preferences: %@", error.localizedDescription);
                } else {
                    NSLog(@"tk VPN preferences saved successfully.");
                }
            }];
        }
    }];
}

- (NSData *)createPasswordReference:(NSString *)password {
    NSDictionary *attributes = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: @"VPNService",
        (__bridge id)kSecValueData: [password dataUsingEncoding:NSUTF8StringEncoding],
    };

    CFTypeRef result = NULL;
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)attributes, &result);
    if (status == errSecSuccess || status == errSecDuplicateItem) {
        // 查询已存储的密码引用
        NSDictionary *query = @{
            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
            (__bridge id)kSecAttrService: @"VPNService",
            (__bridge id)kSecReturnData: @YES,
        };

        CFTypeRef passwordDataRef = NULL;
        if (SecItemCopyMatching((__bridge CFDictionaryRef)query, &passwordDataRef) == errSecSuccess) {
            NSData *passwordData = (__bridge_transfer NSData *)passwordDataRef;
            return passwordData;
        }
    }
    return nil;
}

- (void)connectIKEVPN {
    [[NEVPNManager sharedManager].connection startVPNTunnelAndReturnError:nil];
}

- (void)disconnectIKEVPN {
    [[NEVPNManager sharedManager].connection stopVPNTunnel];
}

- (void)startSSVPN {
    NSError *error = nil;
    [self.proxyWrapper startProxyAndReturnError:&error];
    if (error) {
        NSLog(@"启动 VPN 失败: %@", error.localizedDescription);
    } else {
        NSLog(@"VPN 已启动");
    }
}

// 停止 VPN
- (void)stopSSVPN:(id)sender {
    [self.proxyWrapper stopProxy];
    NSLog(@"VPN 已停止");
}

@end
