Pod::Spec.new do |s|
  s.name         = "GliderLogger"
  s.version      = "2.0.5"
  s.summary      = "Universal Logging - low overheaded simple & flexible for Swift (iOS, macOS, tvOS)"
  s.homepage     = "https://github.com/immobiliare/Glider.git"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Immobiliarelabs" => "mobile@immobiliare.it" }
  s.social_media_url   = "https://twitter.com/immobiliarelabs"
  s.ios.deployment_target = '10.0'
  s.tvos.deployment_target = '12.0'
  s.osx.deployment_target = '10.15.4'
  s.source           = {
    :git => 'https://github.com/immobiliare/Glider.git',
    :tag => s.version.to_s
  }
  s.swift_versions = ['5.0', '5.1', '5.3', '5.4', '5.5', '5.7', '5.8']
  s.framework = 'UIKit'

  s.module_name = "Glider"
  s.source_files = 'Glider/Sources/**/*'
end
