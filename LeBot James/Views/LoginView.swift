import SwiftUI

struct LoginView: View {
    @State private var showCameraView = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()
                
                // App Logo and Title
                VStack(spacing: 16) {
                    Image(systemName: "basketball")
                        .font(.system(size: 80))
                        .foregroundColor(.orange)
                    
                    Text("LeBot James")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                // Value Proposition
                VStack(spacing: 12) {
                    Text("Real-Time AI Coaching")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("to Perfect Your Jumpshot")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Get instant feedback on your shooting form with AI-powered analysis")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // CTA Button
                Button(action: {
                    showCameraView = true
                }) {
                    Text("Start Training")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.orange)
                        .cornerRadius(28)
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showCameraView) {
                CameraTrainingView()
            }
        }
    }
}

#Preview {
    LoginView()
}
