//
//  ScreenReservationsTests.swift
//  PingPongRetroTests
//
//  Unit tests for how camera and fold regions turn into overlay margins.
//

import CoreGraphics
import Testing
@testable import PingPongRetro

struct ScreenReservationsTests {
    private let width: CGFloat = 800

    @Test func flatDisplayUsesBaseMarginsAndNoFold() {
        let reservations = ScreenReservations(width: width, occlusions: [], divisions: [])

        #expect(reservations.fold == nil)
        #expect(reservations.leadingMargin == ScreenReservations.baseMargin)
        #expect(reservations.trailingMargin == ScreenReservations.baseMargin)
        #expect(reservations.leadingHalfWidth == nil)
        #expect(reservations.primaryLeadingMargin == reservations.leadingMargin)
    }

    @Test func cameraNearLeadingEdgeWidensLeadingMargin() {
        let camera = CGRect(x: 0, y: 0, width: 60, height: 120)
        let reservations = ScreenReservations(width: width, occlusions: [camera], divisions: [])

        #expect(reservations.leadingInset == 60)
        #expect(reservations.trailingInset == 0)
        #expect(reservations.leadingMargin == 60)
    }

    @Test func cameraNearTrailingEdgeWidensTrailingMargin() {
        let camera = CGRect(x: 740, y: 0, width: 60, height: 120)
        let reservations = ScreenReservations(width: width, occlusions: [camera], divisions: [])

        #expect(reservations.trailingInset == 60)
        #expect(reservations.leadingInset == 0)
    }

    @Test func symmetricSafeAreaKeepsMarginsEqual() {
        let reservations = ScreenReservations(
            width: width, occlusions: [], divisions: [], safeLeading: 20, safeTrailing: 20
        )
        let margins = reservations.centeredMargins()

        #expect(margins.leading == ScreenReservations.baseMargin)
        #expect(margins.trailing == ScreenReservations.baseMargin)
    }

    @Test func lopsidedSafeAreaShiftsContentBackOntoTheDisplayCenter() {
        // The status area takes 60 points on the trailing side only, so content
        // centered in the safe area would sit 30 points left of the display center.
        let reservations = ScreenReservations(
            width: width, occlusions: [], divisions: [], safeLeading: 0, safeTrailing: 60
        )
        let margins = reservations.centeredMargins(minimum: 16)

        #expect(margins.leading == 76)
        #expect(margins.trailing == 16)
        // Midpoint of the padded area sits at the display center (width / 2 + 30 in local space).
        #expect((margins.leading + (width - margins.trailing)) / 2 == width / 2 + 30)
    }

    @Test func lopsidedSafeAreaOnTheLeadingSideShiftsTheOtherWay() {
        let reservations = ScreenReservations(
            width: width, occlusions: [], divisions: [], safeLeading: 60, safeTrailing: 0
        )
        let margins = reservations.centeredMargins(minimum: 16)

        #expect(margins.leading == 16)
        #expect(margins.trailing == 76)
    }

    @Test func centeredOcclusionDoesNotChangeSideMargins() {
        let island = CGRect(x: 340, y: 0, width: 120, height: 40)
        let reservations = ScreenReservations(width: width, occlusions: [island], divisions: [])

        #expect(reservations.leadingInset == 0)
        #expect(reservations.trailingInset == 0)
    }

    @Test func verticalFoldSplitsTheDisplayIntoTwoHalves() {
        let fold = CGRect(x: 390, y: 0, width: 20, height: 400)
        let reservations = ScreenReservations(width: width, occlusions: [], divisions: [fold])

        #expect(reservations.fold == 390...410)
        #expect(reservations.foldWidth == 20)
        #expect(reservations.leadingHalfWidth == 390 - ScreenReservations.baseMargin)
        #expect(reservations.trailingHalfWidth == width - 410 - ScreenReservations.baseMargin)
        #expect(reservations.primaryLeadingMargin == 410 + ScreenReservations.baseMargin)
    }

    @Test func horizontalFoldIsIgnoredBecauseItIsNotANet() {
        let fold = CGRect(x: 0, y: 190, width: 800, height: 20)
        let reservations = ScreenReservations(width: width, occlusions: [], divisions: [fold])

        #expect(reservations.fold == nil)
    }
}
