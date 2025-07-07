import Foundation

class CoachingTipsManager {
    // MARK: - Properties
    private var coachingData: CoachingData?
    
    // MARK: - Initialization
    init() {
        loadCoachingTips()
    }
    
    // MARK: - Public Methods
    func getRandomTip() -> String {
        guard let tips = coachingData?.tips, !tips.isEmpty else {
            return "Keep practicing your form!"
        }
        return tips.randomElement() ?? "Focus on your shooting fundamentals!"
    }
    
    func getEncouragement() -> String {
        guard let encouragement = coachingData?.encouragement, !encouragement.isEmpty else {
            return "Great job!"
        }
        return encouragement.randomElement() ?? "Keep it up!"
    }
    
    func getMakeComment() -> String {
        guard let makes = coachingData?.makes, !makes.isEmpty else {
            return "Great shot!"
        }
        return makes.randomElement() ?? "Nice shot!"
    }
    
    func getMissComment() -> String {
        guard let misses = coachingData?.misses, !misses.isEmpty else {
            return "Keep shooting!"
        }
        return misses.randomElement() ?? "Next one's going in!"
    }
    
    func getContextualTip(for outcome: ShotOutcome) -> String {
        switch outcome {
        case .make:
            return getMakeComment()
        case .miss:
            return getMissComment()
        }
    }
    
    // MARK: - Private Methods
    private func loadCoachingTips() {
        guard let path = Bundle.main.path(forResource: "coaching_tips", ofType: "json"),
              let data = NSData(contentsOfFile: path) as Data? else {
            print("❌ Could not load coaching_tips.json")
            return
        }
        
        do {
            coachingData = try JSONDecoder().decode(CoachingData.self, from: data)
            print("✅ Loaded \(coachingData?.tips.count ?? 0) coaching tips")
        } catch {
            print("❌ Error decoding coaching tips: \(error)")
        }
    }
}

// MARK: - Supporting Types
struct CoachingData: Codable {
    let tips: [String]
    let encouragement: [String]
    let makes: [String]
    let misses: [String]
}