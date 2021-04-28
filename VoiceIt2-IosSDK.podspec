#
#  Created by VoiceIt Technologies, LLC
#  Copyright © 2020 VoiceIt Technologies LLC. All rights reserved.
#
# Be sure to run `pod lib lint VoiceIt2-IosSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
s.name             = 'VoiceIt2-IosSDK'
s.version          = '2.2.6'
s.summary          = 'A pod that lets you add voice and face verification and identification to your iOS apps, brought to you by VoiceIt.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

s.description      = 'A pod that lets you add voice and face verification and identification to your iOS apps, brought to you by VoiceIt. Now also with basic liveness detection challenges. Please visit https://voiceit.io to learn more and sign up for an account.'
s.homepage         = 'https://github.com/voiceittech/VoiceIt2-IosSDK'
s.license          = { :type => 'MIT', :file => 'LICENSE' }
s.author           = { 'voiceit' => 'support@voiceit.io' }
s.source           = { :git => 'https://github.com/voiceittech/VoiceIt2-IosSDK.git', :tag => s.version.to_s }

s.ios.deployment_target = '11.0'
s.static_framework = true
s.source_files = 'VoiceIt2-IosSDK/Classes/**/*.{h,m}','VoiceIt2-IosSDK/Assets/**/*.{wav}'

s.resource_bundles = {
  'VoiceIt2-IosSDK' => ['VoiceIt2-IosSDK/Classes/**/*.{lproj,storyboard,xib,xcassets,strings}','VoiceIt2-IosSDK/Assets/**/*.{wav}']
}

s.frameworks = 'UIKit', 'AVFoundation'

end
