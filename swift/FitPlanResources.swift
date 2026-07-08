import Foundation

public enum FitPlanResources {
    public static func data(_ resource: String, _ ext: String) throws -> Data {
        guard let url = Bundle.module.url(forResource: resource, withExtension: ext) else {
            throw NSError(domain: "FitPlanSchema", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "missing resource \(resource).\(ext)"])
        }
        return try Data(contentsOf: url)
    }

    public static func movements() throws -> [Movement] {
        try JSONDecoder().decode([Movement].self, from: data("movements", "json"))
    }

    /// The `examples/` dir is copied whole via `.copy("examples")`, so it lands as a
    /// subdirectory inside the resource bundle. Resolve files within it.
    public static func example(_ name: String) throws -> Data {
        guard let dir = Bundle.module.url(forResource: "examples", withExtension: nil) else {
            throw NSError(domain: "FitPlanSchema", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "missing examples dir"])
        }
        return try Data(contentsOf: dir.appendingPathComponent(name))
    }
}
