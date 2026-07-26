import Testing
@testable import SmartEFB

struct POHValidatorTests {
    private func point(
        altitude: Double, temperature: Double, weight: Double,
        roll: Double, over50: Double
    ) -> POHExtraction.PointDTO {
        POHExtraction.PointDTO(
            pressureAltitudeFt: altitude, temperatureC: temperature, weightKg: weight,
            groundRollM: roll, distanceOver50ftM: over50
        )
    }

    // MARK: Point cleaning

    @Test func dropsPointsWithMissingOrImplausibleValues() {
        let extraction = POHExtraction(takeoffPoints: [
            point(altitude: 0, temperature: 15, weight: 800, roll: 300, over50: 500),
            // Implausible: distance far beyond a light aircraft's range.
            point(altitude: 0, temperature: 25, weight: 800, roll: 300, over50: 99000),
            // Missing temperature.
            POHExtraction.PointDTO(pressureAltitudeFt: 0, weightKg: 800, groundRollM: 300, distanceOver50ftM: 500)
        ])

        let result = POHValidator.validate(extraction)
        #expect(result.takeoffTable?.points.count == 1)
        #expect(result.warnings.contains { $0.contains("verworfen") })
    }

    @Test func repairsSwappedRollAndObstacleDistance() throws {
        let extraction = POHExtraction(takeoffPoints: [
            point(altitude: 0, temperature: 15, weight: 800, roll: 500, over50: 300)
        ])

        let result = POHValidator.validate(extraction)
        let repaired = try #require(result.takeoffTable?.points.first)
        #expect(repaired.groundRollM == 300)
        #expect(repaired.distanceOver50ftM == 500)
        #expect(result.warnings.contains { $0.contains("vertauscht") })
    }

    @Test func flagsPointsThatContradictTheExpectedTrend() {
        // Distance falls as pressure altitude rises, which is physically wrong.
        let extraction = POHExtraction(takeoffPoints: [
            point(altitude: 0, temperature: 15, weight: 800, roll: 300, over50: 500),
            point(altitude: 4000, temperature: 15, weight: 800, roll: 250, over50: 400)
        ])

        let result = POHValidator.validate(extraction)
        #expect(result.warnings.contains { $0.contains("Verlauf") })
    }

    @Test func reportsWhenNothingCouldBeRead() {
        let result = POHValidator.validate(POHExtraction())
        #expect(result.isEmpty)
        #expect(result.warnings.contains { $0.contains("keine belastbaren") })
    }

    // MARK: Corrections

    @Test func interpretsCorrectionsGivenAsPercent() throws {
        let extraction = POHExtraction(
            takeoffPoints: [point(altitude: 0, temperature: 15, weight: 800, roll: 300, over50: 500)],
            takeoffCorrections: POHExtraction.CorrectionsDTO(
                headwindPercentPerKt: -1.3, tailwindPercentPerKt: 5,
                grassFactor: 1.2, wetFactor: 1.1, slopePercentPerPercent: 7
            )
        )

        let corrections = try #require(POHValidator.validate(extraction).takeoffTable?.corrections)
        #expect(abs(corrections.headwindPerKt - (-0.013)) < 0.0001)
        #expect(abs(corrections.tailwindPerKt - 0.05) < 0.0001)
        #expect(abs(corrections.slopePerPercent - 0.07) < 0.0001)
        #expect(abs(corrections.grassFactor - 1.2) < 0.0001)
    }

    @Test func acceptsCorrectionsAlreadyGivenAsFraction() throws {
        let extraction = POHExtraction(
            takeoffPoints: [point(altitude: 0, temperature: 15, weight: 800, roll: 300, over50: 500)],
            takeoffCorrections: POHExtraction.CorrectionsDTO(headwindPercentPerKt: -0.012)
        )

        let corrections = try #require(POHValidator.validate(extraction).takeoffTable?.corrections)
        #expect(abs(corrections.headwindPerKt - (-0.012)) < 0.0001)
    }

    @Test func forcesHeadwindToShortenTheDistance() throws {
        // A positive headwind factor would lengthen the distance — never correct.
        let extraction = POHExtraction(
            takeoffPoints: [point(altitude: 0, temperature: 15, weight: 800, roll: 300, over50: 500)],
            takeoffCorrections: POHExtraction.CorrectionsDTO(headwindPercentPerKt: 1.3)
        )

        let corrections = try #require(POHValidator.validate(extraction).takeoffTable?.corrections)
        #expect(corrections.headwindPerKt < 0)
    }

    @Test func fallsBackToDefaultsForOutOfRangeCorrections() throws {
        let extraction = POHExtraction(
            takeoffPoints: [point(altitude: 0, temperature: 15, weight: 800, roll: 300, over50: 500)],
            takeoffCorrections: POHExtraction.CorrectionsDTO(grassFactor: 9, wetFactor: 0.2)
        )

        let corrections = try #require(POHValidator.validate(extraction).takeoffTable?.corrections)
        #expect(corrections.grassFactor == PerformanceCorrections.takeoffDefaults.grassFactor)
        #expect(corrections.wetFactor == PerformanceCorrections.takeoffDefaults.wetFactor)
    }

    // MARK: Cross-check against the POH's worked example

    @Test func verificationPassesWhenTheGridReproducesTheExample() throws {
        let extraction = POHExtraction(
            takeoffPoints: [point(altitude: 3000, temperature: 15, weight: 675, roll: 330, over50: 470)],
            // No wind correction, so the example's 0 kt maps straight onto the grid.
            takeoffCorrections: POHExtraction.CorrectionsDTO(headwindPercentPerKt: 0),
            verification: POHExtraction.VerificationDTO(
                isTakeoff: true, pressureAltitudeFt: 3000, temperatureC: 15, weightKg: 675,
                headwindKt: 0, expectedGroundRollM: 330, expectedDistanceOver50ftM: 470
            )
        )

        let outcome = try #require(POHValidator.validate(extraction).verification)
        #expect(outcome.passed)
        #expect(outcome.maxDeviationPercent < 0.01)
    }

    @Test func verificationFailsAndWarnsWhenTheGridIsWrong() throws {
        let extraction = POHExtraction(
            takeoffPoints: [point(altitude: 3000, temperature: 15, weight: 675, roll: 330, over50: 470)],
            takeoffCorrections: POHExtraction.CorrectionsDTO(headwindPercentPerKt: 0),
            verification: POHExtraction.VerificationDTO(
                isTakeoff: true, pressureAltitudeFt: 3000, temperatureC: 15, weightKg: 675,
                headwindKt: 0, expectedGroundRollM: 330, expectedDistanceOver50ftM: 900
            )
        )

        let result = POHValidator.validate(extraction)
        let outcome = try #require(result.verification)
        #expect(outcome.passed == false)
        #expect(result.warnings.contains { $0.contains("Gegenrechnung") })
    }

    @Test func verificationAppliesTheWindCorrectionBeforeComparing() throws {
        // Chart value 500 m at 0 kt; with -1 % per kt and 10 kt the POH example
        // should read 450 m.
        let extraction = POHExtraction(
            takeoffPoints: [point(altitude: 0, temperature: 15, weight: 800, roll: 300, over50: 500)],
            takeoffCorrections: POHExtraction.CorrectionsDTO(headwindPercentPerKt: -1),
            verification: POHExtraction.VerificationDTO(
                isTakeoff: true, pressureAltitudeFt: 0, temperatureC: 15, weightKg: 800,
                headwindKt: 10, expectedGroundRollM: 270, expectedDistanceOver50ftM: 450
            )
        )

        let outcome = try #require(POHValidator.validate(extraction).verification)
        #expect(abs(outcome.computedDistanceOver50ftM - 450) < 0.01)
        #expect(outcome.passed)
    }

    @Test func noVerificationWhenThePageHasNoWorkedExample() {
        let extraction = POHExtraction(
            takeoffPoints: [point(altitude: 0, temperature: 15, weight: 800, roll: 300, over50: 500)]
        )
        #expect(POHValidator.validate(extraction).verification == nil)
    }
}
