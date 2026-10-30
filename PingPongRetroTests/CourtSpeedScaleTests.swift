//
//  CourtSpeedScaleTests.swift
//  PingPongRetroTests
//
//  Unit tests for how court width scales ball speed.
//

import CoreGraphics
import Testing
@testable import PingPongRetro

@MainActor
struct CourtSpeedScaleTests {
    @Test func referenceWidthLeavesSpeedUnchanged() {
        #expect(GameConfig.courtSpeedScale(forWidth: GameConfig.referenceCourtWidth) == 1)
    }

    @Test func widerCourtsSpeedTheBallUpInProportion() {
        let width = GameConfig.referenceCourtWidth * 1.25
        #expect(abs(GameConfig.courtSpeedScale(forWidth: width) - 1.25) < 0.0001)
    }

    @Test func scaleIsCappedForVeryWideCourts() {
        #expect(GameConfig.courtSpeedScale(forWidth: 5_000) == GameConfig.courtSpeedScaleRange.upperBound)
    }

    @Test func scaleIsFlooredForNarrowCourts() {
        #expect(GameConfig.courtSpeedScale(forWidth: 100) == GameConfig.courtSpeedScaleRange.lowerBound)
    }

    @Test func unmeasuredCourtUsesNoScaling() {
        #expect(GameConfig.courtSpeedScale(forWidth: 0) == 1)
    }
}
