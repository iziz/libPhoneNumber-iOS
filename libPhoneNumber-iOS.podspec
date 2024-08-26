Pod::Spec.new do |s|
  s.name         = "libPhoneNumber-iOS"
  s.version      = "1.2.0"
  s.summary      = "iOS library for parsing, formatting, storing and validating international phone numbers from libphonenumber library."
  s.description  = <<-DESC
libPhoneNumber for iOS
iOS library for parsing, formatting, storing and validating international phone numbers from libphonenumber library.
DESC
  s.homepage     = "https://github.com/iziz/libPhoneNumber-iOS.git"
  s.license      = 'Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0)'
  s.authors      = { "iziz" => "zen.isis@gmail.com", "hyukhur" => "hyukhur@gmail.com" }
  s.source       = { :git => "https://github.com/iziz/libPhoneNumber-iOS.git", :tag => s.version.to_s }
  s.libraries 	 = 'z'
  s.ios.framework    = 'Contacts'
  s.ios.deployment_target = "12.0"
  s.osx.deployment_target = "10.11"
  s.watchos.deployment_target = "4.0"
  s.tvos.deployment_target = "11.0"
  s.requires_arc = true
  s.private_header_files = 'libPhoneNumber/NBGeneratedPhoneNumberMetaData.h'
  s.source_files = 'libPhoneNumber/NBPhoneNumberDefines.{h,m}', 'libPhoneNumber/NBPhoneNumber.{h,m}', 'libPhoneNumber/NBNumberFormat.{h,m}', 'libPhoneNumber/NBPhoneNumberDesc.{h,m}', 'libPhoneNumber/NBPhoneMetaData.{h,m}', 'libPhoneNumber/NBPhoneNumberUtil.{h,m}', 'libPhoneNumber/NBMetadataHelper.{h,m}', 'libPhoneNumber/NBAsYouTypeFormatter.{h,m}', 'libPhoneNumber/NSArray+NBAdditions.{h,m}', 'libPhoneNumber/NBGeneratedPhoneNumberMetaData.h', 'libPhoneNumber/Internal/NBRegExMatcher.{h,m}', 'libPhoneNumber/Internal/NBRegularExpressionCache.{h,m}'
end
