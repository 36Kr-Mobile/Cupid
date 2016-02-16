Pod::Spec.new do |s|

  s.name        = "Cupid"
  s.version     = "1.0.4"
  s.summary     = "Cupid is the ultimate Swift library to deal with third party share service for Chinese app."

  s.description = <<-DESC
                   Cupid is highly inspired by `MonkeyKing`, but with different code structure and data types. And with much more extainablity.
                   You can use it to post messages to QQ, WeChat, Weibo, Pocket, Pasteboard or do OAuth. With minimal code, you can even create your own share and OAuth service provider, such as Alipay!
                   ![screenshot](screenshots/animated.gif)
                   DESC

  s.homepage    = "https://github.com/36Kr-Mobile/Cupid.git"

  s.license     = { :type => "MIT", :file => "LICENSE" }

  s.authors           = { "Shannon Wu" => "inatu@icloud.com" }

  s.ios.deployment_target   = "8.0"

  s.source          = { :git => "https://github.com/36Kr-Mobile/Cupid.git", :tag => s.version }
  s.source_files    = "CupidDemo/Cupid/**/*.swift"
  s.requires_arc    = true

end
