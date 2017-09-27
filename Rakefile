require "bundler/setup"
require "rubygems"
require 'cfpropertylist'

desc "Generate localizations"
task :localizations do
  system("twine generate-all-string-files ~/dev/dronevr-data/localizations.twine ~/dev/ios/DroneVR/Resources/Locales")
end

desc ""
task :build_changelog do
  # plist = CFPropertyList::List.new(:file => "Askr/Askr-Info.plist")
  # data = CFPropertyList.native_types(plist.value)
  # new_version = data["CFBundleShortVersionString"]
  # "Unreleased /"
  system("git changelog -a -p -t Unreleased")
end

desc "Generate assets"
# https://github.com/AliSoftware/SwiftGen#assets-catalogs
task :assets do
  system("swiftgen images SDKSample/Assets.xcassets --output Code/Generated/Images.generated.swift")
  system("swiftgen strings Resources/Locales/en.lproj/Localizable.strings --output Code/Generated/Strings.generated.swift")
  system("swiftgen colors Colors.txt --output Code/Generated/Colors.generated.swift")
  system("swiftgen fonts Resources/Fonts --output Code/Generated/Fonts.generated.swift")
  system("swiftgen storyboards SDKSample/MainStoryboard.storyboard --output Code/Generated/Storyboards.generated.swift")
  # system("natalie.swift SDKSample/MainStoryboard.storyboard > Code/Generated/Storyboards.swift")
end