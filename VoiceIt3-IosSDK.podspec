#
#  Created by VoiceIt Technologies, LLC
#  Copyright © 2020 VoiceIt Technologies LLC. All rights reserved.
#
# Be sure to run `pod lib lint VoiceIt3-IosSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
s.name             = 'VoiceIt3-IosSDK'
s.version          = '3.0.0'
s.summary          = 'A pod that lets you add voice and face verification and identification to your iOS apps, brought to you by VoiceIt.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

s.description      = 'A pod that lets you add voice and face verification and identification to your iOS apps, brought to you by VoiceIt. Please visit https://voiceit.io to learn more and sign up for an account.'
s.homepage         = 'https://github.com/voiceittech/VoiceIt3-IosSDK'
s.license          = { :type => 'MIT', :file => 'LICENSE' }
s.author           = { 'voiceit' => 'support@voiceit.io' }
s.source           = { :git => 'https://github.com/voiceittech/VoiceIt3-IosSDK.git', :tag => s.version.to_s }

s.ios.deployment_target = '11.0'
s.static_framework = true
s.source_files = 'VoiceIt3-IosSDK/Classes/**/*.{h,m}','VoiceIt3-IosSDK/Assets/**/*.{wav}'

s.resource_bundles = {
  'VoiceIt3-IosSDK' => ['VoiceIt3-IosSDK/Classes/**/*.{lproj,storyboard,xib,xcassets,strings}','VoiceIt3-IosSDK/Assets/**/*.{wav}']
}

s.frameworks = 'UIKit', 'AVFoundation'

end
