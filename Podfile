source 'https://github.com/contentful/CocoaPodsSpecs'
source 'https://github.com/CocoaPods/Specs'

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

def shared_pods

pod 'Cube', :git => 'https://github.com/contentful-labs/Cube.git'
#pod 'Cube', :path => '../Cube'
pod 'MMWormhole'

end

link_with 'WatchButton'

shared_pods

pod 'Alamofire', '~> 2.0'
#pod 'ContentfulDeliveryAPI', :path => '../contentful-delivery-api'
pod 'Form', :head
pod 'KeychainAccess', :git => 'https://github.com/kishikawakatsumi/KeychainAccess.git'
pod 'MBProgressHUD'
pod 'PayPal-iOS-SDK'
pod 'Result', '>= 0.6-beta.1'

target 'WatchButton WatchKit Extension', :exclusive => true do

platform :watchos, '2.0'

shared_pods

end
