// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif
#if canImport(SwiftUI)
  import SwiftUI
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ColorAsset.Color", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetColorTypeAlias = ColorAsset.Color
@available(*, deprecated, renamed: "ImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
internal enum Assets {
  internal enum Assets {
    internal static let accentColor = ColorAsset(name: "AccentColor")
  }
  internal enum Icons {
    internal static let icArrowRight = ImageAsset(name: "ic_arrow_right")
    internal static let icBack = ImageAsset(name: "ic_back")
    internal static let icCalendar = ImageAsset(name: "ic_calendar")
    internal static let icCheckOff = ImageAsset(name: "ic_check_off")
    internal static let icCheckOn = ImageAsset(name: "ic_check_on")
    internal static let icChevronBack = ImageAsset(name: "ic_chevron_back")
    internal static let icChevronDown = ImageAsset(name: "ic_chevron_down")
    internal static let icClose = ImageAsset(name: "ic_close")
    internal static let icGrid = ImageAsset(name: "ic_grid")
    internal static let icHashtag = ImageAsset(name: "ic_hashtag")
    internal static let icList = ImageAsset(name: "ic_list")
    internal static let icLogoBlack = ImageAsset(name: "ic_logo_black")
    internal static let icLogoWhite = ImageAsset(name: "ic_logo_white")
    internal static let icMemo = ImageAsset(name: "ic_memo")
    internal static let icMore = ImageAsset(name: "ic_more")
    internal static let icNotificationNormal = ImageAsset(name: "ic_notification_normal")
    internal static let icRadioOff = ImageAsset(name: "ic_radio_off")
    internal static let icRadioOn = ImageAsset(name: "ic_radio_on")
    internal static let icRightArrow = ImageAsset(name: "ic_right_arrow")
    internal static let icSmallPlus = ImageAsset(name: "ic_small_plus")
    internal static let icTitle = ImageAsset(name: "ic_title")
    internal static let icTrash = ImageAsset(name: "ic_trash")
  }
  internal enum Images {
    internal static let imgCategoryDo1 = ImageAsset(name: "img_category_do_1")
    internal static let imgCategoryDo10 = ImageAsset(name: "img_category_do_10")
    internal static let imgCategoryDo11 = ImageAsset(name: "img_category_do_11")
    internal static let imgCategoryDo12 = ImageAsset(name: "img_category_do_12")
    internal static let imgCategoryDo2 = ImageAsset(name: "img_category_do_2")
    internal static let imgCategoryDo3 = ImageAsset(name: "img_category_do_3")
    internal static let imgCategoryDo4 = ImageAsset(name: "img_category_do_4")
    internal static let imgCategoryDo5 = ImageAsset(name: "img_category_do_5")
    internal static let imgCategoryDo6 = ImageAsset(name: "img_category_do_6")
    internal static let imgCategoryDo7 = ImageAsset(name: "img_category_do_7")
    internal static let imgCategoryDo8 = ImageAsset(name: "img_category_do_8")
    internal static let imgCategoryDo9 = ImageAsset(name: "img_category_do_9")
    internal static let imgCategoryGet1 = ImageAsset(name: "img_category_get_1")
    internal static let imgCategoryGet10 = ImageAsset(name: "img_category_get_10")
    internal static let imgCategoryGet2 = ImageAsset(name: "img_category_get_2")
    internal static let imgCategoryGet3 = ImageAsset(name: "img_category_get_3")
    internal static let imgCategoryGet4 = ImageAsset(name: "img_category_get_4")
    internal static let imgCategoryGet5 = ImageAsset(name: "img_category_get_5")
    internal static let imgCategoryGet6 = ImageAsset(name: "img_category_get_6")
    internal static let imgCategoryGet7 = ImageAsset(name: "img_category_get_7")
    internal static let imgCategoryGet8 = ImageAsset(name: "img_category_get_8")
    internal static let imgCategoryGet9 = ImageAsset(name: "img_category_get_9")
    internal static let imgCategoryGo1 = ImageAsset(name: "img_category_go_1")
    internal static let imgCategoryGo10 = ImageAsset(name: "img_category_go_10")
    internal static let imgCategoryGo2 = ImageAsset(name: "img_category_go_2")
    internal static let imgCategoryGo3 = ImageAsset(name: "img_category_go_3")
    internal static let imgCategoryGo4 = ImageAsset(name: "img_category_go_4")
    internal static let imgCategoryGo5 = ImageAsset(name: "img_category_go_5")
    internal static let imgCategoryGo6 = ImageAsset(name: "img_category_go_6")
    internal static let imgCategoryGo7 = ImageAsset(name: "img_category_go_7")
    internal static let imgCategoryGo8 = ImageAsset(name: "img_category_go_8")
    internal static let imgCategoryGo9 = ImageAsset(name: "img_category_go_9")
    internal static let imgCategoryWantToDo = ImageAsset(name: "img_category_want_to_do")
    internal static let imgCategoryWantToGet = ImageAsset(name: "img_category_want_to_get")
    internal static let imgCategoryWantToGo = ImageAsset(name: "img_category_want_to_go")
    internal static let imgEmojiEmpty = ImageAsset(name: "img_emoji_empty")
    internal static let imgHomeEmoji = ImageAsset(name: "img_home_emoji")
  }
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

internal final class ColorAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Color = NSColor
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Color = UIColor
  #endif

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  internal private(set) lazy var color: Color = {
    guard let color = Color(asset: self) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }()

  #if os(iOS) || os(tvOS)
  @available(iOS 11.0, tvOS 11.0, *)
  internal func color(compatibleWith traitCollection: UITraitCollection) -> Color {
    let bundle = BundleToken.bundle
    guard let color = Color(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }
  #endif

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  internal private(set) lazy var swiftUIColor: SwiftUI.Color = {
    SwiftUI.Color(asset: self)
  }()
  #endif

  fileprivate init(name: String) {
    self.name = name
  }
}

internal extension ColorAsset.Color {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  convenience init?(asset: ColorAsset) {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
internal extension SwiftUI.Color {
  init(asset: ColorAsset) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle)
  }
}
#endif

internal struct ImageAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Image = UIImage
  #endif

  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, macOS 10.7, *)
  internal var image: Image {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let name = NSImage.Name(self.name)
    let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }

  #if os(iOS) || os(tvOS)
  @available(iOS 8.0, tvOS 9.0, *)
  internal func image(compatibleWith traitCollection: UITraitCollection) -> Image {
    let bundle = BundleToken.bundle
    guard let result = Image(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }
  #endif

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  internal var swiftUIImage: SwiftUI.Image {
    SwiftUI.Image(asset: self)
  }
  #endif
}

internal extension ImageAsset.Image {
  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, *)
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init?(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = BundleToken.bundle
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
internal extension SwiftUI.Image {
  init(asset: ImageAsset) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle)
  }

  init(asset: ImageAsset, label: Text) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle, label: label)
  }

  init(decorative asset: ImageAsset) {
    let bundle = BundleToken.bundle
    self.init(decorative: asset.name, bundle: bundle)
  }
}
#endif

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
