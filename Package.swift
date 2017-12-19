import PackageDescription

let package = Package(
    name: "haall",
    targets: [
        Target(name: "App"),
        Target(name: "Run", dependencies: ["App"]),
    ],
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 2),
        .Package(url: "https://github.com/vapor/fluent-provider.git", majorVersion: 1),
        .Package(url: "https://github.com/vapor/leaf-provider.git", majorVersion: 1),
        .Package(url: "https://github.com/vapor/mysql-provider.git", majorVersion: 2),
        .Package(url: "https://github.com/vapor/redis-provider", majorVersion: 2),
        .Package(url: "https://github.com/vapor/leaf-provider.git", majorVersion: 1),
        .Package(url: "https://github.com/vapor/auth-provider.git", majorVersion: 1),
        .Package(url: "https://github.com/nodes-vapor/flash.git", majorVersion: 1),
        .Package(url: "https://github.com/vapor/validation-provider.git", majorVersion: 1),
        .Package(url: "https://github.com/nodes-vapor/paginator", majorVersion: 1),
        .Package(url: "https://github.com/Kawoou/AnyDate", majorVersion: 1),
        .Package(url: "https://github.com/vapor/jwt-provider.git", majorVersion: 1)
    ],
    exclude: [
        "Config",
        "Database",
        "Localization",
        "Public",
        "Resources",
    ]
)

