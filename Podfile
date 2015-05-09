plugin 'cocoapods-keys', {
  :project => 'WatchButton',
  :keys => [
    'PayPalSandboxClientId',
    'PayPalSandboxClientSecret',
    'SphereIOClientId',
    'SphereIOClientSecret'
]}

inhibit_all_warnings!
use_frameworks!

link_with 'WatchButton'

pod 'Alamofire'
pod 'KeychainAccess'
pod 'MMWormhole'
pod 'PayPal-iOS-SDK'
pod 'Result'

target 'WatchButton WatchKit Extension', :exclusive => true do

pod 'Alamofire'
pod 'ContentfulDeliveryAPI'
pod 'MMWormhole'
pod 'Result'

end

# Because AFNetworking internally uses `sharedApplication`
post_install do |installer|
  installer.project.targets.each do |target|
    target.build_configurations.each do |config|
    	config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'NO'
    end
  end
end
