// ScreenReservations.swift
//
// Describes the parts of the display that gameplay UI should stay clear of:
// camera cut-outs on the leading / trailing edge and the fold of a partially
// open dual-screen iPhone. The value is measured once near the root of the view
// tree and shared with overlays through the environment.
import SwiftUI

/// Horizontal areas of the display that overlays must avoid.
///
/// All values are expressed in the local coordinate space of the view that was
/// measured, which respects the safe area, so `leadingInset` and `trailingInset`
/// only describe space needed *beyond* the safe area.
nonisolated struct ScreenReservations: Equatable, Sendable {
    /// Smallest gap between overlay content and the edge of the safe area.
    static let baseMargin: CGFloat = 16

    /// A camera or other occlusion near the leading edge, past the safe area.
    var leadingInset: CGFloat = 0
    /// A camera or other occlusion near the trailing edge, past the safe area.
    var trailingInset: CGFloat = 0
    /// Horizontal span of the active fold, or `nil` when the display is flat.
    var fold: ClosedRange<CGFloat>?
    /// Width of the measured container.
    var width: CGFloat = 0
    /// Safe-area inset on the leading side of the measured container.
    var safeLeading: CGFloat = 0
    /// Safe-area inset on the trailing side of the measured container.
    var safeTrailing: CGFloat = 0

    /// No reservations, used before the first measurement and on devices
    /// without reserved regions.
    static let none = ScreenReservations()

    /// Width of the fold, or zero when the display is flat.
    var foldWidth: CGFloat {
        fold.map { $0.upperBound - $0.lowerBound } ?? 0
    }

    /// Margin to keep between overlay content and the leading edge.
    var leadingMargin: CGFloat {
        max(Self.baseMargin, leadingInset)
    }

    /// Margin to keep between overlay content and the trailing edge.
    var trailingMargin: CGFloat {
        max(Self.baseMargin, trailingInset)
    }

    /// Side margins that put content that fills the width on the center of the
    /// whole display, which is where the court's net is.
    ///
    /// The safe area can be lopsided (a dual-screen iPhone keeps its status area
    /// on one side), so content centered inside it would drift off the net.
    /// Extra margin on the roomier side moves it back without leaving the safe
    /// area.
    func centeredMargins(minimum: CGFloat = ScreenReservations.baseMargin) -> (leading: CGFloat, trailing: CGFloat) {
        let leading = max(minimum, leadingInset)
        let trailing = max(minimum, trailingInset)
        let offset = safeTrailing - safeLeading
        return (max(leading, trailing + offset), max(trailing, leading - offset))
    }

    /// Leading margin for content that lives in a single "primary" area: the
    /// whole width on a flat display, or the half after the fold when folded.
    var primaryLeadingMargin: CGFloat {
        guard let fold else { return leadingMargin }
        return fold.upperBound + Self.baseMargin
    }

    /// Width of the area left of the fold, inside the leading margin, or `nil`
    /// when the display is flat.
    var leadingHalfWidth: CGFloat? {
        guard let fold else { return nil }
        return max(0, fold.lowerBound - leadingMargin)
    }

    /// Width of the area right of the fold, inside the trailing margin, or `nil`
    /// when the display is flat.
    var trailingHalfWidth: CGFloat? {
        guard let fold else { return nil }
        return max(0, width - fold.upperBound - trailingMargin)
    }

    init() {}

    /// Builds reservations from already-extracted region frames.
    ///
    /// - Parameters:
    ///   - width: Width of the measured container.
    ///   - occlusions: Frames of active occluding regions (cameras, island).
    ///   - divisions: Frames of active dividing regions (folds).
    ///   - safeLeading: Safe-area inset on the leading side.
    ///   - safeTrailing: Safe-area inset on the trailing side.
    init(width: CGFloat, occlusions: [CGRect], divisions: [CGRect], safeLeading: CGFloat = 0, safeTrailing: CGFloat = 0) {
        self.width = width
        self.safeLeading = safeLeading
        self.safeTrailing = safeTrailing

        for frame in occlusions {
            // Only regions hugging a side edge matter for horizontal margins.
            if frame.midX < width / 2, frame.minX < width * 0.25 {
                leadingInset = max(leadingInset, frame.maxX)
            } else if frame.midX >= width / 2, frame.maxX > width * 0.75 {
                trailingInset = max(trailingInset, width - frame.minX)
            }
        }

        // A fold only acts as a net when it runs top to bottom.
        if let divider = divisions.first(where: { $0.height >= $0.width }) {
            let lower = max(0, divider.minX)
            let upper = min(width, divider.maxX)
            if lower < upper {
                fold = lower...upper
            }
        }
    }

    /// Reads the reserved regions that intersect the measured view.
    init(proxy: GeometryProxy) {
        var occlusions: [CGRect] = []
        var divisions: [CGRect] = []
        if #available(iOS 27.1, macOS 27.1, *) {
            occlusions = proxy.reservedRegions(kind: .occlusion).filter(\.isActive).map(\.frame)
            divisions = proxy.reservedRegions(kind: .division).filter(\.isActive).map(\.frame)
        }
        self.init(
            width: proxy.size.width,
            occlusions: occlusions,
            divisions: divisions,
            safeLeading: proxy.safeAreaInsets.leading,
            safeTrailing: proxy.safeAreaInsets.trailing
        )
    }
}

extension EnvironmentValues {
    /// Display areas that overlays should avoid, measured near the view root.
    @Entry var screenReservations = ScreenReservations.none
}

extension View {
    /// Pads the view so it is centered on the whole display rather than on the
    /// safe area, for content that belongs on the court's center line. When the
    /// display is folded it only keeps clear of the edges; callers lay out each
    /// half themselves.
    func centeredOnDisplay(minimumMargin: CGFloat = ScreenReservations.baseMargin) -> some View {
        modifier(DisplayMarginsModifier(minimumMargin: minimumMargin, confinesToPrimaryHalf: false))
    }

    /// Like `centeredOnDisplay`, but moves the content into the trailing half
    /// when the display is folded, so the fold does not cut through it.
    func inPrimaryArea(minimumMargin: CGFloat = ScreenReservations.baseMargin) -> some View {
        modifier(DisplayMarginsModifier(minimumMargin: minimumMargin, confinesToPrimaryHalf: true))
    }

    /// Measures reserved display regions for this view and publishes them to
    /// descendants through the `screenReservations` environment value.
    func publishesScreenReservations() -> some View {
        modifier(ScreenReservationsModifier())
    }
}

/// Keeps the latest `ScreenReservations` in state and injects it downward.
private struct ScreenReservationsModifier: ViewModifier {
    @State private var reservations = ScreenReservations.none

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: ScreenReservations.self) { proxy in
                ScreenReservations(proxy: proxy)
            } action: { newValue in
                reservations = newValue
            }
            .environment(\.screenReservations, reservations)
    }
}

/// Applies side margins that center content on the whole display, or confine it
/// to the trailing half while the display is folded.
private struct DisplayMarginsModifier: ViewModifier {
    let minimumMargin: CGFloat
    let confinesToPrimaryHalf: Bool

    @Environment(\.screenReservations) private var reservations

    func body(content: Content) -> some View {
        let margins = reservations.centeredMargins(minimum: minimumMargin)
        content
            .padding(.leading, leadingMargin(centered: margins.leading))
            .padding(.trailing, reservations.fold == nil ? margins.trailing : reservations.trailingMargin)
    }

    private func leadingMargin(centered: CGFloat) -> CGFloat {
        guard reservations.fold != nil else { return centered }
        return confinesToPrimaryHalf ? reservations.primaryLeadingMargin : reservations.leadingMargin
    }
}
