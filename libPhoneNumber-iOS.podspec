Pod::Spec.new do |s|
  s.name         = "libPhoneNumber-iOS"
  s.version      = "1.0.5"
  s.summary      = "iOS library for parsing, formatting, storing and validating international phone numbers from libphonenumber library."
  s.description  = <<-DESC
libPhoneNumber for iOS
iOS library for parsing, formatting, storing and validating international phone numbers from libphonenumber library.
DESC
  s.homepage     = "https://github.com/iziz/libPhoneNumber-iOS.git"
  s.license      = { :type => 'Apache' }
  s.authors      = { "iziz" => "zen.isis@gmail.com", "hyukhur" => "hyukhur@gmail.com" }
  s.source       = { :git => "https://github.com/iziz/libPhoneNumber-iOS.git", :tag => s.version.to_s }
  s.libraries 	 = 'z'
  s.ios.framework    = 'CoreTelephony'

  ios_deployment_target = '11.0'
  osx_deployment_target = '10.10'
  tvos_deployment_target = '11.0'
  watchos_deployment_target = '4.0'

  s.ios.deployment_target = ios_deployment_target
  s.osx.deployment_target = osx_deployment_target
  s.tvos.deployment_target = tvos_deployment_target
  s.watchos.deployment_target = watchos_deployment_target
  s.requires_arc = true
  
  s.subspec 'Core' do |cs|
	cs.private_header_files = 'libPhoneNumber/NBGeneratedPhoneNumberMetaData.h'
	cs.source_files = 'libPhoneNumber/NBPhoneNumberDefines.{h,m}', 'libPhoneNumber/NBPhoneNumber.{h,m}', 'libPhoneNumber/NBNumberFormat.{h,m}', 'libPhoneNumber/NBPhoneNumberDesc.{h,m}', 'libPhoneNumber/NBPhoneMetaData.{h,m}', 'libPhoneNumber/NBPhoneNumberUtil.{h,m}', 'libPhoneNumber/NBMetadataHelper.{h,m}', 'libPhoneNumber/NBAsYouTypeFormatter.{h,m}', 'libPhoneNumber/NSArray+NBAdditions.{h,m}', 'libPhoneNumber/NBGeneratedPhoneNumberMetaData.h', 'libPhoneNumber/Internal/NBRegExMatcher.{h,m}', 'libPhoneNumber/Internal/NBRegularExpressionCache.{h,m}'

    cs.test_spec 'unit' do |unit_tests|
      unit_tests.platforms = {
        :ios => ios_deployment_target,
        :osx => osx_deployment_target,
        :tvos => tvos_deployment_target
      }
      unit_tests.source_files = [
        'libPhoneNumberTests/*.[mh]',
      ]
	  unit_tests.resources = ['Resources/libPhoneNumberMetadataForTesting']
    end

  end
  
  s.subspec 'ShortNumber' do |sns|
    sns.private_header_files = 'libPhoneNumberShortNumber/NBGeneratedShortNumberMetadata.h'
    sns.dependency 'libPhoneNumber-iOS/Core'
    sns.source_files = 'libPhoneNumberShortNumber/NBShortNumberUtil.{h,m}', 'libPhoneNumberShortNumber/NBShortNumberMetadataHelper.{h,m}', 'libPhoneNumberShortNumber/NBGeneratedShortNumberMetadata.h'

    sns.test_spec 'unit' do |unit_tests|
      unit_tests.platforms = {
        :ios => ios_deployment_target,
        :osx => osx_deployment_target,
        :tvos => tvos_deployment_target
      }
      unit_tests.source_files = [
        'libPhoneNumberShortNumberTests/*.[mh]',
      ]
	  unit_tests.resources = ['Resources/libPhoneNumberMetadataForTesting']
    end

  end
  
  s.subspec 'Geocoding' do |gs|
    gs.resources = "libPhoneNumberGeocoding/Metadata/*.bundle"
    gs.private_header_files = 'libPhoneNumberGeocoding/Metadata/NBGeocoderMetadataHelper.h'
    gs.dependency 'libPhoneNumber-iOS/Core'
    gs.source_files = 'libPhoneNumberGeocoding/NBPhoneNumberOfflineGeocoder.{h,m}', 'libPhoneNumberGeocoding/Metadata/NBGeocoderMetadataHelper.{h,m}'
    gs.libraries = 'sqlite3'

    gs.test_spec 'unit' do |unit_tests|
      unit_tests.platforms = {
        :ios => ios_deployment_target,
        :osx => osx_deployment_target,
        :tvos => tvos_deployment_target
      }
      unit_tests.source_files = [
        'libPhoneNumberGeocodingTests/*.[mh]',
      ]
	  unit_tests.resources = ['libPhoneNumberGeocodingTests/TestingSource.bundle']
    end

  end

end
