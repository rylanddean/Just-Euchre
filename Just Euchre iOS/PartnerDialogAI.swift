//
//  PartnerDialogAI.swift
//  Just Euchre iOS
//
//  Uses Apple Intelligence (FoundationModels, iOS 26+) to generate
//  extra partner dialog lines in-character for the active persona.
//  Falls back silently to the curated static lines on older devices.
//

import Foundation

// MARK: - Context passed to the AI

struct PartnerDialogContext {
    let trigger: PartnerDialogTrigger
    let ourScore: Int
    let theirScore: Int
    let partnerName: String
}

// MARK: - On-device generation (iOS 26+ / Apple Intelligence)

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, *)
actor PartnerDialogAI {

    static let shared = PartnerDialogAI()

    private var sessions: [String: LanguageModelSession] = [:]

    /// Generates a short in-character line for the given persona and context.
    /// Returns `nil` if the model is unavailable or generation fails.
    func generate(for persona: PartnerPersona, context: PartnerDialogContext) async -> String? {
        guard SystemLanguageModel.default.isAvailable else { return nil }

        let session: LanguageModelSession
        if let existing = sessions[persona.id] {
            session = existing
        } else {
            let instructions = """
            You are \(persona.name), a Euchre card game partner. Your personality: \(persona.tagline)
            Rules:
            - One short sentence only (under 12 words).
            - Stay completely in character.
            - Never mention specific cards, suits, or give strategic advice.
            - Respond to the game event described by the user.
            - No emojis.
            """
            session = LanguageModelSession(
                model: SystemLanguageModel.default,
                instructions: instructions
            )
            sessions[persona.id] = session
        }

        let prompt = eventDescription(for: context)
        do {
            let response = try await session.respond(to: prompt)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : text
        } catch {
            return nil
        }
    }

    private func eventDescription(for context: PartnerDialogContext) -> String {
        let score = "Score is \(context.ourScore)-\(context.theirScore)."
        switch context.trigger {
        case .weTookTrick:   return "Our team just won a trick. \(score) React."
        case .theyTookTrick: return "The opponents just took a trick. \(score) React."
        case .weScored:      return "We just scored points this hand. \(score) React."
        case .theyScored:    return "The opponents just scored this hand. \(score) React."
        case .euchred:       return "We got euchred — the opponents set us. \(score) React."
        case .marched:       return "We just won all five tricks — a march. \(score) React."
        case .weWon:         return "We won the whole game. \(score) React."
        case .weLost:        return "We lost the game. \(score) React."
        case .trumpMade:     return "Trump was just established. React."
        case .idleComment:   return "It's your turn for some table talk during the game. \(score) Say something in character."
        }
    }
}
#endif

// MARK: - Public interface (always callable regardless of OS version)

enum PartnerDialogAIBridge {

    /// Attempts to generate an AI line on iOS 26+; calls `completion` with the result.
    /// On older OS versions or if generation fails, calls `completion(nil)` so the
    /// caller can fall back to static dialog.
    static func generate(
        for persona: PartnerPersona,
        context: PartnerDialogContext,
        completion: @escaping (String?) -> Void
    ) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            Task {
                let result = await PartnerDialogAI.shared.generate(for: persona, context: context)
                await MainActor.run { completion(result) }
            }
            return
        }
        #endif
        completion(nil)
    }
}
