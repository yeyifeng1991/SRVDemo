platform :ios, '12.0'
use_frameworks! :linkage => :static

# 添加 Shadowsocks 的私有仓库源（如果需要）
# source 'https://github.com/shadowsocks/Specs.git'

def shared_pods
  pod 'CocoaAsyncSocket', '~> 7.6.5'
  pod 'CryptoSwift', '~> 1.5.1'
end

target 'SRVDemo' do
  shared_pods
  pod 'NEKit', :modular_headers => true
  
  pod 'AFNetworking'
  pod 'IQKeyboardManager'
  pod 'SDWebImage'
  pod 'YYModel'
  pod 'Masonry', '1.1.0'
  pod 'Bugly', '2.5.0'
  pod 'MJRefresh'
end

target 'PacketTunnel' do
  shared_pods
  # 直接从 GitHub 安装 Shadowsocks
  pod 'Shadowsocks-iOS', :git => 'https://github.com/shadowsocks/shadowsocks-iOS.git', :tag => '2.6.3'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      
      # 为必要的库启用模块化支持
      if ['NEKit', 'Shadowsocks-iOS', 'CocoaAsyncSocket'].include?(target.name)
        config.build_settings['DEFINES_MODULE'] = 'YES'
      end
    end
  end
  
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      if target.name == 'PacketTunnel'
        target.build_configurations.each do |config|
          config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
          config.build_settings['STRIP_INSTALLED_PRODUCT'] = 'YES'
          config.build_settings['OTHER_LDFLAGS'] = '$(inherited) -framework "NetworkExtension"'
          
          # Shadowsocks 必需的预处理器定义
          config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
          config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'SS_LOCAL=1'
          
          # 确保包含正确的头文件搜索路径
          config.build_settings['HEADER_SEARCH_PATHS'] ||= '$(inherited)'
          config.build_settings['HEADER_SEARCH_PATHS'] << '"${PODS_ROOT}/Shadowsocks-iOS/Shadowsocks_iOS"'
        end
      end
    end
  end
end