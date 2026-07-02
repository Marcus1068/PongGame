// 
// GeneratedStringSymbols_Localizable.swift
// Auto-Generated symbols for localized strings defined in “Localizable.xcstrings”.
// 

import Foundation

#if SWIFT_PACKAGE
private nonisolated let resourceBundle = Foundation.Bundle.module
@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
private nonisolated let resourceBundleDescription = LocalizedStringResource.BundleDescription.atURL(resourceBundle.bundleURL)
#else

private class ResourceBundleClass {}
@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
private nonisolated let resourceBundleDescription = LocalizedStringResource.BundleDescription.forClass(ResourceBundleClass.self)
#endif

@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
nonisolated extension LocalizedStringResource {
    /**
     Localized string for key “%lld active” in table “Localizable.xcstrings”.
     */
    static func active(_ arg1: Int) -> LocalizedStringResource {
        LocalizedStringResource("%lld active", defaultValue: "\(arg1, specifier: "%lld")", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “Amber Monitor” in table “Localizable.xcstrings”.
     */
    static var amberMonitor: LocalizedStringResource {
        LocalizedStringResource("Amber Monitor", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “Classic neon blues and magentas with bright arcade highlights.” in table “Localizable.xcstrings”.
     */
    static var classicNeonBluesAndMagentasWithBrightArcadeHighlights: LocalizedStringResource {
        LocalizedStringResource("Classic neon blues and magentas with bright arcade highlights.", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “Clean black-and-white visuals with glow and trails stripped back.” in table “Localizable.xcstrings”.
     */
    static var cleanBlackAndWhiteVisualsWithGlowAndTrailsStrippedBack: LocalizedStringResource {
        LocalizedStringResource("Clean black-and-white visuals with glow and trails stripped back.", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “Minimal Mono” in table “Localizable.xcstrings”.
     */
    static var minimalMono: LocalizedStringResource {
        LocalizedStringResource("Minimal Mono", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “Off” in table “Localizable.xcstrings”.
     */
    static var off: LocalizedStringResource {
        LocalizedStringResource("Off", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “On” in table “Localizable.xcstrings”.
     */
    static var on: LocalizedStringResource {
        LocalizedStringResource("On", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “Phosphor greens, strong contrast, and a terminal-style glow.” in table “Localizable.xcstrings”.
     */
    static var phosphorGreensStrongContrastAndATerminalStyleGlow: LocalizedStringResource {
        LocalizedStringResource("Phosphor greens, strong contrast, and a terminal-style glow.", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “Retro Green CRT” in table “Localizable.xcstrings”.
     */
    static var retroGreenCrt: LocalizedStringResource {
        LocalizedStringResource("Retro Green CRT", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “SPEED BOOST” in table “Localizable.xcstrings”.
     */
    static var speedBoost: LocalizedStringResource {
        LocalizedStringResource("SPEED BOOST", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “Score %@, %@ %lld, %@ %lld” in table “Localizable.xcstrings”.
     */
    static func score(_ arg1: String, _ arg2: String, _ arg3: Int, _ arg4: String, _ arg5: Int) -> LocalizedStringResource {
        LocalizedStringResource("Score %@, %@ %lld, %@ %lld", defaultValue: "\(arg1)\(arg2)\(arg3, specifier: "%lld")\(arg4)\(arg5, specifier: "%lld")", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “Synthwave” in table “Localizable.xcstrings”.
     */
    static var synthwave: LocalizedStringResource {
        LocalizedStringResource("Synthwave", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “Theme” in table “Localizable.xcstrings”.
     */
    static var theme: LocalizedStringResource {
        LocalizedStringResource("Theme", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “Warm amber tones inspired by vintage monochrome monitors.” in table “Localizable.xcstrings”.
     */
    static var warmAmberTonesInspiredByVintageMonochromeMonitors: LocalizedStringResource {
        LocalizedStringResource("Warm amber tones inspired by vintage monochrome monitors.", table: "Localizable", bundle: resourceBundleDescription)
    }
}