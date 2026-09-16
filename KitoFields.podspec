Pod::Spec.new do |s|
  s.name             = 'KitoFields'
  s.version          = '1.1.1'
  s.summary          = 'Customisable SwiftUI form inputs: text, email, password, phone with country picker, OTP.'
  s.description      = <<-DESC
    KitoFields is a pure-SwiftUI form toolkit. Text, email, password (reveal, strength meter,
    requirements), phone number (country picker, as-you-type formatting, E.164, 220+ regions) and
    one-time-code fields share one style and theme system: outlined, filled, underlined, floating
    label or plain, in any shape, with validation rules, inline errors and motion presets.
  DESC
  s.homepage         = 'https://github.com/wykeenjenga/KitoFields'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Wycliff Njenga' => 'wycliffnjenga19@gmail.com' }
  s.source           = { :git => 'https://github.com/wykeenjenga/KitoFields.git', :tag => s.version.to_s }
  s.social_media_url = 'https://x.com/wycliffnjenga2'

  s.ios.deployment_target = '15.0'
  s.osx.deployment_target = '12.0'
  s.swift_versions   = ['5.9']
  s.frameworks       = 'SwiftUI'
  s.source_files     = 'Sources/KitoFields/**/*.swift'
end
