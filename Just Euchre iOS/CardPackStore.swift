//
//  CardPackStore.swift
//  Just Euchre iOS
//

import UIKit

struct CardPack: Equatable {
    let id: String
    let name: String
    let subtitle: String
    let cardBackground: UIColor
    let blackSuitColor: UIColor
    let redSuitColor: UIColor
}

extension CardPack {
    static let all: [CardPack] = [classic, noir, dusk, deepBlue, forest, crimson, midnight, frost, violet, amber, teal, stone]

    static let classic = CardPack(
        id: "classic",
        name: "Classic",
        subtitle: "Clean white",
        cardBackground: UIColor(white: 0.985, alpha: 1),
        blackSuitColor: UIColor(white: 0.12, alpha: 1),
        redSuitColor: UIColor(red: 0.98, green: 0.35, blue: 0.43, alpha: 1)
    )

    static let noir = CardPack(
        id: "noir",
        name: "Noir",
        subtitle: "Dark & minimal",
        cardBackground: UIColor(red: 26/255, green: 33/255, blue: 44/255, alpha: 1),
        blackSuitColor: UIColor(white: 0.90, alpha: 1),
        redSuitColor: UIColor(red: 0.98, green: 0.42, blue: 0.49, alpha: 1)
    )

    static let dusk = CardPack(
        id: "dusk",
        name: "Dusk",
        subtitle: "Warm parchment",
        cardBackground: UIColor(red: 245/255, green: 237/255, blue: 216/255, alpha: 1),
        blackSuitColor: UIColor(red: 61/255, green: 43/255, blue: 31/255, alpha: 1),
        redSuitColor: UIColor(red: 192/255, green: 57/255, blue: 43/255, alpha: 1)
    )

    static let deepBlue = CardPack(
        id: "deepBlue",
        name: "Deep Blue",
        subtitle: "Midnight navy",
        cardBackground: UIColor(red: 13/255, green: 27/255, blue: 62/255, alpha: 1),
        blackSuitColor: UIColor(red: 142/255, green: 202/255, blue: 230/255, alpha: 1),
        redSuitColor: UIColor(red: 0.98, green: 0.35, blue: 0.43, alpha: 1)
    )

    static let forest = CardPack(
        id: "forest",
        name: "Forest",
        subtitle: "Deep green",
        cardBackground: UIColor(red: 13/255, green: 35/255, blue: 24/255, alpha: 1),
        blackSuitColor: UIColor(red: 82/255, green: 246/255, blue: 170/255, alpha: 1),
        redSuitColor: UIColor(red: 253/255, green: 215/255, blue: 88/255, alpha: 1)
    )

    static let crimson = CardPack(
        id: "crimson",
        name: "Crimson",
        subtitle: "Deep burgundy",
        cardBackground: UIColor(red: 44/255, green: 10/255, blue: 18/255, alpha: 1),
        blackSuitColor: UIColor(white: 0.90, alpha: 1),
        redSuitColor: UIColor(red: 0.98, green: 0.48, blue: 0.54, alpha: 1)
    )

    static let midnight = CardPack(
        id: "midnight",
        name: "Midnight",
        subtitle: "Black & gold",
        cardBackground: UIColor(red: 10/255, green: 10/255, blue: 15/255, alpha: 1),
        blackSuitColor: UIColor(red: 253/255, green: 215/255, blue: 88/255, alpha: 1),
        redSuitColor: UIColor(red: 0.98, green: 0.36, blue: 0.44, alpha: 1)
    )

    static let frost = CardPack(
        id: "frost",
        name: "Frost",
        subtitle: "Icy blue",
        cardBackground: UIColor(red: 228/255, green: 238/255, blue: 245/255, alpha: 1),
        blackSuitColor: UIColor(red: 46/255, green: 90/255, blue: 135/255, alpha: 1),
        redSuitColor: UIColor(red: 200/255, green: 48/255, blue: 64/255, alpha: 1)
    )

    static let violet = CardPack(
        id: "violet",
        name: "Violet",
        subtitle: "Deep purple",
        cardBackground: UIColor(red: 22/255, green: 11/255, blue: 46/255, alpha: 1),
        blackSuitColor: UIColor(red: 196/255, green: 168/255, blue: 240/255, alpha: 1),
        redSuitColor: UIColor(red: 244/255, green: 114/255, blue: 182/255, alpha: 1)
    )

    static let amber = CardPack(
        id: "amber",
        name: "Amber",
        subtitle: "Warm whiskey",
        cardBackground: UIColor(red: 44/255, green: 26/255, blue: 4/255, alpha: 1),
        blackSuitColor: UIColor(red: 245/255, green: 166/255, blue: 35/255, alpha: 1),
        redSuitColor: UIColor(red: 224/255, green: 82/255, blue: 64/255, alpha: 1)
    )

    static let teal = CardPack(
        id: "teal",
        name: "Teal",
        subtitle: "Deep ocean",
        cardBackground: UIColor(red: 8/255, green: 36/255, blue: 38/255, alpha: 1),
        blackSuitColor: UIColor(red: 64/255, green: 210/255, blue: 200/255, alpha: 1),
        redSuitColor: UIColor(red: 0.98, green: 0.36, blue: 0.44, alpha: 1)
    )

    static let stone = CardPack(
        id: "stone",
        name: "Stone",
        subtitle: "Warm gray",
        cardBackground: UIColor(red: 200/255, green: 189/255, blue: 176/255, alpha: 1),
        blackSuitColor: UIColor(red: 58/255, green: 50/255, blue: 44/255, alpha: 1),
        redSuitColor: UIColor(red: 162/255, green: 46/255, blue: 46/255, alpha: 1)
    )
}

enum CardPackStore {
    private static let key = "selectedCardPackID"

    static var selectedPackID: String {
        get { UserDefaults.standard.string(forKey: key) ?? CardPack.classic.id }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    static var selectedPack: CardPack {
        CardPack.all.first { $0.id == selectedPackID } ?? CardPack.classic
    }
}
