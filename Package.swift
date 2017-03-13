import PackageDescription

let package = Package(
    name: "Alamofire",
    dependencies: [
        .Package(url: "https://github.com/Alamofire/Alamofire.git", majorVersion: 4)
    ],
    exclude: ["Assets.xcassets", "Crime MapperTests"]
)
