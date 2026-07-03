import XCTest
import SwiftUI
@testable import SetLogKit

final class FalseColorTests: XCTestCase {

    func testSeverityEndpoints() {
        // 0 = good = green (hue 0.33), 1 = bad = red (hue 0).
        XCTAssertEqual(FalseColor.severity(0), Color(hue: 0.33, saturation: 0.85, brightness: 0.9))
        XCTAssertEqual(FalseColor.severity(1), Color(hue: 0, saturation: 0.85, brightness: 0.9))
    }

    func testSeverityClampsOutOfRange() {
        XCTAssertEqual(FalseColor.severity(-5), FalseColor.severity(0))
        XCTAssertEqual(FalseColor.severity(7), FalseColor.severity(1))
    }

    func testAxisPolarity() {
        // Technique: 10 = good; exertion/discomfort: 1 = good.
        XCTAssertEqual(FalseColor.technique(10), FalseColor.severity(0))
        XCTAssertEqual(FalseColor.technique(1), FalseColor.severity(1))
        XCTAssertEqual(FalseColor.exertion(1), FalseColor.severity(0))
        XCTAssertEqual(FalseColor.exertion(10), FalseColor.severity(1))
        XCTAssertEqual(FalseColor.discomfort(1), FalseColor.severity(0))
        XCTAssertEqual(FalseColor.discomfort(10), FalseColor.severity(1))
    }
}
