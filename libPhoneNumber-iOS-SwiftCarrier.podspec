Pod::Spec.new do |s|
  s.name         = "libPhoneNumber-iOS-SwiftCarrier"
  s.module_name  = "libPhoneNumberSwiftCarrier"
  s.version      = "1.7.1"
  s.summary      = "Swift-first carrier facade for libPhoneNumber-iOS"
  s.description  = "Swift-first carrier metadata facade over libPhoneNumberCarrier."
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

  s.dependency 'libPhoneNumber-iOS-SwiftCore', '~> 1.7.1'
  s.dependency 'libPhoneNumberCarrier', '~> 1.7.1'

  s.source_files = [
                    'libPhoneNumberSwiftCarrier/**/*.swift',
                   ]
end
