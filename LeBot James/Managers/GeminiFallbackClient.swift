import Foundation
import UIKit

// Fallback client using standard Gemini API when Live API is unavailable
class GeminiFallbackClient {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
    private let session = URLSession.shared
    
    init() {
        self.apiKey = AppConfig.getAPIKey()
    }
    
    func analyzeShot(frame: CVPixelBuffer, lastTip: String, completion: @escaping (ShotAnalysisResult) -> Void) {
        // Convert frame to image
        guard let image = imageFromPixelBuffer(frame) else {
            completion(ShotAnalysisResult(outcome: .miss, tip: "Unable to analyze frame"))
            return
        }
        
        // Convert to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(ShotAnalysisResult(outcome: .miss, tip: "Unable to process image"))
            return
        }
        
        let base64Image = imageData.base64EncodedString()
        
        // Create request
        let request = createAnalysisRequest(base64Image: base64Image, lastTip: lastTip)
        
        // Send request
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Fallback API Error: \(error)")
                completion(ShotAnalysisResult(outcome: .miss, tip: "Keep practicing your form!"))
                return
            }
            
            guard let data = data else {
                completion(ShotAnalysisResult(outcome: .miss, tip: "No response from AI"))
                return
            }
            
            // Parse response
            self.parseResponse(data: data, completion: completion)
        }.resume()
    }
    
    private func createAnalysisRequest(base64Image: String, lastTip: String) -> URLRequest {
        var request = URLRequest(url: URL(string: "\(baseURL)?key=\(apiKey)")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = createPrompt(lastTip: lastTip)
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": prompt
                        ],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 200
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("Error creating request body: \(error)")
        }
        
        return request
    }
    
    private func createPrompt(lastTip: String) -> String {
        let basePrompt = """
        You are LeBot James, an AI basketball coach with Michael Jordan's authority and expertise.
        
        Analyze this basketball shot image and provide:
        1. Was it a make or miss? (look for ball going through hoop)
        2. One specific, actionable coaching tip about the player's shooting form
        
        Focus on these key aspects:
        - Shooting elbow alignment (should be under the ball)
        - Follow-through (wrist snap, fingers pointing down)
        - Knee bend and leg drive
        - Balance and foot positioning
        - Arc of the shot
        
        Guidelines:
        - Keep tips under 10 words
        - Be encouraging but authoritative like MJ
        - Focus on ONE specific improvement
        - Avoid generic advice
        """
        
        let avoidRepetition = lastTip.isEmpty ? "" : "\n- Don't repeat this previous tip: '\(lastTip)'"
        
        let formatInstructions = """
        
        Return response as JSON only:
        {
            "outcome": "make" or "miss",
            "tip": "your specific coaching tip here"
        }
        """
        
        return basePrompt + avoidRepetition + formatInstructions
    }
    
    private func parseResponse(data: Data, completion: @escaping (ShotAnalysisResult) -> Void) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            guard let candidates = json?["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let firstPart = parts.first,
                  let text = firstPart["text"] as? String else {
                print("❌ Error parsing fallback response structure")
                completion(ShotAnalysisResult(outcome: .miss, tip: "Keep working on your form!"))
                return
            }
            
            // Parse the JSON response from the AI
            if let responseData = text.data(using: .utf8),
               let responseJson = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
               let outcomeString = responseJson["outcome"] as? String,
               let tip = responseJson["tip"] as? String {
                
                let outcome: ShotOutcome = outcomeString.lowercased() == "make" ? .make : .miss
                completion(ShotAnalysisResult(outcome: outcome, tip: tip))
            } else {
                // Fallback parsing if JSON structure is different
                let outcome: ShotOutcome = text.lowercased().contains("make") ? .make : .miss
                let tip = extractTipFromText(text)
                completion(ShotAnalysisResult(outcome: outcome, tip: tip))
            }
            
        } catch {
            print("❌ Error parsing fallback response: \(error)")
            completion(ShotAnalysisResult(outcome: .miss, tip: "Focus on your follow-through!"))
        }
    }
    
    private func extractTipFromText(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("tip") || line.contains("focus") || line.contains("try") {
                return line.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return "Keep practicing your form!"
    }
    
    private func imageFromPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}