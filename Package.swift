import PackageDescription

let package = Package(
    name: "SlackBot",
    dependencies: [
      .Package(url: "https://github.com/qutheory/vapor-tls", majorVersion: 0, minor: 2)
    ],
    exclude: [
        "Images"
    ]
)
