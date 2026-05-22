Pod::Spec.new do |s|
  s.name         = "libPhoneNumberTimeZones"
  s.version      = "1.7.1"
  s.summary      = "Timezone metadata features for libPhoneNumber-iOS"
  s.description  = "Timezone metadata lookup for libPhoneNumber-iOS. This optional module stores timezone prefix metadata on disk."
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

  s.libraries    = 'sqlite3'

  s.ios.deployment_target = "12.0"
  s.osx.deployment_target = "10.13"
  s.watchos.deployment_target = "4.0"
  s.tvos.deployment_target = "12.0"

  s.requires_arc = true

  s.resources    = "libPhoneNumberTimeZonesMetaData/*.bundle"

  s.dependency 'libPhoneNumber-iOS', '~> 1.7.1'

  s.source_files = [
                    'libPhoneNumberTimeZones/**/*.{h,m}',
                   ]
end
