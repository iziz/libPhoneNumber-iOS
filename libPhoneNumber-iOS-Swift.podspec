Pod::Spec.new do |s|
  s.name         = "libPhoneNumber-iOS-Swift"
  s.module_name  = "libPhoneNumberIOSSwift"
  s.version      = "1.6.1"
  s.summary      = "Swift-first umbrella facade for libPhoneNumber-iOS"
  s.description  = "Swift-first umbrella facade over the stable Objective-C libPhoneNumber-iOS core and optional geocoding and short-number modules."
  s.homepage     = "https://github.com/iziz/libPhoneNumber-iOS.git"
  s.license      = 'Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0)'
  s.authors      = {
                    "iziz" => "zen.isis@gmail.com",
                    "hyukhur" => "hyukhur@gmail.com",
                    "Kris Kline" => "kris.kline@oracle.com"
                   }

  s.source       = {
                    :git => "https://github.com/iziz/libPhoneNumber-iOS.git",
                    :tag => s.version.to_s
                   }

  s.ios.deployment_target = "12.0"
  s.osx.deployment_target = "10.13"
  s.watchos.deployment_target = "4.0"
  s.tvos.deployment_target = "12.0"

  s.swift_version = "5.5"
  s.requires_arc = true

  s.dependency 'libPhoneNumber-iOS-SwiftCore', '~> 1.6.1'
  s.dependency 'libPhoneNumber-iOS-SwiftGeocoding', '~> 1.6.1'
  s.dependency 'libPhoneNumber-iOS-SwiftShortNumber', '~> 1.6.1'

  s.source_files = [
                    'libPhoneNumberIOSSwift/**/*.swift',
                   ]
end
