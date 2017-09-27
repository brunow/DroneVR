// Generated using SwiftGen, by O.Halligon — https://github.com/AliSoftware/SwiftGen

#if os(iOS) || os(tvOS) || os(watchOS)
  import UIKit.UIFont
  typealias Font = UIFont
#elseif os(OSX)
  import AppKit.NSFont
  typealias Font = NSFont
#endif

// swiftlint:disable file_length

protocol FontConvertible {
  func font(size: CGFloat) -> Font!
}

extension FontConvertible where Self: RawRepresentable, Self.RawValue == String {
  func font(size: CGFloat) -> Font! {
    return Font(font: self, size: size)
  }
}

extension Font {
  convenience init!<FontType: FontConvertible
    where FontType: RawRepresentable, FontType.RawValue == String>
    (font: FontType, size: CGFloat) {
      self.init(name: font.rawValue, size: size)
  }
}

struct FontFamily {
  enum SFUIDisplay: String, FontConvertible {
    case Regular = "SFUIDisplay-Regular"
    case Heavy = "SFUIDisplay-Heavy"
    case Ultralight = "SFUIDisplay-Ultralight"
    case Semibold = "SFUIDisplay-Semibold"
    case Bold = "SFUIDisplay-Bold"
    case Thin = "SFUIDisplay-Thin"
    case Black = "SFUIDisplay-Black"
    case Medium = "SFUIDisplay-Medium"
    case Light = "SFUIDisplay-Light"
  }
}
