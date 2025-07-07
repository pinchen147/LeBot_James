import Foundation

struct AppConfig {
    
    // MARK: - Convenience Accessors
    // These provide easy access to Config values throughout the app
    
    static var API: Config.API.Type { Config.API.self }
    static var Vision: Config.Vision.Type { Config.Vision.self }
    static var Audio: Config.Audio.Type { Config.Audio.self }
    static var AR: Config.AR.Type { Config.AR.self }
    static var Session: Config.Session.Type { Config.Session.self }
    static var Development: Config.Development.Type { Config.Development.self }
}

// MARK: - Configuration Access
extension AppConfig {
    static func getAPIKey() -> String {
        return Config.getAPIKey()
    }
}