Pod::Spec.new do |s|
  s.name         = "libPhoneNumberGeocoding"
  s.version      = "1.0.0"
  s.summary      = "Geocoding Features for libPhoneNumber-iOS"
  s.description  = <<-DESC
libPhoneNumberGeocoding for iOS
iOS library for gathering region descriptions for any phone number. This library stores geocoding metadata on disk space.
DESC
  s.homepage     = "https://github.com/iziz/libPhoneNumber-iOS.git"
  s.license      = 'Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0)'
  s.authors      = { "rastaarh" => "rastaar@google.com" , "paween" => "paween@google.com", "aalexli" => "aalexli@google.com"}
  s.source       = { :git => "https://github.com/iziz/libPhoneNumber-iOS.git", :tag => s.version.to_s }
  s.libraries      = 'z'
  s.ios.deployment_target = "10.1"
  s.osx.deployment_target = "10.9"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"
  s.requires_arc = true
  s.resources = "libPhoneNumberGeocoding/Metadata/*.bundle"
  s.private_header_files = 'libPhoneNumber/NBGeneratedPhoneNumberMetaData.h'
  s.dependency 'libPhoneNumber-iOS'
  s.source_files = 'libPhoneNumberGeocoding/NBPhoneNumberOfflineGeocoder.{h,m}', 'libPhoneNumberGeocoding/Metadata/NBGeocoderMetadataHelper.{h,m}'
end
