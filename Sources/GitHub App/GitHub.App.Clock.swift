public import GitHub_Standard
private import Kernel_Core

extension GitHub.App {

    public enum Clock {}
}

extension GitHub.App.Clock {
    public static func now() -> Swift.Int64 {
        Kernel.Time.realtime().secondsSinceUnixEpoch
    }
}
