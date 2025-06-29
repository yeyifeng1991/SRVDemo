# Uncomment the next line to define a global platform for your project
 platform :ios, '12.0'
# 全局使用静态框架
use_frameworks! :linkage => :static

def shared_pods
  # 共享的依赖
  pod 'CocoaAsyncSocket', '~> 7.6.5'
  pod 'CryptoSwift', '~> 1.5.1'
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
end

target 'PacketTunnel' do
  # 只调用一次共享依赖
  shared_pods
  
  # 不再重复声明 NEKit
  
  # 通过 post_install 配置 BITCODE
end

# 添加配置钩子处理特殊设置
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # 为所有 target 禁用 BITCODE
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
  
  # 单独为 PacktTunnel target 配置
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      if target.name == 'PacktTunnel'
        target.build_configurations.each do |config|
          # 添加网络扩展专用配置
          config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
          config.build_settings['STRIP_INSTALLED_PRODUCT'] = 'YES'
          config.build_settings['OTHER_LDFLAGS'] = '$(inherited) -framework "NetworkExtension"'
        end
      end
    end
  end
end
