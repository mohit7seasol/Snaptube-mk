# Uncomment the next line to define a global platform for your project
# platform :ios, '15.0'

target 'Snaptube_Mk' do
  # Comment the next line if you don't want to use dynamic frameworks

  pod 'Alamofire'
  pod "SwiftyJSON"
  pod 'SVProgressHUD'
  pod 'SwiftyStoreKit'
  pod 'Firebase/Analytics'
  pod 'Firebase/RemoteConfig'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Performance'
  pod 'Google-Mobile-Ads-SDK'
  pod 'MBProgressHUD'
  pod 'AWSMobileClient', '~> 2.6.13'
  pod 'AWSS3'
  pod "SkeletonView"
  pod 'NVActivityIndicatorView'
  pod 'Cosmos', '~> 25.0'
  pod 'iOSDropDown'
  pod 'IQKeyboardManagerSwift'
  pod 'lottie-ios'
  pod 'SDWebImage', '~> 5.0'
  pod 'SVProgressHUD'
  pod 'TagListView', '~> 1.0'
  pod 'ReachabilitySwift'
  pod 'Mantis'
  pod 'ZLImageEditor'
  
  use_frameworks!

  # Pods for Snaptube_Mk

end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      end
    end
  end
end
