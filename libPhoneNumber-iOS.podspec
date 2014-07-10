Pod::Spec.new do |s|
  s.name         = "libPhoneNumber-iOS"
  s.version      = "0.7.4"
  s.summary      = "iOS library for parsing, formatting, storing and validating international phone numbers from libphonenumber library."
  s.description  = <<-DESC
libPhoneNumber for iOS
iOS library for parsing, formatting, storing and validating international phone numbers from libphonenumber library.
Visit http://code.google.com/p/libphonenumber/ for more information.
DESC
  s.homepage     = "https://github.com/iziz/libPhoneNumber-iOS.git"
  s.license      = 'Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0)'
  s.authors      = { "iziz" => "zen.isis@gmail.com", "hyukhur" => "hyukhur@gmail.com" }
  s.source       = { :git => "https://github.com/iziz/libPhoneNumber-iOS.git", :tag => "0.7.3" }
  s.ios.framework    = 'CoreTelephony'
  s.ios.deployment_target = "4.3"
  s.osx.deployment_target = "10.9"
  s.requires_arc = true
  s.source_files = 'libPhoneNumber/NBPhoneNumber.{h,m}', 'libPhoneNumber/NBNumberFormat.{h,m}', 'libPhoneNumber/NBPhoneNumberDesc.{h,m}', 'libPhoneNumber/NBPhoneMetaData.{h,m}', 'libPhoneNumber/NBPhoneNumberUtil.{h,m}', 'libPhoneNumber/NBAsYouTypeFormatter.{h,m}', 'libPhoneNumber/NBPhoneNumberDefines.h', 'libPhoneNumber/NSArray+NBAdditions.{h,m}'
  s.resources = "libPhoneNumber/Metadata\ Classes/NBPhoneNumberMetadata.plist"
end
