platform :ios, '13.0'
use_frameworks! :linkage => :static

def shared_pods
  pod 'CocoaAsyncSocket', '~> 7.6.5'
  pod 'CryptoSwift', '~> 1.5.1'
#  pod 'NEKit', :git => 'https://github.com/zhuhaow/NEKit.git', :tag => '0.15.0'
  pod 'NEKit', :modular_headers => true


end

target 'SRVDemo' do
  shared_pods
  pod 'AFNetworking'
  pod 'IQKeyboardManager'
  pod 'SDWebImage'
  pod 'YYModel'
  pod 'Masonry', '1.1.0'
  pod 'Bugly', '2.5.0'
  pod 'MJRefresh'
  pod 'SwiftNIO', '~> 2.0'
end

target 'PacketTunnel' do
  shared_pods
  pod 'SwiftNIOExtras', '~> 1.0'
  pod 'SwiftNIOTransportServices', '~> 1.0'
end

post_install do |installer|
  # 禁用所有目标的 Bitcode
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      
      # 为必要库启用模块化
      if ['NEKit', 'CocoaAsyncSocket', 'CryptoSwift'].include?(target.name)
        config.build_settings['DEFINES_MODULE'] = 'YES'
      end
      
      # 统一设置 Swift 5.0
      if ['NEKit', 'CryptoSwift'].include?(target.name)
        config.build_settings['SWIFT_VERSION'] = '5.0'
        config.build_settings['OTHER_SWIFT_FLAGS'] = '$(inherited) -swift-version 5'
      end
    end
  end
  
  # 隧道扩展特殊配置
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      if target.name == 'PacketTunnel'
        target.build_configurations.each do |config|
          config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
          config.build_settings['STRIP_INSTALLED_PRODUCT'] = 'YES'
          config.build_settings['OTHER_LDFLAGS'] = '$(inherited) -framework "NetworkExtension" -framework "Security" -framework "Foundation"'
          
          config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
          config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'SS_LOCAL=1'
          config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'NETWORK_EXTENSION=1'
          
          # 仅调试模式禁用优化
          if config.name == "Debug"
            config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
          end
        end
      end
    end
  end
end
