//
//  OnDeviceNudgeGenerator.swift
//  Just Euchre iOS
//
//  Pure on-device "Apple Intelligence"-style nudges.
//  - Hundreds+ of outcomes via fragment composition.
//  - Non-repeating cycle until exhaustion (then reshuffles).
//

import Foundation

enum OnDeviceNudgeGenerator {

    static func nextNudge() -> String {
        let fragments = FragmentSet.v1
        let index = NudgeCycle.nextIndex(totalCount: fragments.totalCount, version: fragments.version)
        return fragments.phrase(at: index)
    }

    // MARK: - Fragments

    private struct FragmentSet {
        let version: Int
        let openers: [String]
        let actions: [String]
        let addOns: [String]
        let closers: [String]

        var totalCount: UInt64 {
            UInt64(openers.count) * UInt64(actions.count) * UInt64(addOns.count) * UInt64(closers.count)
        }

        func phrase(at index: UInt64) -> String {
            let o = UInt64(openers.count)
            let a = UInt64(actions.count)
            let x = UInt64(addOns.count)
            let c = UInt64(closers.count)

            var i = index
            let opener = openers[Int(i % o)]
            i /= o
            let action = actions[Int(i % a)]
            i /= a
            let addOn = addOns[Int(i % x)]
            i /= x
            let closer = closers[Int(i % c)]

            // Keep it on one line and avoid awkward double spaces.
            return "\(opener) \(action)\(addOn)\(closer)".replacingOccurrences(of: "  ", with: " ")
        }

        static let v1 = FragmentSet(
            version: 1,
            openers: [
                "GG.",
                "Nice run.",
                "Solid session.",
                "That was crisp.",
                "We take those.",
                "Cards down.",
                "Table cleared.",
                "Score posted.",
                "Euchre accomplished.",
                "Victory (or character-building).",
                "The deck has spoken.",
                "Good hustle.",
                "Respectable chaos.",
                "Clean plays.",
                "Good vibes.",
                "Well played.",
                "Mission complete.",
                "Another hand in the books.",
                "All tricks counted.",
                "Time-out, champ.",
                "Okay, legend.",
                "Alright, hero.",
                "You survived.",
                "You cooked.",
                "You battled.",
                "You earned a breather.",
                "That’s enough dopamine.",
                "Phone: 0. You: 1.",
                "Your thumbs did work.",
                "End of the line.",
            ],
            actions: [
                "Go touch grass for 3 minutes",
                "Stand up and stretch",
                "Drink a glass of water",
                "Take 10 deep breaths",
                "Do 15 squats",
                "Do 10 push-ups (or wall push-ups)",
                "Walk to a window and look outside",
                "Start the laundry",
                "Put one dish in the dishwasher",
                "Make your bed",
                "Take out the trash",
                "Tidy one surface",
                "Send a quick “thinking of you” text",
                "Go hug someone (or your pet)",
                "Check in on a friend",
                "Step outside and get sunlight",
                "Take a short walk",
                "Roll your shoulders and unclench your jaw",
                "Fix your posture like you mean it",
                "Do a 2-minute plank (or try)",
                "Knock out one tiny chore",
                "Pick one task and start it badly",
                "Open your notes and write one idea",
                "Do the “future you” favor",
                "Put your phone face-down",
                "Charge your phone in another room",
                "Take a screen break",
                "Go be a person for a bit",
                "Do something kind, right now",
                "Do something amazing today",
                "Touch something that isn’t glass",
                "Go earn your snack",
                "Take a 5-minute “reset”",
                "Move your body",
                "Go touch grass (respectfully)",
                "Be less lazy for exactly one minute",
                "Go win real life for a second",
                "Go do the thing you’ve been avoiding",
                "Make future-you proud",
                "Go get a small win offline",
            ],
            addOns: [
                ".",
                "—seriously.",
                " (timer helps).",
                " while you still remember legs exist.",
                " before the couch claims you.",
                " and come back refreshed.",
                " and don’t negotiate with yourself.",
                " like it’s a side quest.",
                " like you’re the main character.",
                " for your brain’s sake.",
                " for your spine’s sake.",
                " for your vibe’s sake.",
                " then reward yourself.",
                " then you can brag.",
                " then you can doomscroll with honor.",
                " then you can play again.",
                " and make it weirdly easy.",
                " and keep it small.",
                " and keep it real.",
                " and keep it moving.",
                " and do it imperfectly.",
                " and do it now-ish.",
                " and pretend it’s urgent.",
                " like it’s non-negotiable.",
                " like you promised yourself.",
                " like you’re on autopilot (good).",
                " with the confidence of a dealer button.",
                " with zero drama.",
                " with maximum dignity.",
                " with minimal complaining.",
            ],
            closers: [
                " You’ve got this.",
                " You’ll thank you.",
                " Your future self is watching.",
                " Your body will notice.",
                " Your brain will unclog.",
                " Consider it a victory lap.",
                " This is the real flex.",
                " Legendary behavior.",
                " Do it for the plot.",
                " One small thing counts.",
                " Tiny steps still win.",
                " Go be iconic.",
                " Don’t forget you’re alive.",
                " Make it a good day.",
                " Be nice to yourself.",
                " Proud of you (go).",
                " The app will wait.",
                " The deck isn’t going anywhere.",
                " Seriously: phone down.",
                " Touch grass, then return.",
            ]
        )
    }

    // MARK: - Non-repeating cycle

    private enum NudgeCycle {
        private static let startKey = "justeuchre.nudgeCycle.start"
        private static let stepKey = "justeuchre.nudgeCycle.step"
        private static let cursorKey = "justeuchre.nudgeCycle.cursor"
        private static let versionKey = "justeuchre.nudgeCycle.version"
        private static let countKey = "justeuchre.nudgeCycle.count"

        static func nextIndex(totalCount: UInt64, version: Int) -> UInt64 {
            guard totalCount > 0 else { return 0 }
            let defaults = UserDefaults.standard

            let storedVersion = defaults.integer(forKey: versionKey)
            let storedCount = defaults.object(forKey: countKey) as? NSNumber
            let storedCountValue = storedCount?.uint64Value

            if storedVersion != version || storedCountValue != totalCount {
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
            // Try a few random candidates; fall back to 1 (always coprime).
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

