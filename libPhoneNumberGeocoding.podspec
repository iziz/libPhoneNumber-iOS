Pod::Spec.new do |s|
  s.name         = "libPhoneNumberGeocoding"
  s.version      = "0.9.15"
  s.summary      = "Geocoding Features for libPhoneNumber-iOS"
  s.description  = <<-DESC
libPhoneNumberGeocoding for iOS
iOS library for gathering region descriptions for any phone number. This library stores geocoding metadata on disk space.
DESC
  s.homepage     = "https://github.com/iziz/libPhoneNumber-iOS.git"
  s.license      = 'Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0)'
  s.authors      = { "rastaarh" => "rastaar@google.com", "paween" => "paween@google.com", "aalexli" => "aalexli@google.com" }
  s.source       = { :git => "https://github.com/iziz/libPhoneNumber-iOS.git", :tag => s.version.to_s }
  s.libraries      = 'z'
  s.ios.framework    = 'CoreTelephony'
  s.ios.deployment_target = "6.0"
  s.osx.deployment_target = "10.9"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"
  s.requires_arc = true
  s.resources = "libPhoneNumberGeocoding/Metadata/*.bundle"
  s.private_header_files = 'libPhoneNumber/NBGeneratedPhoneNumberMetaData.h'
  s.source_files = 'libPhoneNumber/NBPhoneNumberDefines.{h,m}', 'libPhoneNumber/NBPhoneNumber.{h,m}', 'libPhoneNumber/NBNumberFormat.{h,m}', 'libPhoneNumber/NBPhoneNumberDesc.{h,m}', 'libPhoneNumber/NBPhoneMetaData.{h,m}', 'libPhoneNumber/NBPhoneNumberUtil.{h,m}', 'libPhoneNumber/NBMetadataHelper.{h,m}', 'libPhoneNumber/NBAsYouTypeFormatter.{h,m}', 'libPhoneNumber/NSArray+NBAdditions.{h,m}', 'libPhoneNumber/NBGeneratedPhoneNumberMetaData.h', 'libPhoneNumber/Internal/NBRegExMatcher.{h,m}', 'libPhoneNumber/Internal/NBRegularExpressionCache.{h,m}', 'libPhoneNumberGeocoding/NBPhoneNumberOfflineGeocoder.{h,m}', 'libPhoneNumberGeocoding/Metadata/NBGeocoderMetadataHelper.{h,m}'
end
