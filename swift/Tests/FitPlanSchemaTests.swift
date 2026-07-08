import XCTest
@testable import FitPlanSchema

final class FitPlanSchemaTests: XCTestCase {
    func testDecodesAll873Movements() throws {
        let m = try FitPlanResources.movements()
        XCTAssertEqual(m.count, 873)
        XCTAssertFalse(m[0].name.isEmpty)
    }
    func testPlanExampleRoundTrips() throws {
        let data = try FitPlanResources.example("plan.example.json")
        let plan = try JSONDecoder().decode(FitPlanPlan.self, from: data)
        XCTAssertEqual(plan.days.count, 3)
        XCTAssertEqual(plan.days.last?.type, .rest)
        XCTAssertNil(plan.days.last?.workouts)               // rest ⇒ no workouts
        let re = try JSONDecoder().decode(FitPlanPlan.self, from: JSONEncoder().encode(plan))
        XCTAssertEqual(plan, re)
    }
    func testLogExampleRoundTrips() throws {
        let data = try FitPlanResources.example("log.example.json")
        let log = try JSONDecoder().decode(FitPlanLog.self, from: data)
        XCTAssertEqual(log.planName, "Sample 3-Day Split")
        let re = try JSONDecoder().decode(FitPlanLog.self, from: JSONEncoder().encode(log))
        XCTAssertEqual(log, re)
    }
    func testUnknownWorkoutTypeDecodesToOther() throws {
        let json = #"{"type":"yoga","name":"Flow"}"#.data(using: .utf8)!
        let w = try JSONDecoder().decode(FitPlanWorkout.self, from: json)
        guard case .other(let t, let n) = w else { return XCTFail("expected .other") }
        XCTAssertEqual(t, "yoga"); XCTAssertEqual(n, "Flow")
    }
}
