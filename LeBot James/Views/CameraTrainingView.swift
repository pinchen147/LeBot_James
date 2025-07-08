import SwiftUI

struct CameraTrainingView: View {
    @StateObject private var sessionManager = TrainingSessionManager()
    @Environment(\.dismiss) private var dismiss
    @State private var lastShotOutcome: ShotOutcome? = nil
    
    // Computed property to simplify percentage calculation
    private var shootingPercentage: Int {
        guard sessionManager.totalShots > 0 else { return 0 }
        return Int((Double(sessionManager.makes) / Double(sessionManager.totalShots)) * 100)
    }
    
    var body: some View {
        ZStack {
            // AR Camera View
            ARViewRepresentable(sessionManager: sessionManager)
                .ignoresSafeArea(.all)
            
            // UI Overlays
            VStack {
                // Top UI
                HStack {
                    // Status Indicator
                    HStack(spacing: 8) {
                        Circle()
                            .fill(sessionManager.isAnalyzing ? Color.yellow : Color.green)
                            .frame(width: 8, height: 8)
                        
                        Text(sessionManager.isAnalyzing ? "Analyzing..." : "Listening")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(16)
                    
                    Spacer()
                    
                    // End Session Button
                    Button(action: {
                        sessionManager.endSession()
                        dismiss()
                    }) {
                        Text("End Session")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(16)
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal)
                
                Spacer()
                
                // Shot result overlay
                if let outcome = lastShotOutcome {
                    VStack(spacing: 16) {
                        Image(systemName: outcome == .make ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 100))
                            .foregroundColor(outcome == .make ? .green : .red)
                            .transition(.scale.combined(with: .opacity).animation(.spring(response: 0.5, dampingFraction: 0.7)))
                        
                        Text(outcome == .make ? "SWISH!" : "KEEP SHOOTING!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .transition(.opacity.animation(.easeInOut))
                        
                        // Show current tip if available
                        if !sessionManager.currentTip.isEmpty {
                            Text(sessionManager.currentTip)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .transition(.opacity.animation(.easeInOut.delay(0.2)))
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.7))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(outcome == .make ? Color.green : Color.red, lineWidth: 2)
                            )
                    )
                    .transition(.scale.combined(with: .opacity).animation(.spring()))
                }
                
                Spacer()
                
                // Bottom UI - Shot Counter
                HStack {
                    Spacer()
                    
                    VStack(spacing: 8) {
                        // Makes/Total with visual emphasis
                        HStack(spacing: 8) {
                            Text("\(sessionManager.makes)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            
                            Text("/")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("\(sessionManager.totalShots)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        Text("MAKES")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.7))
                        
                        // Shooting percentage with color coding
                        Text("\(shootingPercentage)%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(percentageColor(shootingPercentage))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.7))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                    )
                    
                    Spacer()
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            sessionManager.startSession()
        }
        .onDisappear {
            sessionManager.endSession()
        }
        .onReceive(sessionManager.$lastShotOutcome) { outcome in
            if let outcome = outcome {
                withAnimation {
                    self.lastShotOutcome = outcome
                }
                
                // Reset after a delay (longer to show coaching tip)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation {
                        self.lastShotOutcome = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func percentageColor(_ percentage: Int) -> Color {
        switch percentage {
        case 80...100:
            return .green
        case 60...79:
            return .yellow
        case 40...59:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    CameraTrainingView()
}