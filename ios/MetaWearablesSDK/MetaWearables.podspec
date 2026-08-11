Pod::Spec.new do |s|
  s.name             = 'MetaWearables'
  s.version          = '0.9.0'
  s.summary          = 'Meta Wearables Device Access Toolkit.'
  s.description      = 'Local pod wrapper for Meta Wearables SDK XCFrameworks.'
  s.homepage         = 'https://wearables.developer.meta.com'
  s.license          = { :type => 'Meta', :file => 'LICENSE' }
  s.author           = { 'Meta' => 'dev@meta.com' }
  s.source           = { :path => '.' }

  s.platform         = :ios, '15.2'
  s.swift_version    = '5.0'

  s.vendored_frameworks = [
    'MWDATCore.xcframework',
    'MWDATCamera.xcframework',
    'MWDATDisplay.xcframework',
    'MWDATMockDevice.xcframework',
    'MWDATMockDeviceTestClient.xcframework'
  ]
end
