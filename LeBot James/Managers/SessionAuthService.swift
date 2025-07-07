import Foundation
import UIKit

class SessionAuthService {
    // MARK: - Properties
    private let tokenServiceURL: URL
    private let session = URLSession.shared
    private let deviceId: String
    
    // MARK: - Initialization
    init() {
        // Use your deployed backend URL or localhost for development
        self.tokenServiceURL = URL(string: Config.API.tokenServiceURL)!
        
        // Generate or retrieve device ID
        self.deviceId = SessionAuthService.getDeviceId()
    }
    
    // MARK: - Public Methods
    func fetchEphemeralToken(completion: @escaping (EphemeralToken?) -> Void) {
        print("🔑 Requesting ephemeral token...")
        
        var request = URLRequest(url: tokenServiceURL.appendingPathComponent("auth/request-token"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = [
            "deviceId": deviceId,
            "userId": "anonymous" // Optional: implement user authentication
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("❌ Error creating request body: \(error)")
            DispatchQueue.main.async { completion(nil) }
            return
        }
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Token request failed: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ Token request failed with status: \(httpResponse.statusCode)")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            guard let data = data else {
                print("❌ No data received")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            do {
                let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                let ephemeralToken = EphemeralToken(
                    token: tokenResponse.token,
                    expiresAt: ISO8601DateFormatter().date(from: tokenResponse.expiresAt) ?? Date().addingTimeInterval(1800),
                    sessionStartDeadline: ISO8601DateFormatter().date(from: tokenResponse.sessionStartDeadline) ?? Date().addingTimeInterval(120)
                )
                
                print("✅ Ephemeral token received")
                print("📅 Expires at: \(ephemeralToken.expiresAt)")
                print("🔒 Session start deadline: \(ephemeralToken.sessionStartDeadline)")
                
                DispatchQueue.main.async { completion(ephemeralToken) }
                
            } catch {
                print("❌ Error parsing token response: \(error)")
                DispatchQueue.main.async { completion(nil) }
            }
        }.resume()
    }
    
    // MARK: - Private Methods
    private static func getDeviceId() -> String {
        let key = "LeBot_James_Device_ID"
        
        if let existingId = UserDefaults.standard.string(forKey: key) {
            return existingId
        }
        
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }
}

// MARK: - Supporting Types
struct EphemeralToken {
    let token: String
    let expiresAt: Date
    let sessionStartDeadline: Date
    
    var isValid: Bool {
        return Date() < expiresAt
    }
    
    var canStartSession: Bool {
        return Date() < sessionStartDeadline
    }
}

private struct TokenResponse: Codable {
    let token: String
    let expiresAt: String
    let sessionStartDeadline: String
} 