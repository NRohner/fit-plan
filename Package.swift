// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "FitPlanSchema",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "FitPlanSchema", targets: ["FitPlanSchema"])
    ],
    targets: [
        .target(
            name: "FitPlanSchema",
            path: ".",
            exclude: [
                "validate.mjs",
                "README.md",
                "LLM_GUIDE.md",
                ".gitattributes",
                "swift/Tests"
            ],
            sources: ["swift"],
            resources: [
                .copy("movements.json"),
                .copy("plan.schema.json"),
                .copy("log.schema.json"),
                .copy("movement.schema.json"),
                .copy("examples")
            ]
        ),
        .testTarget(
            name: "FitPlanSchemaTests",
            dependencies: ["FitPlanSchema"],
            path: "swift/Tests"
        )
    ]
)
