// PongScene+ReservedRegions.swift
//
// Keeps the court clear of hardware-reserved display regions. Cameras push the
// paddles in from the side edges, and the fold of a partially open dual-screen
// iPhone becomes the net: the dashed center line is hidden and nothing spawns
// inside the fold.
import SpriteKit
#if os(iOS)
import UIKit
#endif

extension PongScene {
    /// How often, in seconds, reserved regions are re-read. Regions can change
    /// without the scene resizing, for example while the device is folding.
    private static let reservedRegionRefreshInterval: TimeInterval = 0.25

    /// Ball and computer-paddle speed factor for the current court width.
    var courtSpeedScale: CGFloat {
        GameConfig.courtSpeedScale(forWidth: frame.width)
    }

    /// Serve and return speed after applying the speed setting and court width.
    var scaledBaseBallSpeed: CGFloat {
        GameConfig.baseBallSpeed * courtSpeedScale * CGFloat(gameState?.ballSpeed ?? 1)
    }

    /// Horizontal span, in scene coordinates, of the fold when the device is
    /// partially open, or `nil` when the display is flat.
    var activeFoldRange: ClosedRange<CGFloat>? {
        #if os(iOS)
        if #available(iOS 27.1, *), let view {
            let divider = view.reservedRegions(kind: .division)
                .first { $0.isActive && $0.frame.height >= $0.frame.width }
            if let divider, divider.frame.minX < divider.frame.maxX {
                return divider.frame.minX...divider.frame.maxX
            }
        }
        #endif
        return nil
    }

    /// Width of the side area occupied by cameras or the Dynamic Island, as
    /// seen by the larger of the two side edges. Zero when no region is active.
    var sideOcclusionInset: CGFloat {
        #if os(iOS)
        if #available(iOS 27.1, *), let view {
            let width = view.bounds.width
            return view.reservedRegions(kind: .occlusion)
                .filter(\.isActive)
                .map { region in
                    region.frame.midX < width / 2 ? region.frame.maxX : width - region.frame.minX
                }
                .max() ?? 0
        }
        #endif
        return 0
    }

    /// Moves `x` out of the fold, if it falls inside, to the nearer side.
    func positionAvoidingFold(_ xPosition: CGFloat) -> CGFloat {
        guard let fold = activeFoldRange else { return xPosition }
        let clearance = ballRadius * 4
        guard xPosition > fold.lowerBound - clearance, xPosition < fold.upperBound + clearance else { return xPosition }
        let midFold = (fold.lowerBound + fold.upperBound) / 2
        return xPosition < midFold ? fold.lowerBound - clearance : fold.upperBound + clearance
    }

    /// Horizontal center for transient banners: mid-court on a flat display,
    /// or the middle of the trailing half when the fold is in the way.
    var bannerCenterX: CGFloat {
        guard let fold = activeFoldRange else { return frame.midX }
        return (fold.upperBound + frame.maxX) / 2
    }

    /// Hides the dashed center line while the fold itself serves as the net.
    func updateCenterLineVisibility() {
        centerLineContainer.isHidden = activeFoldRange != nil
    }

    /// Re-applies paddle insets and center-line visibility when the cameras or
    /// fold have changed since the last check. Cheap enough to call every frame.
    func refreshReservedRegionLayoutIfNeeded(currentTime: TimeInterval) {
        guard currentTime - lastReservedRegionCheck >= Self.reservedRegionRefreshInterval else { return }
        lastReservedRegionCheck = currentTime

        let inset = paddleEdgeInset
        if inset != appliedPaddleInset {
            appliedPaddleInset = inset
            playerPaddle.position.x = frame.maxX - inset
            opponentPaddle.position.x = frame.minX + inset
        }

        let fold = activeFoldRange
        if fold != appliedFoldRange {
            appliedFoldRange = fold
            updateCenterLineVisibility()
            layoutPowerUpIfNeeded()
        }
    }
}
