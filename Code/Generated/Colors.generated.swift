// Generated using SwiftGen, by O.Halligon — https://github.com/AliSoftware/SwiftGen

#if os(iOS) || os(tvOS) || os(watchOS)
  import UIKit.UIColor
  typealias Color = UIColor
#elseif os(OSX)
  import AppKit.NSColor
  typealias Color = NSColor
#endif

extension Color {
  convenience init(rgbaValue: UInt32) {
    let red   = CGFloat((rgbaValue >> 24) & 0xff) / 255.0
    let green = CGFloat((rgbaValue >> 16) & 0xff) / 255.0
    let blue  = CGFloat((rgbaValue >>  8) & 0xff) / 255.0
    let alpha = CGFloat((rgbaValue      ) & 0xff) / 255.0

    self.init(red: red, green: green, blue: blue, alpha: alpha)
  }
}

// swiftlint:disable file_length
// swiftlint:disable type_body_length
enum ColorName {
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ff0000"></span>
  /// Alpha: 100% <br/> (0xff0000ff)
  case FlyBadGPS
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ffffff"></span>
  /// Alpha: 100% <br/> (0xffffffff)
  case FlyHUDText
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#52edc7"></span>
  /// Alpha: 100% <br/> (0x52edc7ff)
  case FlyHUDVRText
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#7ed321"></span>
  /// Alpha: 100% <br/> (0x7ed321ff)
  case HighBattery
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#434343"></span>
  /// Alpha: 100% <br/> (0x434343ff)
  case HudText
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ff0000"></span>
  /// Alpha: 100% <br/> (0xff0000ff)
  case LowBatttery
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ffcd00"></span>
  /// Alpha: 100% <br/> (0xffcd00ff)
  case MiddleBattery
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#464646"></span>
  /// Alpha: 100% <br/> (0x464646ff)
  case SettingsTextColor
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#50e3d7"></span>
  /// Alpha: 100% <br/> (0x50e3d7ff)
  case SwitchColor
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ffffff"></span>
  /// Alpha: 100% <br/> (0xffffffff)
  case Text

  var rgbaValue: UInt32 {
    switch self {
    case .FlyBadGPS: return 0xff0000ff
    case .FlyHUDText: return 0xffffffff
    case .FlyHUDVRText: return 0x52edc7ff
    case .HighBattery: return 0x7ed321ff
    case .HudText: return 0x434343ff
    case .LowBatttery: return 0xff0000ff
    case .MiddleBattery: return 0xffcd00ff
    case .SettingsTextColor: return 0x464646ff
    case .SwitchColor: return 0x50e3d7ff
    case .Text: return 0xffffffff
    }
  }

  var color: Color {
    return Color(named: self)
  }
}
// swiftlint:enable type_body_length

extension Color {
  convenience init(named name: ColorName) {
    self.init(rgbaValue: name.rgbaValue)
  }
}
