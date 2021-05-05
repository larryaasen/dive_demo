# pod lib lint dive_obslib.podspec
Pod::Spec.new do |s|
  s.name             = 'dive_obslib'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin that provides low level services for video.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*.{swift,h,m,mm}'
  s.frameworks  = 'AVFoundation'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.13'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.2'
  s.xcconfig  =   {
    'LIBRARY_SEARCH_PATHS' => [
      '$(inherited)'
    ]
  }
end
