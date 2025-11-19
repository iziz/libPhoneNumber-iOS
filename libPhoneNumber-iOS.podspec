Pod::Spec.new do |s|
  s.name         = "libPhoneNumber-iOS"
  s.version      = "1.3.0"
  s.summary      = "iOS library for parsing, formatting, storing and validating international phone numbers from libphonenumber library."
  s.description  = "libPhoneNumber for iOS. iOS library for parsing, formatting, storing and validating international phone numbers from libphonenumber library."
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
  
  s.libraries 	 = 'z'
  s.ios.framework    = 'Contacts'
  
  s.ios.deployment_target = "12.0"
  s.osx.deployment_target = "10.13"
  s.watchos.deployment_target = "4.0"
  s.tvos.deployment_target = "12.0"
  
  s.requires_arc = true

  s.private_header_files = [
                    'libPhoneNumberInternal/**/*.h',
                   ]
  
  s.source_files = [
                    'libPhoneNumberInternal/**/*.{h,m}',
                    'libPhoneNumber/**/*.{h,m}',
                   ]

  s.resources   = [
                    'libPhoneNumber/PrivacyInfo.xcprivacy'
                  ]

end
