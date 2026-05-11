import ProjectDescription

public enum BundleID {
    private static let base = "com.didwndckd"

    public static func create(_ name: String) -> String {
        "\(base).\(name)"
    }
}
