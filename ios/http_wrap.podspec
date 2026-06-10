#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint http_wrap.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'http_wrap'
  s.version          = '1.1.1'
  s.summary          = 'A Flutter plugin for wrapping HTTP requests and responses.'
  s.description      = <<-DESC
A Flutter plugin for wrapping HTTP requests and responses,
providing a unified interface for network communication.
                       DESC
  s.homepage         = 'https://github.com/rans-rans/http_wrap'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'rans-rans' => 'opensource@users.noreply.github.com' }
  s.source           = { :path => '.' }
  s.source_files = 'http_wrap/Sources/http_wrap/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'http_wrap_privacy' => ['http_wrap/Sources/http_wrap/PrivacyInfo.xcprivacy']}
end
