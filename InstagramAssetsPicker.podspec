#
# Be sure to run `pod lib lint InstagramAssetsPicker.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "InstagramAssetsPicker"
  s.version          = "0.1.0"
  s.summary          = "A assets picker like Instagram with photo and video crop"

  s.homepage         = "https://github.com/JGINGIT/InstagramAssetsPicker"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "JG" => "jezzegoo@gmail.com" }
  s.source           = { :git => "https://github.com/JGINGIT/InstagramAssetsPicker.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resources = 'Pod/Assets/InstagramAssetsPicker.bundle'

  s.dependency 'GPUImage', '~> 0.1.6'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'

end
