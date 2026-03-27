//
//  BotNameGenerator.swift
//  Just Euchre iOS
//
//  Real-ish bot names (<= 8 chars) with a non-repeating cycle.
//

import Foundation

enum BotNameGenerator {

    static func nextBotNames(count: Int) -> [String] {
        let pool = NamePool.v1
        guard count > 0 else { return [] }
        let requested = min(count, pool.names.count)

        var picked: [String] = []
        picked.reserveCapacity(requested)

        var safety = 0
        while picked.count < requested && safety < pool.names.count * 2 {
            safety += 1
            let idx = NameCycle.nextIndex(totalCount: UInt64(pool.names.count), version: pool.version)
            let name = pool.names[Int(idx)]
            if !picked.contains(name) {
                picked.append(name)
            }
        }

        // Fallback: fill from the pool if something went wrong.
        if picked.count < requested {
            for name in pool.names where !picked.contains(name) {
                picked.append(name)
                if picked.count == requested { break }
            }
        }

        return picked
    }

    private struct NamePool {
        let version: Int
        let names: [String]

        static let v1 = NamePool(
            version: 1,
            names: [
                "Avery", "Blake", "Carter", "Drew", "Emmett", "Finley", "Graham", "Hayden",
                "Iris", "Jasper", "Kai", "Logan", "Mason", "Nolan", "Olivia", "Parker",
                "Quinn", "Rowan", "Sage", "Tatum", "Uma", "Violet", "Wes", "Xander",
                "Yara", "Zoe",

                "Amelia", "Aria", "Ari", "Ben", "Chloe", "Cole", "Dylan", "Eli",
                "Eva", "Ezra", "Fiona", "Gwen", "Holly", "Ivy", "Jack", "Juno",
                "Kira", "Liam", "Luna", "Mila", "Mia", "Noah", "Nova", "Owen",
                "Remy", "Riley", "Skye", "Theo", "Vera", "Will",

                "Adrian", "Aileen", "Alyssa", "Anya", "Asher", "Aston", "Bea", "Bella",
                "Caleb", "Cleo", "Daisy", "Elena", "Evan", "Felix", "Freya", "Harris",
                "Henry", "Isla", "Jonah", "Josie", "Keira", "Leah", "Margo", "Miles",
                "Mira", "Naomi", "Nina", "Orla", "Oscar", "Piper",

                "Reese", "Rory", "Sadie", "Selene", "Simon", "Sofia", "Stella", "Summer",
                "Tessa", "Tristan", "Umair", "Willa", "Winston", "Zara",
            ]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count <= 8 }
        )
    }

    private enum NameCycle {
        private static let startKey = "justeuchre.botnames.start"
        private static let stepKey = "justeuchre.botnames.step"
        private static let cursorKey = "justeuchre.botnames.cursor"
        private static let versionKey = "justeuchre.botnames.version"
        private static let countKey = "justeuchre.botnames.count"

        static func nextIndex(totalCount: UInt64, version: Int) -> UInt64 {
            guard totalCount > 0 else { return 0 }
            let defaults = UserDefaults.standard

            let storedVersion = defaults.integer(forKey: versionKey)
            let storedCount = (defaults.object(forKey: countKey) as? NSNumber)?.uint64Value
            if storedVersion != version || storedCount != totalCount {
                reseed(totalCount: totalCount, version: version, defaults: defaults)
            }

            var start = (defaults.object(forKey: startKey) as? NSNumber)?.uint64Value ?? 0
            var step = (defaults.object(forKey: stepKey) as? NSNumber)?.uint64Value ?? 1
            var cursor = (defaults.object(forKey: cursorKey) as? NSNumber)?.uint64Value ?? 0

            if start >= totalCount || step == 0 || gcd(step, totalCount) != 1 {
                reseed(totalCount: totalCount, version: version, defaults: defaults)
                start = (defaults.object(forKey: startKey) as? NSNumber)?.uint64Value ?? 0
                step = (defaults.object(forKey: stepKey) as? NSNumber)?.uint64Value ?? 1
                cursor = (defaults.object(forKey: cursorKey) as? NSNumber)?.uint64Value ?? 0
            }

            if cursor >= totalCount {
                reseed(totalCount: totalCount, version: version, defaults: defaults)
                start = (defaults.object(forKey: startKey) as? NSNumber)?.uint64Value ?? 0
                step = (defaults.object(forKey: stepKey) as? NSNumber)?.uint64Value ?? 1
                cursor = (defaults.object(forKey: cursorKey) as? NSNumber)?.uint64Value ?? 0
            }

            let idx = (start &+ (step &* cursor)) % totalCount
            defaults.set(NSNumber(value: cursor &+ 1), forKey: cursorKey)
            return idx
        }

        private static func reseed(totalCount: UInt64, version: Int, defaults: UserDefaults) {
            let start = UInt64.random(in: 0..<totalCount)
            let step = randomCoprimeStep(modulus: totalCount)
            defaults.set(NSNumber(value: start), forKey: startKey)
            defaults.set(NSNumber(value: step), forKey: stepKey)
            defaults.set(NSNumber(value: 0 as UInt64), forKey: cursorKey)
            defaults.set(version, forKey: versionKey)
            defaults.set(NSNumber(value: totalCount), forKey: countKey)
        }

        private static func randomCoprimeStep(modulus: UInt64) -> UInt64 {
            guard modulus > 1 else { return 1 }
            for _ in 0..<24 {
                let candidate = UInt64.random(in: 1..<modulus)
                if gcd(candidate, modulus) == 1 { return candidate }
            }
            return 1
        }

        private static func gcd(_ a: UInt64, _ b: UInt64) -> UInt64 {
            var x = a
            var y = b
            while y != 0 {
                let t = x % y
                x = y
                y = t
            }
            return x
        }
    }
}

