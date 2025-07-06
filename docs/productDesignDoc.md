LeBot_James: AI Basketball Coach – Product Design Document (MVP)
1. Overview

Solo basketball practice is a fundamental part of player development, but it often lacks a critical component: immediate, expert feedback. Players can shoot for hours, unknowingly reinforcing bad habits in their form. LeBot_James is an iOS-based AI basketball coach that watches you practice, providing the real-time analysis and feedback of a personal trainer, right on your iPhone.

The app uses the phone's camera, positioned on a tripod, to observe the player. By intelligently selecting and analyzing key frames of each shot with a powerful multimodal AI (Google's Gemini), it provides a simple shot counter and, more importantly, personalized, actionable coaching tips delivered via audio and augmented reality (AR) overlays. The system analyzes shooting form, shot trajectory, and the outcome (make or miss) to deliver context-aware feedback after every attempt.

This app is iOS-first, built for simplicity and effectiveness. The MVP is hyper-focused on two core functions: counting shots and providing passive coaching to improve a player's form. The system design emphasizes:

Hands-Free Operation: Set up your phone on a tripod, start the session, and practice without interruption.

Real-Time Shot Counting: An on-screen counter automatically tracks makes and total attempts.

Per-Shot AI Coaching: After each shot, receive a concise audio tip based on the AI's analysis of your form (e.g., "Keep that elbow in," "Good follow-through").

Visual Feedback via AR: Augmented reality overlays provide instant visual confirmation of makes/misses and can highlight areas for improvement, like your shooting arm's angle or the arc of the ball.

Efficient AI Analysis: The app intelligently selects key frames from the video stream to send for cloud analysis (~1 FPS), respecting the Gemini API's capabilities and optimizing performance.

Minimalist Interface: The app consists of only two primary screens: a simple entry/paywall screen and the main camera view where all the action happens.

LeBot_James aims to be the ultimate practice partner, making every training session more productive by providing the immediate feedback loop necessary for meaningful improvement.

2. Feature Overview (MVP)

The MVP will focus on delivering a tight, valuable feedback loop with just two core features.

Feature	Description	Implementation Details
1. Automatic Shot Counting	The app visually detects each shot attempt and its outcome (make or miss), displaying a running tally on the screen.	Computer Vision: The app continuously monitors the camera feed. On-device heuristics (e.g., detecting a rapid upward motion of the player and ball, followed by the ball's trajectory towards the hoop) identify a "shot event." A key frame from the event (e.g., the ball near the rim) is sent to the Gemini Vision API. The prompt asks Gemini to determine if the ball went through the hoop. The result ("make" or "miss") is returned. <br><br> UI/AR: The UI displays a simple counter (e.g., "Shots: 7/12"). After each shot, an AR overlay provides instant visual feedback: a green checkmark ✓ or a red ✗ briefly appears over the hoop. This is rendered using ARKit.
2. Passive AI Coaching	After each shot, the AI provides a single, concise piece of audio feedback based on its analysis of the player's shooting form.	Pose Estimation & AI Reasoning: During the "shot event," the app sends a key frame (or a small sequence of frames) capturing the player's form at the point of release to the Gemini Vision API. The prompt instructs the AI to analyze the player's shooting mechanics (e.g., knee bend, elbow alignment, hand position, follow-through) using pose estimation. <br><br> RAG for Quality: To ensure high-quality feedback, the prompt is augmented with a small piece of expert knowledge retrieved from a Supabase database (our Coaching Knowledge Base). For example: [CONTEXT from KB: "A 90-degree angle on the shooting elbow is ideal..."] Analyze the user's form in this image and provide one concise tip. <br><br> Audio & Context: The AI's textual feedback is converted to speech using iOS's AVSpeechSynthesizer. The Training Session Manager tracks the feedback given, ensuring the AI doesn't repeat the same tip consecutively, making the coaching feel more dynamic and aware. The feedback is "passive"—it's delivered after the shot, not as a command.
3. System Architecture

The architecture is designed for leanness and efficiency, consisting of the iOS client, a cloud AI model, and a lightweight backend for knowledge storage.

Generated code
iPhone (Client App)
├─ Camera & AR View (ARKit)        - Captures live video; renders AR overlays (shot result, form guides).
├─ Training Session Manager        - Core logic orchestrating the practice session.
│   ├─ Shot Event Detector         - On-device logic to identify when a shot is taken, triggering analysis.
│   ├─ Smart Frame Selector        - Selects the most relevant frame(s) of the shot (e.g., release, apex) to send to the cloud, respecting the ~1 FPS limit.
│   ├─ AI Analysis Client          - Formats the prompt (with RAG context) and sends the selected frame(s) to the Gemini API.
│   ├─ Supabase Client (Optional for MVP) - Fetches coaching tips from the knowledge base to augment AI prompts (RAG).
│   └─ Response Renderer           - Receives JSON from Gemini and translates it into UI updates (shot counter), AR overlays, and audio feedback (TTS).
├─ Audio Output (TTS)              - Speaks the coaching tips using AVSpeechSynthesizer.
└─ UI Layer (SwiftUI)              - Renders the two app screens and the minimal OSD on the camera view.

Cloud Services
├─ Google Gemini Pro Vision API    - Receives an image and a prompt. Returns a JSON object containing the shot outcome ("make"/"miss") and a coaching tip.
└─ Supabase Backend (Post-MVP)     - A simple Postgres database to store a "Coaching Knowledge Base" of expert tips, used for the RAG system to improve feedback quality. For the MVP, these tips could be hardcoded in the client.

Typical Session Flow:

Setup: The user ("Jordan") places their iPhone on a tripod, pointing it towards the basketball hoop, and opens the LeBot_James app. After the login/paywall screen, the main camera view appears. Jordan taps "Start Session."

Monitoring: The Training Session Manager activates. The Shot Event Detector begins monitoring the camera feed for motion patterns indicating a shot.

Shot Detected: Jordan takes a shot. The detector identifies the setup, release, and the ball traveling toward the hoop.

Smart Frame Selection: The Smart Frame Selector isolates one or two key frames: one of Jordan at the moment of release (for form analysis) and one of the ball at the rim (for outcome analysis).

AI Analysis: The AI Analysis Client sends these frames to the Gemini API with a prompt like: """Analyze this basketball shot. 1. Was it a make or miss? 2. Observe the player's shooting form (elbow, knees, follow-through). 3. Provide one concise, positive coaching tip based on their form. Return as JSON: {"outcome": "make/miss", "tip": "your tip here"}"""

Response Received: Gemini processes the request and returns a JSON payload, e.g., { "outcome": "miss", "tip": "Try to get more power from your legs next time." }.

Render Feedback: The Response Renderer immediately processes the JSON:

UI: The on-screen counter updates (e.g., from "7/12" to "7/13").

AR: A red ✗ overlay fades in and out over the hoop. A temporary AR line might highlight Jordan's legs to reinforce the tip visually.

Audio: The TTS engine speaks the feedback: "Try to get more power from your legs next time."

Loop: The system returns to the monitoring state, ready for the next shot. The entire cycle, from shot to feedback, should complete within 2-3 seconds to feel immediate.

4. UI/UX Design Considerations

The user experience is designed to be invisible during practice. The user interacts with the app to start and end a session, but the core value is delivered hands-free.

Screen 1: Login / Paywall:

This is the entry point to the app.

Visuals: A clean, simple screen with the app logo ("LeBot_James"), a strong value proposition ("Real-Time AI Coaching to Perfect Your Jumpshot"), and a single call-to-action button (e.g., "Unlock Pro" or "Start Free Trial").

Functionality: For the MVP, this screen can be a placeholder that simply navigates to the main camera view upon tapping the button. Full implementation would involve StoreKit for subscriptions.

Screen 2: Camera / Training View:

This is the app's primary interface. It will be active for the entire practice session.

Layout: A full-screen, landscape camera view. All UI elements are overlays designed for high visibility against a real-world background (e.g., white text with a drop shadow).

On-Screen Display (OSD): Kept to an absolute minimum.

Shot Counter: A persistent counter in one corner (e.g., Makes: 15 / Total: 25).

Status Indicator: A small icon that subtly indicates the app's state (e.g., "Listening," "Analyzing...").

Controls: A simple "End Session" button.

AR Overlays: These are the primary visual feedback mechanism. They are designed to be transient—appearing for a few seconds after a shot and then fading away to prevent cluttering the view.

Shot Result: A large, clear ✓ or ✗ icon centered on the hoop.

Form Guides (Post-MVP): Simple lines, circles, or arrows to highlight a specific body part mentioned in the audio feedback (e.g., a line showing the ideal elbow angle).

5. Technical Challenges and Mitigations

Real-Time Performance & Frame Selection: The biggest challenge is analyzing a high-speed action (a jump shot) with a cloud API limited to ~1 FPS.

Challenge: Simply sending a frame every second is inefficient and likely to miss the crucial moments of the shot.

Mitigation: The Smart Frame Selector is key. We will use on-device vision processing (e.g., iOS Vision framework's motion or trajectory detection) to buffer frames around a high-motion event. Once the event is complete (ball lands), the module will select the single best frame representing the form at release and send only that one to Gemini. This makes our use of the 1 FPS limit intelligent and targeted.

AI Accuracy & Coaching Quality: The feedback is only useful if it's accurate and relevant.

Challenge: A generic LLM might give vague, repetitive, or incorrect basketball advice.

Mitigation: Prompt Engineering & RAG. The prompt sent to Gemini will be highly specific, guiding it to look for key aspects of shooting form. For higher quality, we will implement a basic RAG system. The prompt will be augmented with a curated sentence from a "coaching bible" stored in Supabase. This grounds the AI's response in proven coaching techniques, drastically reducing hallucinations and improving the quality of the tips.

Environmental Variability: Outdoor courts have inconsistent lighting, potential occlusions, and varying distances.

Challenge: The AI might fail if the player, ball, or hoop is not clearly visible.

Mitigation: The app will have a simple setup guide ("Make sure the hoop and player are fully in frame"). During the session, if the AI repeatedly fails to analyze a shot, it can provide a helpful prompt: "I'm having trouble seeing clearly. Please check the camera's position."

Cost Management: Cloud AI API calls can be expensive, especially for video analysis.

Challenge: A 30-minute session could involve hundreds of shots and thus hundreds of API calls.

Mitigation: Our Smart Frame Selector is the primary cost-control mechanism. By only sending one or two frames per shot instead of continuous streaming, we link costs directly to user activity. The subscription model is designed to cover these operational costs. A free tier might be limited to a certain number of AI-analyzed shots per day.

6. Conclusion

LeBot_James is a focused, high-impact application that directly addresses a core need for aspiring basketball players: accessible, immediate feedback. By leveraging the power of the iPhone's camera and the advanced multimodal capabilities of Google's Gemini API, this app transforms a standard smartphone into a personal shooting coach. The MVP's tight scope—shot counting and passive coaching—ensures we can deliver a polished and genuinely useful product quickly. The architecture is lean, efficient, and built to scale, with a clear path to future enhancements like detailed analytics, personalized drill recommendations, and a richer RAG-powered knowledge base. By making every practice session smarter, LeBot_James has the potential to become an indispensable tool for players dedicated to improving their game.