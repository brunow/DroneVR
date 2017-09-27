// Generated using SwiftGen, by O.Halligon — https://github.com/AliSoftware/SwiftGen

#if os(iOS) || os(tvOS) || os(watchOS)
  import UIKit.UIImage
  typealias Image = UIImage
#elseif os(OSX)
  import AppKit.NSImage
  typealias Image = NSImage
#endif

// swiftlint:disable file_length
// swiftlint:disable type_body_length
enum Asset: String {
  case AltitudeIcon = "AltitudeIcon"
  case CameraLineHorizontal = "CameraLineHorizontal"
  case CameraLineVertical = "CameraLineVertical"
  case CloseMenuButton = "CloseMenuButton"
  case ConnectedState = "ConnectedState"
  case DistanceIcon = "DistanceIcon"
  case DroneIcon = "DroneIcon"
  case EmergencyButton = "EmergencyButton"
  case FindDroneBarBG = "FindDroneBarBG"
  case FindDroneCloseBtn = "FindDroneCloseBtn"
  case FindDroneCompass = "FindDroneCompass"
  case Fly_No_Video = "fly-no-video"
  case FlyButton = "FlyButton"
  case FlyingMetricsOverlay = "FlyingMetricsOverlay"
  case GoDown = "GoDown"
  case GoUp = "GoUp"
  case HighBattery = "HighBattery"
  case HomeBackground = "HomeBackground"
  case LandingButton = "LandingButton"
  case LaunchBG = "LaunchBG"
  case LineSep = "LineSep"
  case Logo = "Logo"
  case LowBattery = "LowBattery"
  case MainLogo = "MainLogo"
  case MapBG = "MapBG"
  case MaskImageLeft = "MaskImageLeft"
  case MaskImageRight = "MaskImageRight"
  case MenuFindMyDroneButton = "MenuFindMyDroneButton"
  case MenuIconBackground = "MenuIconBackground"
  case MenuReturnHomeButton = "MenuReturnHomeButton"
  case MenuSimpleButton = "MenuSimpleButton"
  case MenuVRButton = "MenuVRButton"
  case MenuVRModeButton = "MenuVRModeButton"
  case MiddleBattery = "MiddleBattery"
  case MoreButton = "MoreButton"
  case MoveBackward = "MoveBackward"
  case MoveForward = "MoveForward"
  case MoveLeft = "MoveLeft"
  case MoveRight = "MoveRight"
  case NotificationBackground = "NotificationBackground"
  case NotificationStatusBackground = "NotificationStatusBackground"
  case NotificationSuccessIcon = "NotificationSuccessIcon"
  case RecordingOnButton = "RecordingOnButton"
  case RecordingStopButton = "RecordingStopButton"
  case SettingsBlurredBG = "SettingsBlurredBG"
  case SettingsSegmentedBorder = "SettingsSegmentedBorder"
  case SettingsSegmentedSelectedBG = "SettingsSegmentedSelectedBG"
  case SettingsSegmentedUnSelectedBG = "SettingsSegmentedUnSelectedBG"
  case SpeedIcon = "SpeedIcon"
  case Stick_base = "stick_base"
  case Stick_hold = "stick_hold"
  case Stick_normal = "stick_normal"
  case StickCenter = "StickCenter"
  case TakeOffButton = "TakeOffButton"
  case TakePhotoButton = "TakePhotoButton"
  case TurnLeft = "TurnLeft"
  case TurnRight = "TurnRight"

  var image: Image {
    return Image(asset: self)
  }
}
// swiftlint:enable type_body_length

extension Image {
  convenience init!(asset: Asset) {
    self.init(named: asset.rawValue)
  }
}
