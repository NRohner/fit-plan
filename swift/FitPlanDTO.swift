import Foundation

// MARK: Enums (verbatim from plan.schema.json $defs)
public enum DayType: String, Codable, Sendable { case work, rest }
public enum ActivityType: String, Codable, Sendable {
    case running, cycling, swimming, rowing, gym_cardio, general_cardio
}
public enum DurationUnit: String, Codable, Sendable {
    case seconds, minutes, hours, miles, kilometers, yards, meters
}
public enum EffortZone: String, Codable, Sendable { case z0, z1, z2, z3, z4, z5 }
public enum CardioSetType: String, Codable, Sendable { case warmup, main, cooldown }
public enum WeightUnit: String, Codable, Sendable { case kg, lbs }
public enum BodyPart: String, Codable, Sendable {
    case lower_body, upper_body, core, full_body, chest, bicep, tricep, back,
         shoulder, glute, hamstring, calf, quad, neck, forearm, other
}

// MARK: Movement library
public struct Movement: Codable, Equatable, Sendable {
    public let id: Int
    public let name: String
    public let description: String
    public let bodyPart: BodyPart
    public let notes: String?
    public let link: String?
}

// MARK: Plan
public struct FitPlanPlan: Codable, Equatable, Sendable {
    public let schemaVersion: String
    public let name: String
    public let notes: String?
    public let days: [FitPlanDay]
    public init(schemaVersion: String, name: String, notes: String? = nil, days: [FitPlanDay]) {
        self.schemaVersion = schemaVersion; self.name = name; self.notes = notes; self.days = days
    }
}

public struct FitPlanDay: Codable, Equatable, Sendable {
    public let type: DayType
    public let name: String?
    public let notes: String?
    public let workouts: [FitPlanWorkout]?   // nil on rest days
    public init(type: DayType, name: String? = nil, notes: String? = nil, workouts: [FitPlanWorkout]? = nil) {
        self.type = type; self.name = name; self.notes = notes; self.workouts = workouts
    }
}

/// Discriminated on `type`. Unknown types decode to `.other` (forward-compat).
public enum FitPlanWorkout: Codable, Equatable, Sendable {
    case strength(name: String, sets: [StrengthItem])
    case cardio(name: String, activityType: ActivityType, sets: [CardioItem])
    case other(type: String, name: String)

    private enum K: String, CodingKey { case type, name, activityType, sets }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: K.self)
        let type = try c.decode(String.self, forKey: .type)
        let name = try c.decode(String.self, forKey: .name)
        switch type {
        case "strength": self = .strength(name: name, sets: try c.decode([StrengthItem].self, forKey: .sets))
        case "cardio":   self = .cardio(name: name,
                                        activityType: try c.decode(ActivityType.self, forKey: .activityType),
                                        sets: try c.decode([CardioItem].self, forKey: .sets))
        default:         self = .other(type: type, name: name)
        }
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: K.self)
        switch self {
        case let .strength(name, sets):
            try c.encode("strength", forKey: .type); try c.encode(name, forKey: .name); try c.encode(sets, forKey: .sets)
        case let .cardio(name, at, sets):
            try c.encode("cardio", forKey: .type); try c.encode(name, forKey: .name)
            try c.encode(at, forKey: .activityType); try c.encode(sets, forKey: .sets)
        case let .other(type, name):
            try c.encode(type, forKey: .type); try c.encode(name, forKey: .name)
        }
    }
}

/// oneOf: a block has `sets`; a plain set has `movement`.
public enum StrengthItem: Codable, Equatable, Sendable {
    case set(StrengthSet)
    case block(StrengthSetBlock)
    private enum K: String, CodingKey { case sets }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: K.self)
        if c.contains(.sets) { self = .block(try StrengthSetBlock(from: decoder)) }
        else { self = .set(try StrengthSet(from: decoder)) }
    }
    public func encode(to encoder: Encoder) throws {
        switch self { case let .set(s): try s.encode(to: encoder); case let .block(b): try b.encode(to: encoder) }
    }
}
public struct StrengthSet: Codable, Equatable, Sendable {
    public let movement: String; public let reps: Int; public let rounds: Int
    public let weight: Int; public let weightUnit: WeightUnit
    public init(movement: String, reps: Int, rounds: Int, weight: Int, weightUnit: WeightUnit) {
        self.movement = movement; self.reps = reps; self.rounds = rounds; self.weight = weight; self.weightUnit = weightUnit
    }
}
public struct StrengthSetBlock: Codable, Equatable, Sendable {
    public let sets: [StrengthSet]; public let reps: Int
    public init(sets: [StrengthSet], reps: Int) { self.sets = sets; self.reps = reps }
}

public enum CardioItem: Codable, Equatable, Sendable {
    case set(CardioSet)
    case block(CardioSetBlock)
    private enum K: String, CodingKey { case sets }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: K.self)
        if c.contains(.sets) { self = .block(try CardioSetBlock(from: decoder)) }
        else { self = .set(try CardioSet(from: decoder)) }
    }
    public func encode(to encoder: Encoder) throws {
        switch self { case let .set(s): try s.encode(to: encoder); case let .block(b): try b.encode(to: encoder) }
    }
}
public struct CardioSet: Codable, Equatable, Sendable {
    public let type: CardioSetType; public let duration: Double; public let durationUnits: DurationUnit
    public let effort: EffortZone?; public let notes: String?
    public init(type: CardioSetType, duration: Double, durationUnits: DurationUnit, effort: EffortZone? = nil, notes: String? = nil) {
        self.type = type; self.duration = duration; self.durationUnits = durationUnits; self.effort = effort; self.notes = notes
    }
}
public struct CardioSetBlock: Codable, Equatable, Sendable {
    public let sets: [CardioSet]; public let reps: Int; public let notes: String?
    public init(sets: [CardioSet], reps: Int, notes: String? = nil) { self.sets = sets; self.reps = reps; self.notes = notes }
}
