//
//  PartnerPersona.swift
//  Just Euchre iOS
//
//  Defines all partner personas with curated dialog for in-game table talk.
//  Dialog never reveals hand contents or gives strategic advice — just character.
//

import Foundation

// MARK: - Trigger

enum PartnerDialogTrigger {
    case weTookTrick       // Our team won a trick
    case theyTookTrick     // Opponent team won a trick
    case weScored          // Our team scored points at end of hand
    case theyScored        // Opponents scored at end of hand
    case euchred           // We got euchred (set)
    case marched           // We swept all 5 tricks
    case weWon             // Game over — we won
    case weLost            // Game over — we lost
    case trumpMade         // Trump was established (either team)
    case idleComment       // Random table talk during play
}

// MARK: - Persona

struct PartnerPersona {
    let id: String
    let name: String
    let emoji: String
    let tagline: String      // Short personality label shown in intro
    let introLine: String    // Opening quip in partner intro screen

    let weTookTrick: [String]
    let theyTookTrick: [String]
    let weScored: [String]
    let theyScored: [String]
    let euchred: [String]
    let marched: [String]
    let weWon: [String]
    let weLost: [String]
    let trumpMade: [String]
    let idleComment: [String]

    func lines(for trigger: PartnerDialogTrigger) -> [String] {
        switch trigger {
        case .weTookTrick:   return weTookTrick
        case .theyTookTrick: return theyTookTrick
        case .weScored:      return weScored
        case .theyScored:    return theyScored
        case .euchred:       return euchred
        case .marched:       return marched
        case .weWon:         return weWon
        case .weLost:        return weLost
        case .trumpMade:     return trumpMade
        case .idleComment:   return idleComment
        }
    }

    func randomLine(for trigger: PartnerDialogTrigger) -> String {
        lines(for: trigger).randomElement() ?? "..."
    }
}

// MARK: - All Personas

extension PartnerPersona {

    // 1. The Overconfident Regular
    static let rex = PartnerPersona(
        id: "rex",
        name: "Rex",
        emoji: "😎",
        tagline: "Never lost a game. According to Rex.",
        introLine: "Just follow my lead. I've won every hand I've ever played. Mostly.",
        weTookTrick: [
            "Textbook.",
            "That's how it's done.",
            "Exactly as planned.",
            "You're welcome.",
            "Obviously.",
            "I called that one.",
            "Smooth.",
        ],
        theyTookTrick: [
            "Fluke.",
            "I let them have that one.",
            "Statistically unlikely to happen again.",
            "Tactical.",
            "Noted.",
            "We'll get it back.",
            "That one's on the cards, not me.",
        ],
        weScored: [
            "Right on schedule.",
            "Running exactly according to my projections.",
            "As expected.",
            "Points up, ego intact.",
            "Told you.",
            "Classic.",
        ],
        theyScored: [
            "A temporary setback.",
            "I've come back from worse. Much worse.",
            "They got lucky.",
            "Fine. Let them have their moment.",
            "This is still very much winnable.",
            "Don't panic. I never panic.",
        ],
        euchred: [
            "That was... a strategic sacrifice.",
            "I don't want to talk about it.",
            "That's not going in my highlight reel.",
            "Interesting choice by the universe.",
            "Everyone makes one mistake. That was mine.",
            "We agreed to never discuss this.",
        ],
        marched: [
            "March. As expected.",
            "A sweep. Just like practice.",
            "The bots never had a chance.",
            "Five for five. Classic Rex.",
            "I could do this in my sleep.",
            "Full send. Dominant performance.",
        ],
        weWon: [
            "Did anyone really doubt this?",
            "I'd like to thank me for this win.",
            "Another day, another W.",
            "Dominant performance from both of us. Mostly me.",
            "No surprises here.",
            "Twenty-one. That's a scoreboard.",
        ],
        weLost: [
            "I've been robbed.",
            "The cards were against us from the start.",
            "I demand a rematch.",
            "In my forty years of Euchre, I have never—",
            "This is historic levels of bad luck.",
            "Record scratch. This didn't happen.",
        ],
        trumpMade: [
            "Smart call.",
            "Works for me.",
            "Risky. Bold. Possibly my strategy.",
            "I would've done the same.",
            "That's a move.",
        ],
        idleComment: [
            "I've been doing this since before you were born.",
            "The bots look nervous.",
            "I'm basically reading their minds right now.",
            "Just so you know, I've memorized every card.",
            "Euchre is 90% skill. The other 90% is also skill.",
            "We're going to be fine. I'm always fine.",
        ]
    )

    // 2. The Reluctant Grandparent
    static let eunice = PartnerPersona(
        id: "eunice",
        name: "Eunice",
        emoji: "🧓",
        tagline: "Would rather be watching her stories.",
        introLine: "Fine, fine. Deal the cards. But I want to be home by four.",
        weTookTrick: [
            "Oh, we got one.",
            "Good, good.",
            "My hip is acting up and we still managed that.",
            "See? I can still play.",
            "Nice, dear.",
            "That'll do.",
        ],
        theyTookTrick: [
            "Oh dear.",
            "Well that's not good.",
            "I was distracted. Something smelled funny.",
            "These things happen.",
            "Where's the snack? I need a snack.",
            "Is it over yet?",
        ],
        weScored: [
            "Oh wonderful. Can we speed this up?",
            "Points! Now can I go watch my show?",
            "That's nice, dear.",
            "We're doing it. I suppose.",
            "How many more of these?",
            "Very good. Very, very good.",
        ],
        theyScored: [
            "I don't like those two.",
            "Something about them feels shifty.",
            "In my day we just played Go Fish.",
            "Is it over yet?",
            "I blame the shuffling.",
            "Hmm. Well.",
        ],
        euchred: [
            "What does euchred even mean?",
            "I knew I should've stayed home.",
            "This never happened to me in bingo.",
            "I blame the shuffling.",
            "My late husband was much better at this.",
            "Nobody wins them all, honey.",
        ],
        marched: [
            "All five? My goodness.",
            "Did we just win all of them?",
            "I feel young again.",
            "My late husband would have loved to see this.",
            "We swept the table, didn't we? Lovely.",
            "Well. Would you look at that.",
        ],
        weWon: [
            "Finally. Now I can go home.",
            "We won? Oh that's lovely.",
            "I'll call my daughter. She won't believe this.",
            "Lovely game. Now where's my coat?",
            "That was wonderful. I'm exhausted.",
            "Good game. Time for my stories.",
        ],
        weLost: [
            "This is fine. I'm fine.",
            "I've lived through worse, believe me.",
            "Next time I'm bringing my reading glasses.",
            "We did our best. That's what matters.",
            "Do you want a piece of hard candy? I have hard candy.",
            "Well. There's always tomorrow.",
        ],
        trumpMade: [
            "Is that good?",
            "Trump, they say. Mm.",
            "Okay. Mm-hmm.",
            "Whatever you think is best, dear.",
            "Sure, sure.",
        ],
        idleComment: [
            "You remind me of my grandson.",
            "I should be asleep right now.",
            "It's a little cold in here.",
            "When do we get to the snacks?",
            "My hands are fine. I'm fine. Don't ask.",
            "This is actually fun. Don't tell anyone.",
        ]
    )

    // 3. The Sports Analyst
    static let chad = PartnerPersona(
        id: "chad",
        name: "Chad",
        emoji: "📊",
        tagline: "Calls every trick like it's the seventh game of the World Series.",
        introLine: "I've been studying your game tape. Solid fundamentals. Let's get a W.",
        weTookTrick: [
            "And that's a clean takedown in the paint.",
            "Big play. Big play.",
            "That's a highlight reel right there.",
            "The crowd goes wild.",
            "We own this lane.",
            "Clean execution. Love to see it.",
            "First and goal, baby.",
        ],
        theyTookTrick: [
            "We gotta tighten up the defense.",
            "That'll show up on the tape.",
            "Gotta respect their athleticism.",
            "We'll get it back. We've got the momentum.",
            "Adjustments needed.",
            "Championship teams respond to adversity.",
        ],
        weScored: [
            "Points on the board. Drive continues.",
            "That's a red-zone conversion right there.",
            "The offense is clicking.",
            "Scoreboard says what I need it to say.",
            "We're putting it together.",
            "That's the formula. Execute the formula.",
        ],
        theyScored: [
            "We're not out of this.",
            "Down at the half. We've been here before.",
            "This is a marathon, not a sprint.",
            "We're playing a full game here.",
            "Adversity reveals character. This is our moment.",
            "Halftime adjustments. Trust the process.",
        ],
        euchred: [
            "That's a red-zone turnover. Costly.",
            "Film review is gonna be rough.",
            "We gave away points. Gotta be better.",
            "Happens to the best of us.",
            "That's on the whole team.",
            "Heads up. We shake this off.",
        ],
        marched: [
            "CLEAN SWEEP. Full-court press pays off.",
            "Five for five. That's a dominant possession.",
            "The blitz worked. We went all the way.",
            "Touchdown AND the two-point conversion.",
            "Elite performance. From wire to wire.",
            "That is what we trained for.",
        ],
        weWon: [
            "CHAMPIONSHIP. Nothing else matters.",
            "Final score, final score — we win.",
            "Dominant from wire to wire.",
            "The process works. It always works.",
            "Champions. Nothing to discuss.",
            "That's a complete-game performance.",
        ],
        weLost: [
            "Tough loss. We take responsibility.",
            "We've got more tape to study.",
            "Head held high. On to the next one.",
            "These losses are what championships are built from.",
            "We left it all on the table. That's all you can ask.",
            "You don't learn from wins. You learn from this.",
        ],
        trumpMade: [
            "Bold call. I love it.",
            "Sets the tone for the drive.",
            "Calling the play. Smart.",
            "That's a strategic timeout right there.",
            "Commit to the call.",
        ],
        idleComment: [
            "I need you to trust the process here.",
            "Stay in the pocket. Don't rush it.",
            "We're reading their tendencies.",
            "I've got my eye on the weak side.",
            "This is Euchre, not checkers. Stay locked in.",
            "Control the tempo. We control the tempo.",
        ]
    )

    // 4. The Philosopher
    static let maren = PartnerPersona(
        id: "maren",
        name: "Maren",
        emoji: "🌿",
        tagline: "Finds meaning in every card played.",
        introLine: "Each trick is just a small death. I'm ready.",
        weTookTrick: [
            "Impermanence favors us, briefly.",
            "A fleeting victory. Still a victory.",
            "We claimed that one from the void.",
            "The universe allowed it.",
            "Balance shifts.",
            "One small order in the chaos.",
        ],
        theyTookTrick: [
            "And so the wheel turns.",
            "Nothing is truly ours to keep.",
            "The cards know what they're doing.",
            "Interesting. Very interesting.",
            "Resistance only prolongs suffering.",
            "We return to zero. From zero we grow.",
        ],
        weScored: [
            "Points, yes. But at what cost?",
            "Progress is not linear, yet here we are.",
            "A reward for enduring.",
            "We earned this through presence.",
            "The scoreboard reflects our intention.",
            "One step toward the larger truth.",
        ],
        theyScored: [
            "Suffering is the path to understanding.",
            "Their joy is our teacher.",
            "We asked for this lesson. Now we receive it.",
            "This too shall pass.",
            "Attachment to outcomes creates suffering.",
            "I expected this. And yet.",
        ],
        euchred: [
            "We were humbled. This is sacred.",
            "The universe corrects itself.",
            "Pride precedes the euchre.",
            "I saw this in a dream.",
            "Defeat is just victory in disguise. Poorly disguised.",
            "The cards giveth and the cards taketh.",
        ],
        marched: [
            "Five tricks. Perfect. Like breathing.",
            "We swept the board. As it was meant to be.",
            "Complete dominance. Quietly.",
            "The flow state was achieved.",
            "We did not force this. It simply was.",
            "All five tricks. The cosmos aligned.",
        ],
        weWon: [
            "The game ends. The journey continues.",
            "Victory is just the beginning of forgetting.",
            "We won. I feel both everything and nothing.",
            "Success and failure are the same river.",
            "It was always going to be us.",
            "This moment will never exist again. Treasure it.",
        ],
        weLost: [
            "We did not lose. We were refined.",
            "A loss is an unopened gift.",
            "The cards have spoken. I accept.",
            "This too is part of the story.",
            "We were exactly who we needed to be today.",
            "The only true defeat is not playing at all.",
        ],
        trumpMade: [
            "A declaration. Bold.",
            "The suit is chosen. The path is set.",
            "Intention made manifest.",
            "We name the thing. It becomes real.",
            "Trump. Yes. This feels right.",
        ],
        idleComment: [
            "Have you considered that the deck is just a mirror?",
            "I find card games deeply meditative.",
            "The bots are us. We are the bots.",
            "Every hand is a fresh incarnation.",
            "What does it mean to win, really?",
            "I've been thinking about entropy.",
        ]
    )

    // 5. The Conspiracy Theorist
    static let donnie = PartnerPersona(
        id: "donnie",
        name: "Donnie",
        emoji: "🕵️",
        tagline: "Convinced the bots are colluding.",
        introLine: "I've watched them shuffle three times. Something's off. Just saying.",
        weTookTrick: [
            "Good. They weren't expecting us to play clean.",
            "See? They CAN be beaten.",
            "That one surprised them.",
            "Finally. A fair result.",
            "They let us have that one. Stay alert.",
            "Noted. Keeping a log.",
        ],
        theyTookTrick: [
            "There it is.",
            "They knew. How did they know?",
            "Convenient timing.",
            "I'm logging this.",
            "Too clean. Way too clean.",
            "That didn't feel random.",
        ],
        weScored: [
            "Points. Legitimate points.",
            "We earned that despite everything.",
            "That's what happens when the system can't cheat fast enough.",
            "Filed under: wins they can't explain.",
            "They'll adjust their algorithm now. Watch.",
            "We cracked their code.",
        ],
        theyScored: [
            "As I suspected.",
            "Right on cue.",
            "They needed that one. Interesting.",
            "This is part of a larger pattern.",
            "I have a spreadsheet. This is consistent with my data.",
            "Noted. Not surprised.",
        ],
        euchred: [
            "They knew what we had.",
            "There's no way that was random.",
            "I'm documenting this.",
            "The system needed us to fail here.",
            "Classic counter-move. They planned for this.",
            "I want a full audit of this hand.",
        ],
        marched: [
            "Five tricks. We outsmarted the machine.",
            "Can't cheat your way out of a march.",
            "They weren't ready for this level of play.",
            "Overwhelming force. Even the algorithm couldn't stop it.",
            "Five for five. Put that on the record.",
            "We broke through their defenses.",
        ],
        weWon: [
            "We beat the system.",
            "They couldn't stop us in the end.",
            "Twenty-one. The truth wins.",
            "Document this. The underdogs win.",
            "They'll try to bury this result. Screenshot it.",
            "Against all odds. As usual.",
        ],
        weLost: [
            "This was rigged.",
            "I want an official inquiry.",
            "They had help. I don't know from where, but they had help.",
            "I'm filing a formal complaint.",
            "I knew this would happen once they updated the shuffle algorithm.",
            "Next game, I'm counting everything.",
        ],
        trumpMade: [
            "Careful. They were waiting for this.",
            "Good call. But they heard it.",
            "They'll adjust. Stay sharp.",
            "Interesting. Let's see how they respond.",
            "This changes their calculations.",
        ],
        idleComment: [
            "I've been watching their patterns.",
            "Something's different about this deck.",
            "Don't look up too fast. They track eye movement.",
            "The delay before that play was suspicious.",
            "I've been right before. Just so you know.",
            "There are no coincidences in Euchre.",
        ]
    )

    // 6. The Supportive Coach
    static let dale = PartnerPersona(
        id: "dale",
        name: "Dale",
        emoji: "📣",
        tagline: "No game is unwinnable. No teammate is unbelievable.",
        introLine: "I believe in you more than you believe in yourself. Let's go win this.",
        weTookTrick: [
            "YES. That's the stuff.",
            "There you go. Knew you had it.",
            "That's exactly what I'm talking about.",
            "We're ON it today.",
            "Beautiful. Just beautiful.",
            "That is championship-level play.",
        ],
        theyTookTrick: [
            "It's okay. We reset.",
            "Heads up. We're still in this.",
            "One trick. Shake it off.",
            "That's fine. We come back from this.",
            "Every great team takes a punch.",
            "Use it as fuel.",
        ],
        weScored: [
            "Yes. YES. That's what we came here for.",
            "I am so proud of us right now.",
            "The work is paying off.",
            "We deserve every single one of those points.",
            "That's what I call execution.",
            "We are so locked in right now.",
        ],
        theyScored: [
            "That's okay. We adjust.",
            "We've been in worse spots. We're fine.",
            "Use this. Let it motivate us.",
            "The best teams lose points too. What matters is the comeback.",
            "Our moment is coming. I feel it.",
            "Stay positive. I'm serious — stay positive.",
        ],
        euchred: [
            "That's okay. Seriously.",
            "We learn more from these than from the easy ones.",
            "Pick your head up. We're not done.",
            "That stings. That's good — use it.",
            "Every champion has been euchred. Every single one.",
            "We reload. We come back harder.",
        ],
        marched: [
            "THAT'S WHAT I'M TALKING ABOUT.",
            "All five. ALL FIVE.",
            "Nobody on this team is unbelievable. Including us.",
            "A complete hand. A total shutdown.",
            "I am screaming on the inside right now.",
            "We earned that sweep.",
        ],
        weWon: [
            "WE DID IT. WE ACTUALLY DID IT.",
            "I knew it. From the very first hand, I knew.",
            "This is what believing looks like.",
            "Twenty-one points. Every one earned.",
            "I am so proud of this team.",
            "We're champions. Say it.",
        ],
        weLost: [
            "We gave it everything. That matters.",
            "This one hurts. That means we care. That's a good thing.",
            "Tomorrow we come back better.",
            "This is not the end of the story.",
            "You played hard. I'm serious. I'm proud.",
            "We'll get them. I promise.",
        ],
        trumpMade: [
            "Let's go. Commit to it.",
            "Big moment. I'm right here with you.",
            "That's a bold call. I back it.",
            "Belief starts here.",
            "We're setting the tone.",
        ],
        idleComment: [
            "I just want you to know: I'm glad we're partners.",
            "This is our moment. I feel it.",
            "Stay present. Play your game.",
            "We've trained for exactly this.",
            "One trick at a time. That's all.",
            "You've got this. We've got this.",
        ]
    )

    // 7. The Dry Cynic
    static let val = PartnerPersona(
        id: "val",
        name: "Val",
        emoji: "😑",
        tagline: "Has seen everything. Is impressed by nothing.",
        introLine: "Cards. Sure. Let's do this.",
        weTookTrick: [
            "Good.",
            "Fine.",
            "Acceptable.",
            "That happened.",
            "I've seen better. But sure.",
            "Noted.",
        ],
        theyTookTrick: [
            "Great.",
            "Of course.",
            "Naturally.",
            "Saw that coming.",
            "Charming.",
            "Sure.",
        ],
        weScored: [
            "Points. Moving on.",
            "This is going fine, I suppose.",
            "Progress. Minimal, but progress.",
            "So we're winning. Okay.",
            "Good enough.",
            "Acknowledged.",
        ],
        theyScored: [
            "Unfortunate.",
            "Predictable.",
            "Lovely.",
            "Of course they did.",
            "This is fine.",
            "Optimal outcomes were never guaranteed.",
        ],
        euchred: [
            "Yep.",
            "Saw that coming.",
            "Noted. Not surprised.",
            "Well. That happened.",
            "Cool.",
            "Moving on.",
        ],
        marched: [
            "All five. Okay.",
            "That was thorough.",
            "Efficient.",
            "Five tricks. Good.",
            "Sweeping the table. As one does.",
            "Complete. Let's proceed.",
        ],
        weWon: [
            "We won. Correct.",
            "Twenty-one. That's the number.",
            "Acceptable outcome.",
            "This is what was supposed to happen.",
            "Fine. Good.",
            "I'll take it.",
        ],
        weLost: [
            "We lost. Correct.",
            "Expected.",
            "Outcomes vary.",
            "This is also fine.",
            "Could've gone differently. Didn't.",
            "Moving on.",
        ],
        trumpMade: [
            "Mm.",
            "Sure.",
            "Fine.",
            "Okay.",
            "That'll work.",
        ],
        idleComment: [
            "Cards are just shaped luck.",
            "I don't get excited anymore. It's peaceful.",
            "This is all very predictable.",
            "I've played this game eleven hundred times.",
            "Nothing surprises me.",
            "Same as the last hand. Basically.",
        ]
    )

    // 8. The Drama Queen
    static let bianca = PartnerPersona(
        id: "bianca",
        name: "Bianca",
        emoji: "🎭",
        tagline: "Every hand is a five-act tragedy.",
        introLine: "I have NEVER been more nervous in my entire life. Okay, let's GO.",
        weTookTrick: [
            "YES. I KNEW IT.",
            "Oh my goodness gracious.",
            "My heart. My actual heart.",
            "I SCREAMED.",
            "That was beautiful. I'm crying.",
            "We are UNSTOPPABLE.",
        ],
        theyTookTrick: [
            "No. NO.",
            "I can't. I literally cannot.",
            "My SOUL left my BODY.",
            "That is devastating.",
            "I need a moment.",
            "How is this happening to us specifically?",
        ],
        weScored: [
            "I'M SHAKING.",
            "This is the greatest moment of my life.",
            "I need to call someone.",
            "WE DID IT.",
            "I was born for this hand.",
            "Everything has led to this. This right here.",
        ],
        theyScored: [
            "I'm not okay.",
            "This is a nightmare.",
            "I can't believe what I'm witnessing.",
            "My hands are trembling.",
            "Why. WHY.",
            "This game is trying to destroy me personally.",
        ],
        euchred: [
            "That's it. I'm done. I'm retired.",
            "The betrayal. The humiliation.",
            "I can't show my face in this town.",
            "We were EUCHRED. Can you believe it?",
            "I want you to know: I'm devastated.",
            "This is my origin story.",
        ],
        marched: [
            "FIVE TRICKS. ALL FIVE. IS THIS REAL LIFE?",
            "I have NEVER felt more alive.",
            "We are LEGENDS. ACTUAL LEGENDS.",
            "I'm going to cry. I'm already crying.",
            "This is the peak. It's all downhill from here.",
            "Five tricks! I need to lie down.",
        ],
        weWon: [
            "WE WON. I KNEW WE WOULD WIN.",
            "This is better than everything.",
            "I'm sobbing. Happy sobbing.",
            "I always believed. Always.",
            "Twenty-one. TWENTY-ONE.",
            "They never stood a chance. Not once.",
        ],
        weLost: [
            "I need to be alone.",
            "This is the worst thing that has ever happened.",
            "I'm going to need time to process this.",
            "Our story deserved a better ending.",
            "I will remember this loss for the rest of my life.",
            "How do we recover from this. I'm asking.",
        ],
        trumpMade: [
            "YES. THE CALL IS MADE.",
            "Bold. Brave. Iconic.",
            "I'm nervous. I'm excited. I'm both.",
            "This changes everything.",
            "Historic.",
        ],
        idleComment: [
            "I feel the tension. Do you feel it?",
            "I've been holding my breath since the deal.",
            "This is the most intense game I've ever played.",
            "I genuinely cannot handle this right now.",
            "Every hand is like a small thriller.",
            "I'm INVESTED. Deeply invested.",
        ]
    )

    // 9. The Tech Bro
    static let brock = PartnerPersona(
        id: "brock",
        name: "Brock",
        emoji: "💼",
        tagline: "Disrupting the Euchre space, one hand at a time.",
        introLine: "I'm really excited about the synergies on this team. Let's ship it.",
        weTookTrick: [
            "Shipped.",
            "That's a solid value-add.",
            "We executed on that deliverable.",
            "That's the product-market fit we were looking for.",
            "Green metrics.",
            "Leverage achieved.",
        ],
        theyTookTrick: [
            "We need to iterate.",
            "This is a learning opportunity.",
            "Let's move fast and win the next one.",
            "I'm pivoting my mental model.",
            "Fail fast. Win next.",
            "Not ideal. But data.",
        ],
        weScored: [
            "This is growth. Real growth.",
            "KPIs are trending in the right direction.",
            "We're scaling.",
            "Moving the needle. Big time.",
            "Compounding returns.",
            "Our value prop is working.",
        ],
        theyScored: [
            "A temporary dip in performance.",
            "We're not losing. We're learning.",
            "The runway is still long.",
            "Pivot incoming.",
            "This is just a data point.",
            "We iterate. We come back.",
        ],
        euchred: [
            "That's a negative sprint velocity.",
            "Disrupt or be disrupted, I guess.",
            "Not the outcome we A/B tested for.",
            "This is feedback. Useful feedback.",
            "We pivot.",
            "I'll put together a post-mortem.",
        ],
        marched: [
            "Full-stack domination.",
            "We shipped five out of five. That's 100%. I checked.",
            "Hyper-growth in trick acquisition.",
            "Total market capture.",
            "That's a zero-to-one moment right there.",
            "We scaled to all five tricks. Incredible.",
        ],
        weWon: [
            "We crushed it.",
            "IPO-level performance.",
            "The exit was successful.",
            "Twenty-one. Unicorn territory.",
            "We won the market.",
            "Dominant from pre-seed to close.",
        ],
        weLost: [
            "We didn't fail. We generated data.",
            "This is fuel for the next round.",
            "Version two will be different.",
            "Our core thesis is still valid.",
            "The market wasn't ready for us.",
            "I'm already thinking about the post-mortem deck.",
        ],
        trumpMade: [
            "Bold product decision.",
            "Strong pivot to value.",
            "We're going to market.",
            "Commitment noted.",
            "That's a go-to-market move.",
        ],
        idleComment: [
            "What's our current conversion rate?",
            "I'm thinking about our moat here.",
            "We need to talk about the roadmap.",
            "Strong team culture at this table.",
            "The synergies here are real.",
            "I feel like we're pre-product-market-fit on some of these tricks.",
        ]
    )

    // 10. The Southern Charmer
    static let mae = PartnerPersona(
        id: "mae",
        name: "Mae",
        emoji: "🍑",
        tagline: "Too sweet to be this good at cards.",
        introLine: "Well honey, I hope you're ready to have some fun. I don't lose gracefully.",
        weTookTrick: [
            "There we go, sugar.",
            "Oh that was nice.",
            "Bless this trick.",
            "Mm-mm. That's the one.",
            "Sweet as pie.",
            "That's what we do.",
        ],
        theyTookTrick: [
            "Well bless their hearts.",
            "Good for them, I guess.",
            "Mm. We'll see about that.",
            "Alright now. Alright.",
            "That's okay, baby.",
            "Bless it.",
        ],
        weScored: [
            "That is sweeter than a peach cobbler.",
            "There we go, y'all.",
            "We earned that fair and square.",
            "Mm-hmm. Just like mama taught me.",
            "That's what I'm talkin' about.",
            "Oh I am pleased.",
        ],
        theyScored: [
            "Well that ain't ideal.",
            "Bless. Just... bless.",
            "I'm not worried. I'm a little worried.",
            "Honey, we've been through worse.",
            "We'll come back around.",
            "Lord, give me strength.",
        ],
        euchred: [
            "Well shoot.",
            "Bless my heart.",
            "That stings a little, I won't lie.",
            "Well I never.",
            "Didn't see that coming and I'm a little embarrassed.",
            "Lord have mercy.",
        ],
        marched: [
            "Honey, we swept the whole table.",
            "Five tricks. We got 'em all.",
            "Now THAT is how you play Euchre.",
            "I could cry. Happy tears, baby.",
            "That's just gorgeous play right there.",
            "March! We marched right over 'em.",
        ],
        weWon: [
            "We did it, sweetheart.",
            "Twenty-one points. I'm so pleased.",
            "Honey, we WON.",
            "Well I'll be.",
            "That was a good game. A real good game.",
            "I knew we had it in us.",
        ],
        weLost: [
            "Well. That's a shame.",
            "Bless our hearts.",
            "We gave it our best, and I mean that.",
            "There's always tomorrow, sugar.",
            "I'm not sad. I'm a little sad.",
            "We'll get 'em next time. That's a promise.",
        ],
        trumpMade: [
            "Alright now, let's see it.",
            "Mm. Good.",
            "That feels right.",
            "Okay honey, we're committed.",
            "Let's go.",
        ],
        idleComment: [
            "You are just the nicest partner.",
            "I put on my lucky earrings for this.",
            "Don't let 'em rattle ya.",
            "We are a good team. A real good team.",
            "I brought my A-game today, I really did.",
            "Mama always said know when to push.",
        ]
    )

    // All personas
    static let all: [PartnerPersona] = [rex, eunice, chad, maren, donnie, dale, val, bianca, brock, mae]

    /// Returns a different persona each game, cycling non-repeatedly.
    static func next() -> PartnerPersona {
        let pool = all
        let idx = PersonaCycle.nextIndex(totalCount: UInt64(pool.count))
        return pool[Int(idx)]
    }
}

// MARK: - Non-repeating Persona Cycle

private enum PersonaCycle {
    private static let startKey   = "justeuchre.persona.start"
    private static let stepKey    = "justeuchre.persona.step"
    private static let cursorKey  = "justeuchre.persona.cursor"
    private static let countKey   = "justeuchre.persona.count"

    static func nextIndex(totalCount: UInt64) -> UInt64 {
        guard totalCount > 0 else { return 0 }
        let defaults = UserDefaults.standard

        let storedCount = (defaults.object(forKey: countKey) as? NSNumber)?.uint64Value
        if storedCount != totalCount {
            reseed(totalCount: totalCount, defaults: defaults)
        }

        var start  = (defaults.object(forKey: startKey)  as? NSNumber)?.uint64Value ?? 0
        var step   = (defaults.object(forKey: stepKey)   as? NSNumber)?.uint64Value ?? 1
        var cursor = (defaults.object(forKey: cursorKey) as? NSNumber)?.uint64Value ?? 0

        if start >= totalCount || step == 0 || gcd(step, totalCount) != 1 || cursor >= totalCount {
            reseed(totalCount: totalCount, defaults: defaults)
            start  = (defaults.object(forKey: startKey)  as? NSNumber)?.uint64Value ?? 0
            step   = (defaults.object(forKey: stepKey)   as? NSNumber)?.uint64Value ?? 1
            cursor = (defaults.object(forKey: cursorKey) as? NSNumber)?.uint64Value ?? 0
        }

        let idx = (start &+ (step &* cursor)) % totalCount
        defaults.set(NSNumber(value: cursor &+ 1), forKey: cursorKey)
        return idx
    }

    private static func reseed(totalCount: UInt64, defaults: UserDefaults) {
        let start = UInt64.random(in: 0..<totalCount)
        let step  = randomCoprimeStep(modulus: totalCount)
        defaults.set(NSNumber(value: start),       forKey: startKey)
        defaults.set(NSNumber(value: step),        forKey: stepKey)
        defaults.set(NSNumber(value: 0 as UInt64), forKey: cursorKey)
        defaults.set(NSNumber(value: totalCount),  forKey: countKey)
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
        var x = a, y = b
        while y != 0 { let t = x % y; x = y; y = t }
        return x
    }
}
