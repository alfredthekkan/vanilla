// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Hello",
    products: [
        .library(name: "Hello", targets: ["App"]),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),

<<<<<<< HEAD
        .package(url: "https://github.com/vapor/postgresql.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0-rc"),
        .package(url: "https://github.com/vapor/auth.git", from: "2.0.0-rc"),  // added
        .package(url: "https://github.com/vapor/redis.git", from: "3.0.0")
    ],
    targets: [
        .target(name: "App", dependencies: ["FluentPostgreSQL", "Vapor", "Authentication", "Redis"]),
=======
        // 🔵 Swift ORM (queries, models, relations, etc) built on SQLite 3.
        .package(url: "https://github.com/vapor/fluent-sqlite.git", from: "3.0.0")
    ],
    targets: [
        .target(name: "App", dependencies: ["FluentSQLite", "Vapor"]),
>>>>>>> eb72ad783fb5417ff63f800bc441b58ec3676293
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

