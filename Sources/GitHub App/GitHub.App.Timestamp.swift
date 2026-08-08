// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-github open source project
//
// Copyright (c) 2026 Coen ten Thije Boonkkamp and the swift-github project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

public import GitHub_Standard

extension GitHub.App {
    /// The RFC 3339 instants GitHub puts in `expires_at`, as POSIX seconds.
    ///
    /// Reading GitHub's own expiry rather than adding an hour to a local clock
    /// matters: the two disagree by however far this machine's clock has
    /// drifted, and the direction that matters — a fast local clock — produces
    /// a cache entry that outlives the credential it describes.
    public enum Timestamp {}
}

extension GitHub.App.Timestamp {
    /// Parses `YYYY-MM-DDTHH:MM:SSZ`, the only shape GitHub emits here.
    ///
    /// Deliberately strict. A tolerant parser that accepted an offset it then
    /// ignored would place expiry hours away from the truth, and the failure —
    /// a token treated as fresh past its death — appears as an unexplained 401
    /// somewhere else entirely.
    public static func seconds(from value: Swift.String) -> Swift.Int64? {
        let scalars = Array(value.utf8)
        guard scalars.count == 20, scalars[19] == UInt8(ascii: "Z") else { return nil }
        guard
            scalars[4] == UInt8(ascii: "-"), scalars[7] == UInt8(ascii: "-"),
            scalars[10] == UInt8(ascii: "T"),
            scalars[13] == UInt8(ascii: ":"), scalars[16] == UInt8(ascii: ":")
        else { return nil }

        func number(_ range: Swift.Range<Swift.Int>) -> Swift.Int64? {
            var result: Swift.Int64 = 0
            for index in range {
                let digit = scalars[index]
                guard digit >= UInt8(ascii: "0"), digit <= UInt8(ascii: "9") else { return nil }
                result = result * 10 + Swift.Int64(digit - UInt8(ascii: "0"))
            }
            return result
        }

        guard
            let year = number(0..<4),
            let month = number(5..<7),
            let day = number(8..<10),
            let hour = number(11..<13),
            let minute = number(14..<16),
            let second = number(17..<19),
            (1...12).contains(month), (1...31).contains(day),
            hour < 24, minute < 60, second < 61
        else { return nil }

        return days(year: year, month: month, day: day) * 86_400
            + hour * 3_600 + minute * 60 + second
    }

    /// Howard Hinnant's `days_from_civil`: the proleptic Gregorian day number
    /// relative to 1970-01-01, exact for every year this will ever see.
    static func days(year: Swift.Int64, month: Swift.Int64, day: Swift.Int64) -> Swift.Int64 {
        let shifted = year - (month <= 2 ? 1 : 0)
        let era = (shifted >= 0 ? shifted : shifted - 399) / 400
        let yearOfEra = shifted - era * 400
        let dayOfYear = (153 * (month + (month > 2 ? -3 : 9)) + 2) / 5 + day - 1
        let dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear
        return era * 146_097 + dayOfEra - 719_468
    }
}
