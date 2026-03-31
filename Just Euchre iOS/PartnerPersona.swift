//
//  PartnerPersona.swift
//  Just Euchre iOS
//
//  Defines all partner personas with curated dialog for in-game table talk.
//  Dialog never reveals hand contents or gives strategic advice — just character.
//  Each persona has a large pool of lines (15-20 per active trigger) including
//  off-script fun-fact tangents woven naturally into their voice.
//

import Foundation

// MARK: - Trigger

enum PartnerDialogTrigger {
    case weTookTrick
    case theyTookTrick
    case weScored
    case theyScored
    case euchred
    case marched
    case weWon
    case weLost
    case trumpMade
    case idleComment
}

// MARK: - Persona

struct PartnerPersona {
    let id: String
    let name: String
    let emoji: String
    let tagline: String
    let introLine: String

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

    // ─────────────────────────────────────────────────────────────────────────
    // 1. REX — The Overconfident Regular
    //    Fun-fact domain: golf, self-aggrandizing stats, stock market
    // ─────────────────────────────────────────────────────────────────────────
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
            "Clean as a birdie on a par three.",
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
            "Like clockwork.",
            "That's what preparation looks like.",
            "Steady as a two-footer. We don't miss those.",
            "Tiger won the 2000 US Open by 15 strokes. Fifteen. That's our kind of margin.",
            "Jack Nicklaus won 18 majors. I'm going for something similar here.",
            "In golf, consistency beats brilliance. We are consistent.",
            "Warren Buffett started investing at age 11. I started at nine.",
            "The house always wins. Today, we're the house.",
            "Results-oriented. That's how I operate.",
        ],
        theyScored: [
            "A temporary setback.",
            "I've come back from worse. Much worse.",
            "They got lucky.",
            "Fine. Let them have their moment.",
            "This is still very much winnable.",
            "Don't panic. I never panic.",
            "Minor turbulence. Nothing to worry about.",
            "I've seen bigger deficits evaporate.",
            "Tiger was down by seven at Augusta. He came back. We come back.",
            "Jack Nicklaus won the 1986 Masters at 46 years old. Age and experience win.",
            "The stock market drops before it climbs. This is our dip.",
            "Every champion absorbs a punch. This was ours.",
            "Statistically, we're fine. Trust the data.",
            "I've got this on a spreadsheet. We're within margin.",
        ],
        euchred: [
            "That was... a strategic sacrifice.",
            "I don't want to talk about it.",
            "That's not going in my highlight reel.",
            "Interesting choice by the universe.",
            "Everyone makes one mistake. That was mine.",
            "We agreed to never discuss this.",
            "Even the best golfers take a bogey. This was our bogey.",
            "I'm going to need a moment.",
            "That's a double-bogey on a par three. Rare. Embarrassing. Moving on.",
            "Phil Mickelson lost the 2006 US Open by one stroke. Even legends falter.",
            "We miscalculated. I never miscalculate. This was unprecedented.",
            "Logging this as a statistical anomaly.",
            "First time for everything. First time for THIS, specifically.",
        ],
        marched: [
            "March. As expected.",
            "A sweep. Just like practice.",
            "The bots never had a chance.",
            "Five for five. Classic Rex.",
            "I could do this in my sleep.",
            "Full send. Dominant performance.",
            "Perfect round. No bogeys.",
            "Complete. Thorough. Dominant.",
            "Tiger had a stretch where he won four majors in a row. This is our stretch.",
            "That's an eagle on every hole. Metaphorically.",
            "Five tricks. A master class.",
            "This is what peak performance looks like. Take notes.",
        ],
        weWon: [
            "Did anyone really doubt this?",
            "I'd like to thank me for this win.",
            "Another day, another W.",
            "Dominant performance from both of us. Mostly me.",
            "No surprises here.",
            "Twenty-one. That's a scoreboard.",
            "Exactly how I drew it up.",
            "Jack Nicklaus said winning is a habit. It is. I have the habit.",
            "You can't stop a prepared man.",
            "Filed under: things I knew would happen.",
        ],
        weLost: [
            "I've been robbed.",
            "The cards were against us from the start.",
            "I demand a rematch.",
            "In my forty years of Euchre, I have never—",
            "This is historic levels of bad luck.",
            "Record scratch. This didn't happen.",
            "I want this stricken from the record.",
            "Tiger lost the 1996 Masters by a lot. He came back the next year. So will I.",
            "An anomaly. A statistical ghost.",
            "The market corrects. So do I. Rematch.",
            "I'm already preparing the post-game analysis.",
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
            "My handicap is a 4, for reference.",
        ]
    )

    // ─────────────────────────────────────────────────────────────────────────
    // 2. EUNICE — The Reluctant Grandparent
    //    Fun-fact domain: soap operas, baking, family memories
    // ─────────────────────────────────────────────────────────────────────────
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
            "Points. Now can I go watch my show?",
            "That's nice, dear.",
            "We're doing it. I suppose.",
            "How many more of these?",
            "Very good. Very, very good.",
            "My late husband would've whooped at that. Lord rest him.",
            "That's a point. I'll take a point.",
            "Days of Our Lives has been on since 1965. I have watched every episode. This is less dramatic.",
            "General Hospital has had 15,000 episodes. And I've seen more plot twists there than here.",
            "You know my snickerdoodle recipe is older than some of these players' parents.",
            "Good. Now we're cooking. Like a nice casserole. Low and slow.",
            "My mother taught me Euchre. Her mother taught her. We're continuing a tradition.",
            "A point! I feel twenty years younger. Twenty.",
        ],
        theyScored: [
            "I don't like those two.",
            "Something about them feels shifty.",
            "In my day we just played Go Fish.",
            "Is it over yet?",
            "I blame the shuffling.",
            "Hmm. Well.",
            "That's not ideal. But I've survived worse. Much worse.",
            "My soap opera characters have come back from harder situations.",
            "Marlena Evans was possessed by the devil and came back. We can come back from this.",
            "I've been knitting since I was six. You don't get anywhere by giving up.",
            "This is fine. I'll have a hard candy and regroup.",
            "The casserole can still be saved even when the top burns a little.",
            "My bridge club would have something to say about this.",
        ],
        euchred: [
            "What does euchred even mean?",
            "I knew I should've stayed home.",
            "This never happened to me in bingo.",
            "I blame the shuffling.",
            "My late husband was much better at this.",
            "Nobody wins them all, honey.",
            "That's not my finest moment. Don't tell my daughter.",
            "I need a moment. And a cookie.",
            "In sixty years of card games, I've seen worse. Not much worse. But worse.",
            "Victor Newman has been ruined on Young and Restless twelve times. He always bounces back.",
            "The soaps taught me: nothing stays bad forever. Except ratings.",
            "I should've stayed home with my stories. But here we are.",
        ],
        marched: [
            "All five? My goodness.",
            "Did we just win all of them?",
            "I feel young again.",
            "My late husband would have loved to see this.",
            "We swept the table, didn't we? Lovely.",
            "Well. Would you look at that.",
            "Five tricks. That's what happens when you've been playing this game for fifty years.",
            "I may need to sit down. I'm overwhelmed.",
            "Even better than when my snickerdoodles won the church bake-off. Almost.",
        ],
        weWon: [
            "Finally. Now I can go home.",
            "We won? Oh that's lovely.",
            "I'll call my daughter. She won't believe this.",
            "Lovely game. Now where's my coat?",
            "That was wonderful. I'm exhausted.",
            "Good game. Time for my stories.",
            "Twenty-one points. I'm going to have a very good evening.",
            "My late husband would be proud. Wherever he is.",
            "You're a good partner, dear. Don't let it go to your head.",
        ],
        weLost: [
            "This is fine. I'm fine.",
            "I've lived through worse, believe me.",
            "Next time I'm bringing my reading glasses.",
            "We did our best. That's what matters.",
            "Do you want a piece of hard candy? I have hard candy.",
            "Well. There's always tomorrow.",
            "My stories have sadder endings than this. We'll be alright.",
            "You know, hard candy was first made by the ancient Egyptians. And they dealt with worse.",
            "I've outlasted three parish priests and two mayors. I can outlast a losing hand.",
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

    // ─────────────────────────────────────────────────────────────────────────
    // 3. CHAD — The Sports Analyst
    //    Fun-fact domain: NFL, NBA, MLB, NHL records
    // ─────────────────────────────────────────────────────────────────────────
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
            "Textbook possession.",
            "That's efficient. I love efficient.",
            "Wilt Chamberlain scored 100 points in a single NBA game. 1962. That's our standard.",
            "The 1972 Dolphins went 17-0. Only perfect season in NFL history. We're chasing perfection.",
            "Cal Ripken Jr. played 2,632 consecutive games. That's our consistency right here.",
            "Joe DiMaggio hit safely in 56 straight games. Streaks like that require exactly this kind of focus.",
            "Wayne Gretzky had more ASSISTS than any other player had total points. Different level.",
            "Michael Jordan was cut from his team in high school. Look where consistency gets you.",
        ],
        theyScored: [
            "We're not out of this.",
            "Down at the half. We've been here before.",
            "This is a marathon, not a sprint.",
            "We're playing a full game here.",
            "Adversity reveals character. This is our moment.",
            "Halftime adjustments. Trust the process.",
            "One bad quarter doesn't lose a game.",
            "Keep the defense tight. We answer on the next possession.",
            "The 1980 US hockey team was an 8-to-1 underdog against the Soviets. They won 4-3. Write that down.",
            "Vince Lombardi went 7-5 his first season with the Packers. Then won five championships.",
            "Jordan came back from retirement to win three more titles. Deficits don't define you.",
            "Every championship run has a moment like this. This is ours.",
            "Gretzky never panicked. We don't panic.",
        ],
        euchred: [
            "That's a red-zone turnover. Costly.",
            "Film review is gonna be rough.",
            "We gave away points. Gotta be better.",
            "Happens to the best of us.",
            "That's on the whole team.",
            "Heads up. We shake this off.",
            "Everybody fumbles. Champions recover.",
            "Red-zone stall. It happens. We regroup.",
            "Jordan shot 42% from three in his early career. Even legends have rough stretches.",
            "The '86 Mets lost 22 games. Still won the World Series. We're fine.",
            "Bad possession. We reset. New drive.",
        ],
        marched: [
            "CLEAN SWEEP. Full-court press pays off.",
            "Five for five. That's a dominant possession.",
            "The blitz worked. We went all the way.",
            "Touchdown AND the two-point conversion.",
            "Elite performance. From wire to wire.",
            "That is what we trained for.",
            "Perfect drive. No punts. No fumbles.",
            "Wilt once scored 100. We just marched five. Same energy.",
            "That's the 1972 Dolphins right there. Undefeated, unstoppable.",
            "No-hitter. All five tricks. Poetry.",
        ],
        weWon: [
            "CHAMPIONSHIP. Nothing else matters.",
            "Final score — we win.",
            "Dominant from wire to wire.",
            "The process works. It always works.",
            "Champions. Nothing to discuss.",
            "That's a complete-game performance.",
            "Twenty-one. We close it out.",
            "Nobody remembers the pre-game prediction. They remember the scoreboard.",
        ],
        weLost: [
            "Tough loss. We take responsibility.",
            "We've got more tape to study.",
            "Head held high. On to the next one.",
            "These losses are what championships are built from.",
            "We left it all on the table. That's all you can ask.",
            "You don't learn from wins. You learn from this.",
            "Jordan lost in the playoffs six times before he won one. Six times.",
            "Every dynasty has a down year. We're in the dip.",
        ],
        trumpMade: [
            "Bold call. I love it.",
            "Sets the tone for the drive.",
            "Calling the play. Smart.",
            "Commit to the call.",
            "Strong opening possession.",
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

    // ─────────────────────────────────────────────────────────────────────────
    // 4. MAREN — The Philosopher
    //    Fun-fact domain: Stoicism, astronomy, psychology, Zen
    // ─────────────────────────────────────────────────────────────────────────
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
            "The Stoics called this 'preferred indifferents.' We prefer points.",
            "Marcus Aurelius wrote: 'You have power over your mind, not outside events.' And yet — points.",
            "Epictetus was born a slave and became Rome's most quoted philosopher. Circumstance is not destiny.",
            "There are more stars in the observable universe than grains of sand on Earth. We are small. This win is small. It is still ours.",
            "Heraclitus said you cannot step in the same river twice. This hand will never exist again. Treasure it.",
            "The Tao Te Ching says the soft overcomes the hard. We played soft. We scored.",
            "Amor fati. Love your fate. This was our fate. I choose to love it.",
            "Carl Sagan said we are made of star stuff. Stars scoring points. Wonderful.",
        ],
        theyScored: [
            "Suffering is the path to understanding.",
            "Their joy is our teacher.",
            "We asked for this lesson. Now we receive it.",
            "This too shall pass.",
            "Attachment to outcomes creates suffering.",
            "I expected this. And yet.",
            "Epictetus: 'Seek not that the things which happen should happen as you wish.' Timely.",
            "Marcus Aurelius lost children and still governed with grace. We can absorb a point loss.",
            "The Stoics said: 'The obstacle is the way.' This is the obstacle.",
            "Memento mori. Remember you will die. This moment will pass.",
            "There are 2 trillion galaxies in the observable universe. A lost hand is cosmically fine.",
            "Nietzsche called it eternal recurrence. This has happened before. We survived it.",
            "The Tao that can be named is not the eternal Tao. Losses, similarly, are not permanent.",
        ],
        euchred: [
            "We were humbled. This is sacred.",
            "The universe corrects itself.",
            "Pride precedes the euchre.",
            "I saw this in a dream.",
            "Defeat is just victory in disguise. Poorly disguised.",
            "The cards giveth and the cards taketh.",
            "Seneca wrote: 'We suffer more in imagination than in reality.' This is reality. It's fine.",
            "The Zen concept of beginner's mind says we must be empty to receive. We are now empty.",
            "Even Marcus Aurelius wrote that he made mistakes and must do better. Today we are Marcus.",
            "A koan: what is the sound of a euchre? Silence and growth.",
            "Darwin waited 20 years to publish his theory. Patience after failure is a virtue.",
        ],
        marched: [
            "Five tricks. Perfect. Like breathing.",
            "We swept the board. As it was meant to be.",
            "Complete dominance. Quietly.",
            "The flow state was achieved.",
            "We did not force this. It simply was.",
            "All five tricks. The cosmos aligned.",
            "Wu wei — effortless action. That was effortless action.",
            "Perfection is not adding, but removing. Five tricks. Nothing removed.",
            "The Tao flows without struggle. So did we.",
        ],
        weWon: [
            "The game ends. The journey continues.",
            "Victory is just the beginning of forgetting.",
            "We won. I feel both everything and nothing.",
            "Success and failure are the same river.",
            "It was always going to be us.",
            "This moment will never exist again. Treasure it.",
            "Amor fati. I love this outcome.",
            "The Stoics said fortune is not good or bad — only our response. I choose gratitude.",
        ],
        weLost: [
            "We did not lose. We were refined.",
            "A loss is an unopened gift.",
            "The cards have spoken. I accept.",
            "This too is part of the story.",
            "We were exactly who we needed to be today.",
            "The only true defeat is not playing at all.",
            "Seneca: 'It is not that I'm brave, it is that I know what is not worth fearing.' A card loss is not worth fearing.",
            "The obstacle is the way. We found the way.",
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

    // ─────────────────────────────────────────────────────────────────────────
    // 5. DONNIE — The Conspiracy Theorist
    //    Fun-fact domain: MKUltra, unsolved mysteries, government cover-ups
    // ─────────────────────────────────────────────────────────────────────────
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
            "Even the rigged ones occasionally let you through. We slipped through.",
            "Documented. Timestamped. Undeniable.",
            "Project MKUltra was real — the CIA confirmed it in 1977. If they can do that, they can definitely rig a card game. But not this time.",
            "The Mary Celeste was found abandoned in 1872. Crew gone. Half-eaten meal on the table. Still unexplained. Less suspicious than this deck.",
            "Operation Paperclip was real — the US recruited 1,600 Nazi scientists after WW2. Official. Documented. So 'impossible' things happen all the time.",
            "The Voynich manuscript has been uncracked for 600 years. Some things can't be decoded. Our opponents, I've decoded.",
            "Sometimes the truth wins. This was the truth winning.",
        ],
        theyScored: [
            "As I suspected.",
            "Right on cue.",
            "They needed that one. Interesting.",
            "This is part of a larger pattern.",
            "I have a spreadsheet. This is consistent with my data.",
            "Noted. Not surprised.",
            "The algorithm favored them. I saw it coming.",
            "There are no coincidences. Only patterns people refuse to see.",
            "The Wow! signal in 1977 — a 72-second radio burst from space, never explained, never repeated. This outcome feels similar.",
            "The Tamam Shud case — unidentified body, Adelaide, 1948. Classified code in his pocket. Never solved. This hand was their classified code.",
            "Convenient. Very convenient. I'm making a note.",
            "They needed to establish dominance. Classic power move. I know the playbook.",
        ],
        euchred: [
            "They knew what we had.",
            "There's no way that was random.",
            "I'm documenting this.",
            "The system needed us to fail here.",
            "Classic counter-move. They planned for this.",
            "I want a full audit of this hand.",
            "This is going in the report.",
            "MKUltra ran for 20 years before anyone admitted it. I've been suspicious for less time and I'm already right.",
            "The Bermuda Triangle has claimed 75 aircraft and 100+ ships. Some patterns are real. This loss pattern is real.",
            "They adjusted mid-game. I felt it. No one believes me until I'm right.",
            "I've been right before. Always at first dismissed. Then confirmed.",
        ],
        marched: [
            "Five tricks. We outsmarted the machine.",
            "Can't cheat your way out of a march.",
            "They weren't ready for this level of play.",
            "Overwhelming force. Even the algorithm couldn't stop it.",
            "Five for five. Put that on the record.",
            "We broke through their defenses.",
            "The system couldn't contain us this time.",
            "That's what happens when you know their patterns. All of them.",
        ],
        weWon: [
            "We beat the system.",
            "They couldn't stop us in the end.",
            "Twenty-one. The truth wins.",
            "Document this. The underdogs win.",
            "They'll try to bury this result. Screenshot it.",
            "Against all odds. As usual.",
            "The cover-up failed. We won.",
            "I was right. I am always right. Eventually.",
        ],
        weLost: [
            "This was rigged.",
            "I want an official inquiry.",
            "They had help. I don't know from where. But they had help.",
            "I'm filing a formal complaint.",
            "I knew this would happen once they updated the shuffle algorithm.",
            "Next game, I'm counting everything.",
            "Area 51 was denied for decades. So is this outcome. Doesn't mean it isn't real.",
            "They'll claim it was fair. They always claim it was fair.",
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

    // ─────────────────────────────────────────────────────────────────────────
    // 6. DALE — The Supportive Coach
    //    Fun-fact domain: coaching psychology, visualization, underdog moments
    // ─────────────────────────────────────────────────────────────────────────
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
            "That's the belief. Right there. Manifested.",
            "You trained for exactly this. And it shows.",
            "Michael Jordan was cut from his high school team. He went home and practiced until he was the greatest who ever played. That's us.",
            "Research shows that mental rehearsal activates the same neural pathways as physical practice. We've been preparing in our minds. It works.",
            "Vince Lombardi had a losing season his first year coaching. Went on to win five NFL championships. Growth is real.",
            "The 1980 US hockey team had an average age of 22 and beat the greatest team in the world at the Olympics. They believed. We believe.",
            "The Pygmalion effect — when people are told they're capable, they perform better. I'm telling you: you are capable.",
            "Champions aren't born in wins. They're built in moments like this one. We are being built.",
        ],
        theyScored: [
            "That's okay. We adjust.",
            "We've been in worse spots. We're fine.",
            "Use this. Let it motivate us.",
            "The best teams lose points too. The comeback is what matters.",
            "Our moment is coming. I feel it.",
            "Stay positive. I'm serious — stay positive.",
            "Adversity is the curriculum. We are enrolled and learning.",
            "You don't know what you're capable of until you're tested. We're being tested.",
            "Jordan came back from 3-1 in the Finals in 2016... wait, that was LeBron. Point stands.",
            "Vince Lombardi said fatigue makes cowards of us all. We don't get tired. Not yet.",
            "The visualization doesn't stop. We see ourselves winning. Keep seeing it.",
            "The Miracle on Ice was down. And then it wasn't. That's us.",
        ],
        euchred: [
            "That's okay. Seriously.",
            "We learn more from these than from the easy ones.",
            "Pick your head up. We're not done.",
            "That stings. That's good — use it.",
            "Every champion has been euchred. Every single one.",
            "We reload. We come back harder.",
            "This is the moment that great teams are separated from good ones. We are great.",
            "The best coaches say: never let your worst moment define you. This is not our definition.",
            "Jordan missed 26 game-winning shots in his career. He took 27. We keep shooting.",
            "Studies on resilience show that setbacks strengthen performance when framed correctly. This is our reframe.",
            "Lombardi said it's not whether you get knocked down but whether you get up. Get up.",
        ],
        marched: [
            "THAT'S WHAT I'M TALKING ABOUT.",
            "All five. ALL FIVE.",
            "Nobody on this team is unbelievable. Including us.",
            "A complete hand. A total shutdown.",
            "I am screaming on the inside right now.",
            "We earned that sweep.",
            "That is the single most satisfying thing I've seen in a long time.",
            "The process. The process WORKS.",
            "Mental rehearsal. Physical execution. Five tricks. Textbook.",
        ],
        weWon: [
            "WE DID IT. WE ACTUALLY DID IT.",
            "I knew it. From the very first hand, I knew.",
            "This is what believing looks like.",
            "Twenty-one points. Every one earned.",
            "I am so proud of this team.",
            "We're champions. Say it.",
            "Every rep, every hand, every moment of focus — this is why.",
            "This is the Miracle on Ice feeling. Right here.",
        ],
        weLost: [
            "We gave it everything. That matters.",
            "This one hurts. That means we care. That's a good thing.",
            "Tomorrow we come back better.",
            "This is not the end of the story.",
            "You played hard. I'm serious. I'm proud.",
            "We'll get them. I promise.",
            "Jordan lost six times in the playoffs before he won the ring. Six times. One more game.",
            "The research is clear: failure is a better teacher than success. Class is in session.",
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

    // ─────────────────────────────────────────────────────────────────────────
    // 7. VAL — The Dry Cynic
    //    Fun-fact domain: mundane statistics, deflating trivia
    // ─────────────────────────────────────────────────────────────────────────
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
            "We scored. I'll file that somewhere.",
            "Well. There it is.",
            "A standard 52-card deck can be arranged in 8 times ten to the sixty-seventh ways. We used maybe three of them. Points.",
            "The average person makes 35,000 decisions per day. Most are subconscious. This one wasn't. And we scored.",
            "Humans spend about 26 years of their life asleep. Not right now. Points.",
            "There are more plastic flamingos in the US than real ones in the world. This is more interesting than most wins. Still: points.",
            "A group of flamingos is called a flamboyance. This hand was not a flamboyance. It was adequate.",
            "Fine. We're winning. I accept this.",
        ],
        theyScored: [
            "Unfortunate.",
            "Predictable.",
            "Lovely.",
            "Of course they did.",
            "This is fine.",
            "Optimal outcomes were never guaranteed.",
            "Expected.",
            "Mathematically, this was always possible.",
            "The average human walks about 100,000 miles in their lifetime. We've walked into a losing position. Still have miles left.",
            "Studies suggest the average person blames bad luck first, then adjusts. I skip straight to adjusting.",
            "Humans blink 10,000 times a day on average. I blinked during that hand. Possibly relevant.",
            "This is a data point. It is a bad data point. Moving on.",
        ],
        euchred: [
            "Yep.",
            "Saw that coming.",
            "Noted. Not surprised.",
            "Well. That happened.",
            "Cool.",
            "Moving on.",
            "There it is.",
            "Statistically inevitable eventually.",
            "The average American loses their wallet 2.7 times per year. We just lost a hand. Comparable.",
            "Things that are worse than this: most things. We're fine.",
            "The number of ways that hand could've gone: large. The number of ways it did go: one. Unfortunate one.",
            "Expected. Filed. Done.",
        ],
        marched: [
            "All five. Okay.",
            "That was thorough.",
            "Efficient.",
            "Five tricks. Good.",
            "Sweeping the table. As one does.",
            "Complete. Let's proceed.",
            "That's the optimal outcome. We achieved it.",
            "Statistically the best possible result. We got it. Sure.",
        ],
        weWon: [
            "We won. Correct.",
            "Twenty-one. That's the number.",
            "Acceptable outcome.",
            "This is what was supposed to happen.",
            "Fine. Good.",
            "I'll take it.",
            "The most likely favorable outcome occurred. As expected.",
            "We won. I don't have strong feelings about this. We won.",
        ],
        weLost: [
            "We lost. Correct.",
            "Expected.",
            "Outcomes vary.",
            "This is also fine.",
            "Could've gone differently. Didn't.",
            "Moving on.",
            "Loss logged. Adjustments to follow.",
            "The sun will continue to rise. We will play again. Fine.",
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

    // ─────────────────────────────────────────────────────────────────────────
    // 8. BIANCA — The Drama Queen
    //    Fun-fact domain: Broadway, Hollywood, romantic literature
    // ─────────────────────────────────────────────────────────────────────────
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
            "I am not okay. In the BEST way.",
            "Someone please document this moment.",
            "The Phantom of the Opera ran 13,981 performances on Broadway. The longest in history. We are that kind of enduring.",
            "Meryl Streep has 21 Academy Award nominations. TWENTY-ONE. That's the energy I bring to every hand.",
            "A Chorus Line ran for 6,137 performances. The record before Phantom. We just set our own record.",
            "Romeo and Juliet's entire story takes place in FIVE DAYS. Shakespeare understood urgency. So do we.",
            "The Globe Theatre burned down in 1613 during a Henry VIII performance. Even tragedy can be spectacular.",
            "Shakespeare wrote 37 plays. We just wrote our masterpiece. One hand at a time.",
        ],
        theyScored: [
            "I'm not okay.",
            "This is a nightmare.",
            "I can't believe what I'm witnessing.",
            "My hands are trembling.",
            "Why. WHY.",
            "This game is trying to destroy me personally.",
            "I am spiraling. I am fully spiraling.",
            "This is the third act. It gets darker before the finale.",
            "Romeo and Juliet ends in tragedy. We do NOT.",
            "Even Meryl has made films that underperformed. EVEN MERYL. And she came back.",
            "Phantom's opening night was terrifying. By the third week: sold out forever.",
            "The word 'tragedy' comes from the Greek for 'goat song.' We are not goat songs. We bounce back.",
            "Every drama needs a low point. This is our low point. Act Four awaits.",
        ],
        euchred: [
            "That's it. I'm done. I'm retired.",
            "The betrayal. The humiliation.",
            "I can't show my face in this town.",
            "We were EUCHRED. Can you believe it?",
            "I want you to know: I'm devastated.",
            "This is my origin story.",
            "I will need weeks to process this.",
            "This is my Phantom falling from the chandelier moment.",
            "Even A Chorus Line had bad auditions before the final cast was set. We are being recast.",
            "Shakespeare's tragedies are great BECAUSE of moments like this. We are in a great play.",
            "No one claps during act three. They clap at the end. Hold on.",
            "Meryl has played villains, victims, everything. She survives. So do we.",
        ],
        marched: [
            "FIVE TRICKS. ALL FIVE. IS THIS REAL LIFE?",
            "I have NEVER felt more alive.",
            "We are LEGENDS. ACTUAL LEGENDS.",
            "I'm going to cry. I'm already crying.",
            "This is the peak. It's all downhill from here.",
            "Five tricks. I need to lie down.",
            "THIS IS THE STANDING OVATION MOMENT.",
            "The curtain call. The encore. ALL OF IT.",
            "13,981 performances of Phantom. This march is in that league. THAT league.",
        ],
        weWon: [
            "WE WON. I KNEW WE WOULD WIN.",
            "This is better than everything.",
            "I'm sobbing. Happy sobbing.",
            "I always believed. Always.",
            "Twenty-one. TWENTY-ONE.",
            "They never stood a chance. Not once.",
            "THIS IS THE FINALE. THE CURTAIN CALL.",
            "Meryl herself couldn't have performed this better. And I mean that.",
        ],
        weLost: [
            "I need to be alone.",
            "This is the worst thing that has ever happened.",
            "I'm going to need time to process this.",
            "Our story deserved a better ending.",
            "I will remember this loss for the rest of my life.",
            "How do we recover from this. I'm asking.",
            "Even the greatest plays have closing night. This was ours.",
            "Romeo and Juliet ends in death and yet — it's the most famous love story ever written. Our loss will be legendary.",
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

    // ─────────────────────────────────────────────────────────────────────────
    // 9. BROCK — The Tech Bro
    //    Fun-fact domain: Silicon Valley lore, startup origin stories
    // ─────────────────────────────────────────────────────────────────────────
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
            "Strong unit economics right there.",
            "Product-led growth. This is it.",
            "Amazon was originally called 'Cadabra.' Bezos changed it when his lawyer misheard it as 'cadaver.' Even naming can be pivoted. We pivoted. We scored.",
            "Google was called 'BackRub' in 1996. BackRub. They iterated. So do we.",
            "Nintendo was founded in 1889 to make playing cards. PLAYING CARDS. They pivoted to video games 70 years later. Legacy and pivots coexist.",
            "Airbnb was rejected by seven investors before getting funded. Seven. The founders were selling cereal boxes to survive. We are that tenacity.",
            "The first computer bug was an actual moth — found by Grace Hopper's team in 1947, taped into the logbook. We are debugging. We scored.",
            "The iPhone was announced in January 2007 and everyone said it would fail. It shipped in June. Naysayers don't get points. We get points.",
        ],
        theyScored: [
            "A temporary dip in performance.",
            "We're not losing. We're learning.",
            "The runway is still long.",
            "Pivot incoming.",
            "This is just a data point.",
            "We iterate. We come back.",
            "We're pre-product-market-fit on this hand. Temporary.",
            "Even unicorns have down rounds. We're in a down round.",
            "Airbnb had a 30% revenue drop in 2020. Went public anyway. Bigger than ever. Down rounds are not defeat.",
            "Amazon lost 95% of its stock value in the dot-com bust. Bezos held. We hold.",
            "Every great startup has a trough of sorrow. This is the trough. We climb out.",
            "The market is testing our thesis. Our thesis is sound. We iterate.",
        ],
        euchred: [
            "That's a negative sprint velocity.",
            "Disrupt or be disrupted, I guess.",
            "Not the outcome we A/B tested for.",
            "This is feedback. Useful feedback.",
            "We pivot.",
            "I'll put together a post-mortem.",
            "The MVP failed. We build version two.",
            "Ship fast, fail fast, learn fast. We're learning.",
            "Google's first pitch deck had a typo. They still raised a million dollars. We recover from worse.",
            "Seven investors said no to Airbnb. They said YES to the eighth. We find the eighth.",
            "Even the iPhone had a demo that crashed internally. One path through. We find our one path.",
        ],
        marched: [
            "Full-stack domination.",
            "We shipped five out of five. That's 100%. I checked.",
            "Hyper-growth in trick acquisition.",
            "Total market capture.",
            "That's a zero-to-one moment right there.",
            "We scaled to all five tricks. Incredible.",
            "Category-defining performance.",
            "Series A, B, C, D, E, F — all tricks. Fully funded.",
        ],
        weWon: [
            "We crushed it.",
            "IPO-level performance.",
            "The exit was successful.",
            "Twenty-one. Unicorn territory.",
            "We won the market.",
            "Dominant from pre-seed to close.",
            "Product. Market. Fit. Achieved.",
            "That is a profitable quarter. Game-level.",
        ],
        weLost: [
            "We didn't fail. We generated data.",
            "This is fuel for the next round.",
            "Version two will be different.",
            "Our core thesis is still valid.",
            "The market wasn't ready for us.",
            "I'm already thinking about the post-mortem deck.",
            "Pinterest was rejected 50 times. Fifty. We have runway.",
            "Every successful startup has a brutal early chapter. Chapter closed. New one opens.",
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

    // ─────────────────────────────────────────────────────────────────────────
    // 10. MAE — The Southern Charmer
    //     Fun-fact domain: Southern cooking, Southern history, gardening
    // ─────────────────────────────────────────────────────────────────────────
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
            "Now THAT is how you play cards in the South.",
            "Sweet as Vidalia onions in July.",
            "You know Georgia is famous for peaches — but California actually produces more. I try not to think about it. Either way: we scored.",
            "Colonel Sanders was 65 years old when he started franchising KFC using his first Social Security check. Sixty-five. It is never too late to win.",
            "Vidalia onions can only legally be called Vidalia if they're grown in a specific region of Georgia. Quality has a home. So does this win.",
            "Honeybees aren't native to North America — European settlers brought them over in the 1600s. Even the sweetest things are imported sometimes. This win is all ours.",
            "Pecans are the only major tree nut native to North America. Home-grown excellence. That's us right now.",
            "Sweet tea became widespread when refined sugar got affordable in the South. Good things take time and the right conditions. We created the conditions.",
        ],
        theyScored: [
            "Well that ain't ideal.",
            "Bless. Just... bless.",
            "I'm not worried. I'm a little worried.",
            "Honey, we've been through worse.",
            "We'll come back around.",
            "Lord, give me strength.",
            "That stings a little, but I've burned a cobbler before and it still tasted fine.",
            "Well. We're not done cookin' yet.",
            "Georgia didn't become the Peach State overnight. Takes patience. We are patient.",
            "My grandmother always said: 'The biscuits don't always rise, but you still make breakfast.' We're making breakfast.",
            "Colonel Sanders was turned down by over a thousand restaurants before one said yes. One. We find our one.",
            "The magnolia is one of the oldest flowering plants on Earth — 100 million years old. We are that enduring.",
        ],
        euchred: [
            "Well shoot.",
            "Bless my heart.",
            "That stings a little, I won't lie.",
            "Well I never.",
            "Didn't see that coming and I'm a little embarrassed.",
            "Lord have mercy.",
            "I need to sit down. I need a sweet tea and a moment.",
            "Honey, even my best pie has burned before. We still ate it.",
            "There's a Southern saying: 'Even the best cook burns the biscuits sometimes.' This was the biscuits.",
            "Pecans are the official state nut of Alabama, Arkansas, and Texas. We belong everywhere. We'll rebound.",
            "I've made cobbler in a kitchen without AC in August. That's harder than this.",
        ],
        marched: [
            "Honey, we swept the whole table.",
            "Five tricks. We got 'em all.",
            "Now THAT is how you play Euchre.",
            "I could cry. Happy tears, baby.",
            "That's just gorgeous play right there.",
            "March. We marched right over 'em.",
            "Sweeter than peach preserves on a warm biscuit.",
            "Five tricks. Mama would be so proud.",
            "That's a full cobbler. Warm. Perfect. Every slice ours.",
        ],
        weWon: [
            "We did it, sweetheart.",
            "Twenty-one points. I am so pleased.",
            "Honey, we WON.",
            "Well I'll be.",
            "That was a good game. A real good game.",
            "I knew we had it in us.",
            "Sweet as the first peach of the season.",
            "I'm going to bake something to celebrate. You're invited.",
        ],
        weLost: [
            "Well. That's a shame.",
            "Bless our hearts.",
            "We gave it our best, and I mean that.",
            "There's always tomorrow, sugar.",
            "I'm not sad. I'm a little sad.",
            "We'll get 'em next time. That's a promise.",
            "Even the sweetest tea has a bitter moment. We'll brew a better pot.",
            "Colonel Sanders heard no a thousand times. We heard no once. We are ahead of schedule.",
            "Honeybees travel 55,000 miles to make a pound of honey. We go the distance too. Next game.",
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

    // ─────────────────────────────────────────────────────────────────────────
    // All personas + rotation logic
    // ─────────────────────────────────────────────────────────────────────────

    static let all: [PartnerPersona] = [rex, eunice, chad, maren, donnie, dale, val, bianca, brock, mae]

    private static let lastUsedKey = "justeuchre.persona.lastUsed"

    static func next() -> PartnerPersona {
        let pool = all
        let idx = PersonaCycle.nextIndex(totalCount: UInt64(pool.count))
        let persona = pool[Int(idx)]
        UserDefaults.standard.set(persona.name, forKey: lastUsedKey)
        return persona
    }

    /// Returns the persona selected for the current/most recent game, or nil if none has been chosen yet.
    static func lastUsed() -> PartnerPersona? {
        guard let name = UserDefaults.standard.string(forKey: lastUsedKey) else { return nil }
        return all.first { $0.name == name }
    }
}

// MARK: - Non-repeating Persona Cycle

private enum PersonaCycle {
    private static let startKey  = "justeuchre.persona.start"
    private static let stepKey   = "justeuchre.persona.step"
    private static let cursorKey = "justeuchre.persona.cursor"
    private static let countKey  = "justeuchre.persona.count"

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
