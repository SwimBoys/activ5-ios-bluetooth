#
# Be sure to run `pod lib lint Activ5-Device.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Activ5Device'
  s.version          = '1.0.0'
  s.summary          = 'Framework used for connection with Activ5 Device'
  s.swift_version    = '4.2'
  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  
  s.description      = <<-DESC
  TODO: Add long description of the pod here.
  DESC
  
  s.homepage         = 'https://github.com/ActivBody/activ5-ios-bluetooth.git'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'martinkey' => 'martinkuvandzhiev@gmail.com' }
  s.source           = { :git => 'https://github.com/ActivBody/activ5-ios-bluetooth.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  
  s.platform          = :ios, '10.0'
  s.platform          = :tvos, '10.0'
  s.ios.deployment_target = '10.0'
  s.tvos.deployment_target = '10.0'

  s.source_files = 'Sources/**/*.swift'
#  s.vendored_frameworks = 'Activ5Device'
  # s.resource_bundles = {
  #   'Activ5-Device' => ['Activ5-Device/Assets/*.png']
  # }
  
  # s.public_header_files = 'Pod/Classes/**/*.h'
   s.framework = 'CoreBluetooth', 'Foundation'
end
