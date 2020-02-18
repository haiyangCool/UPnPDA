#
# Be sure to run `pod lib lint UPnPDA.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'UPnPDA'
  s.version          = '1.0.0'
  s.summary          = 'UPnPDA is a UPnP Device Search And Control Tools'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
UPnPDA is a Tools to search aim service(Device),you can use it to search the Device(includes the aim Searvice),And it supported a AVTransport to Control device (DLNA Mode), setAVTransportURI , invoke play 、pause、stop ... actions.
                       DESC

  s.homepage         = 'https://github.com/haiyangCool/UPnPDA'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'haiyangCool' => 'haiyang_wang_cool@126.com' }
  s.source           = { :git => 'https://github.com/haiyangCool/UPnPDA.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'UPnPDA/Classes/**/*'
  
  # s.resource_bundles = {
  #   'UPnPDA' => ['UPnPDA/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'AEXML'
  s.dependency 'CocoaAsyncSocket'
end
