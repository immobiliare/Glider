Pod::Spec.new do |s|
  s.name         = "GliderLogger"
  s.version      = "0.9.2"
  s.summary      = "Lightweight yet powerful logging library. It's the Winston.js for Swift!"
  s.homepage     = "https://github.com/malcommac/Glider.git"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Daniele Margutti" => "hello@danielemargutti.com" }
  s.social_media_url   = "https://twitter.com/danielemargutti"
  s.ios.deployment_target = '13.0'
  s.source           = {
    :git => 'https://github.com/malcommac/Glider.git',
    :tag => s.version.to_s
  }
  s.swift_versions = ['5.0', '5.1', '5.3', '5.4', '5.5']
  s.framework = 'UIKit'

  s.module_name = "Glider"
  s.source_files = 'Glider/Sources/**/*'
end
