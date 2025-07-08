import Foundation

// MARK: - CoachResponse Data Model
// The top-level struct matching the JSON output from Gemini 2.0 Flash
struct CoachResponse: Codable {
    let shotID: String
    let outcome: String
    let shotType: String
    let analysis: ShotAnalysis
    
    // Computed properties for easier use
    var shotOutcome: ShotOutcome {
        switch outcome.uppercased() {
        case "MAKE":
            return .make
        case "MISS":
            return .miss
        default:
            return .indeterminate
        }
    }
    
    var shotCategory: ShotCategory {
        switch shotType.lowercased() {
        case "layup":
            return .layup
        case "mid-range":
            return .midRange
        case "three-pointer":
            return .threePointer
        default:
            return .midRange // Default fallback
        }
    }
}

// MARK: - ShotAnalysis
// The nested analysis part containing feedback
struct ShotAnalysis: Codable {
    let positiveFeedback: String
    let correctiveFeedback: String
}

// MARK: - Supporting Enums
enum ShotOutcome: String, CaseIterable {
    case make = "MAKE"
    case miss = "MISS"
    case indeterminate = "INDETERMINATE"
}

enum ShotCategory: String, CaseIterable {
    case layup = "Layup"
    case midRange = "Mid-Range"
    case threePointer = "Three-Pointer"
    
    var displayName: String {
        return rawValue
    }
}

// MARK: - Gemini Live API Response Wrapper
// Wrapper for the actual response from Gemini Live API
struct GeminiLiveResponse: Codable {
    let serverContent: ServerContent?
    let setupComplete: Bool?
}

struct ServerContent: Codable {
    let modelTurn: ModelTurn?
    let turnComplete: Bool?
}

struct ModelTurn: Codable {
    let role: String?
    let parts: [ContentPart]?
}

struct ContentPart: Codable {
    let text: String?
}

// MARK: - Gemini Live API Message Structures
struct GeminiSetupMessage: Codable {
    let setup: SetupConfig
}

struct SetupConfig: Codable {
    let model: String
    let systemInstruction: SystemInstruction
    let generationConfig: GenerationConfig
}

struct SystemInstruction: Codable {
    let parts: [TextPart]
}

struct TextPart: Codable {
    let text: String
}

struct GenerationConfig: Codable {
    let responseModalities: [String]
    let temperature: Double?
    let maxOutputTokens: Int?
}

struct GeminiClientMessage: Codable {
    let clientContent: ClientContent
}

struct ClientContent: Codable {
    let turns: [Turn]
    let turnComplete: Bool
}

struct Turn: Codable {
    let role: String
    let parts: [Part]
}

struct Part: Codable {
    let text: String?
    let inlineData: InlineData?
}

struct InlineData: Codable {
    let mimeType: String
    let data: String
}