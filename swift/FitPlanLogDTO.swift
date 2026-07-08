import Foundation

public struct FitPlanLog: Codable, Equatable, Sendable {
    public let schemaVersion: String
    public let planName: String
    public let date: String            // "YYYY-MM-DD"
    public let notes: String?
    public let days: [FitPlanLoggedDay]
    public init(schemaVersion: String, planName: String, date: String, notes: String? = nil, days: [FitPlanLoggedDay]) {
        self.schemaVersion = schemaVersion; self.planName = planName; self.date = date; self.notes = notes; self.days = days
    }
}
public struct FitPlanLoggedDay: Codable, Equatable, Sendable {
    public let type: DayType
    public let planDayIndex: Int?
    public let name: String?
    public let notes: String?
    public let workouts: [FitPlanLoggedWorkout]?
    public init(type: DayType, planDayIndex: Int? = nil, name: String? = nil, notes: String? = nil, workouts: [FitPlanLoggedWorkout]? = nil) {
        self.type = type; self.planDayIndex = planDayIndex; self.name = name; self.notes = notes; self.workouts = workouts
    }
}
public enum FitPlanLoggedWorkout: Codable, Equatable, Sendable {
    case strength(name: String, sets: [LoggedStrengthItem])
    case cardio(name: String, activityType: ActivityType, sets: [LoggedCardioItem])
    case other(type: String, name: String)
    private enum K: String, CodingKey { case type, name, activityType, sets }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: K.self)
        let type = try c.decode(String.self, forKey: .type); let name = try c.decode(String.self, forKey: .name)
        switch type {
        case "strength": self = .strength(name: name, sets: try c.decode([LoggedStrengthItem].self, forKey: .sets))
        case "cardio":   self = .cardio(name: name, activityType: try c.decode(ActivityType.self, forKey: .activityType), sets: try c.decode([LoggedCardioItem].self, forKey: .sets))
        default:         self = .other(type: type, name: name)
        }
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: K.self)
        switch self {
        case let .strength(name, sets): try c.encode("strength", forKey: .type); try c.encode(name, forKey: .name); try c.encode(sets, forKey: .sets)
        case let .cardio(name, at, sets): try c.encode("cardio", forKey: .type); try c.encode(name, forKey: .name); try c.encode(at, forKey: .activityType); try c.encode(sets, forKey: .sets)
        case let .other(type, name): try c.encode(type, forKey: .type); try c.encode(name, forKey: .name)
        }
    }
}
public enum LoggedStrengthItem: Codable, Equatable, Sendable {
    case set(LoggedStrengthSet); case block(LoggedStrengthSetBlock)
    private enum K: String, CodingKey { case sets }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: K.self)
        if c.contains(.sets) { self = .block(try LoggedStrengthSetBlock(from: decoder)) } else { self = .set(try LoggedStrengthSet(from: decoder)) }
    }
    public func encode(to encoder: Encoder) throws { switch self { case let .set(s): try s.encode(to: encoder); case let .block(b): try b.encode(to: encoder) } }
}
public struct LoggedStrengthSet: Codable, Equatable, Sendable {
    public let movement: String; public let actualReps: Int; public let actualRounds: Int
    public let actualWeight: Int; public let weightUnit: WeightUnit; public let notes: String?
    public init(movement: String, actualReps: Int, actualRounds: Int, actualWeight: Int, weightUnit: WeightUnit, notes: String? = nil) {
        self.movement = movement; self.actualReps = actualReps; self.actualRounds = actualRounds; self.actualWeight = actualWeight; self.weightUnit = weightUnit; self.notes = notes
    }
}
public struct LoggedStrengthSetBlock: Codable, Equatable, Sendable {
    public let sets: [LoggedStrengthSet]; public let actualReps: Int; public let notes: String?
    public init(sets: [LoggedStrengthSet], actualReps: Int, notes: String? = nil) { self.sets = sets; self.actualReps = actualReps; self.notes = notes }
}
public enum LoggedCardioItem: Codable, Equatable, Sendable {
    case set(LoggedCardioSet); case block(LoggedCardioSetBlock)
    private enum K: String, CodingKey { case sets }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: K.self)
        if c.contains(.sets) { self = .block(try LoggedCardioSetBlock(from: decoder)) } else { self = .set(try LoggedCardioSet(from: decoder)) }
    }
    public func encode(to encoder: Encoder) throws { switch self { case let .set(s): try s.encode(to: encoder); case let .block(b): try b.encode(to: encoder) } }
}
public struct LoggedCardioSet: Codable, Equatable, Sendable {
    public let type: CardioSetType; public let actualDuration: Double; public let durationUnits: DurationUnit
    public let actualEffort: EffortZone?; public let notes: String?
    public init(type: CardioSetType, actualDuration: Double, durationUnits: DurationUnit, actualEffort: EffortZone? = nil, notes: String? = nil) {
        self.type = type; self.actualDuration = actualDuration; self.durationUnits = durationUnits; self.actualEffort = actualEffort; self.notes = notes
    }
}
public struct LoggedCardioSetBlock: Codable, Equatable, Sendable {
    public let sets: [LoggedCardioSet]; public let actualReps: Int; public let notes: String?
    public init(sets: [LoggedCardioSet], actualReps: Int, notes: String? = nil) { self.sets = sets; self.actualReps = actualReps; self.notes = notes }
}
