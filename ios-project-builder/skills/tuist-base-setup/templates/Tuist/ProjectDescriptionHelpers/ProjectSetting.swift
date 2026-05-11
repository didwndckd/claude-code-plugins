import ProjectDescription

public enum ProjectSetting {
    public static let base: Settings = .settings(
        configurations: [
            .debug(name: .debug, xcconfig: XCConfig.base),
            .release(name: .release, xcconfig: XCConfig.base),
        ]
    )

    public static let app: Settings = .settings(
        configurations: [
            .debug(name: .debug, xcconfig: XCConfig.app),
            .release(name: .release, xcconfig: XCConfig.app),
        ]
    )
}
