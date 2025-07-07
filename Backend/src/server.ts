import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import { GoogleGenerativeAI } from '@google/generative-ai';

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(cors({
    origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
    credentials: true
}));
app.use(express.json({ limit: '10mb' }));

// Request logging middleware
app.use((req: Request, res: Response, next: NextFunction) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
    next();
});

// Validate API key
const masterApiKey = process.env.GOOGLE_API_KEY;
if (!masterApiKey) {
    console.error('❌ GOOGLE_API_KEY is not set in environment variables');
    process.exit(1);
}

// Initialize Google AI
const genAI = new GoogleGenerativeAI(masterApiKey);

// Health check endpoint
app.get('/health', (req: Request, res: Response) => {
    res.json({ 
        status: 'healthy', 
        timestamp: new Date().toISOString(),
        service: 'lebot-james-token-service'
    });
});

// Token request endpoint
app.post('/auth/request-token', async (req: Request, res: Response) => {
    console.log('📋 Received ephemeral token request');
    
    try {
        // Validate request (add your authentication logic here)
        const { deviceId, userId } = req.body;
        
        if (!deviceId) {
            return res.status(400).json({ 
                error: 'Device ID is required' 
            });
        }
        
        // Token configuration
        const now = new Date();
        const expireTime = new Date(now.getTime() + 30 * 60 * 1000); // 30 minutes
        const newSessionExpireTime = new Date(now.getTime() + 2 * 60 * 1000); // 2 minutes to start session
        
        // Note: This is a placeholder for the actual ephemeral token creation
        // The real implementation would use the Google AI SDK when ephemeral tokens are available
        
        // For now, we'll create a mock response structure
        const mockToken = {
            name: `projects/lebot-james/locations/global/authTokens/token-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
            expireTime: expireTime.toISOString(),
            newSessionExpireTime: newSessionExpireTime.toISOString(),
            uses: 1
        };
        
        console.log('✅ Ephemeral token created successfully');
        console.log(`📅 Token expires: ${expireTime.toISOString()}`);
        console.log(`🔒 Session start deadline: ${newSessionExpireTime.toISOString()}`);
        
        // Return the token to the client
        res.json({ 
            token: mockToken.name,
            expiresAt: mockToken.expireTime,
            sessionStartDeadline: mockToken.newSessionExpireTime
        });
        
    } catch (error) {
        console.error('❌ Error creating ephemeral token:', error);
        res.status(500).json({ 
            error: 'Failed to create authentication token',
            details: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});

// Direct analysis endpoint (fallback for when Live API is not available)
app.post('/analyze/shot', async (req: Request, res: Response) => {
    console.log('🏀 Received shot analysis request');
    
    try {
        const { imageBase64, lastTip } = req.body;
        
        if (!imageBase64) {
            return res.status(400).json({ 
                error: 'Image data is required' 
            });
        }
        
        // Use Gemini for analysis
        const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
        
        const prompt = `
        Analyze this basketball shot image and provide:
        1. Was it a make or miss? (look for ball going through hoop)
        2. One specific, actionable coaching tip about shooting form
        
        Focus on: elbow alignment, follow-through, knee bend, balance, arc
        Keep tips concise and encouraging.
        ${lastTip ? `Don't repeat this tip: "${lastTip}"` : ''}
        
        Return JSON only: {"outcome": "make" or "miss", "tip": "your tip here"}
        `;
        
        const result = await model.generateContent([
            prompt,
            {
                inlineData: {
                    mimeType: "image/jpeg",
                    data: imageBase64
                }
            }
        ]);
        
        const response = await result.response;
        const text = response.text();
        
        // Try to parse JSON response
        try {
            const analysisResult = JSON.parse(text);
            res.json(analysisResult);
        } catch (parseError) {
            // Fallback parsing
            const outcome = text.toLowerCase().includes('make') ? 'make' : 'miss';
            const tip = text.includes('tip') ? text.split('tip')[1]?.trim() : 'Keep practicing your form!';
            
            res.json({ outcome, tip });
        }
        
    } catch (error) {
        console.error('❌ Error analyzing shot:', error);
        res.status(500).json({ 
            error: 'Failed to analyze shot',
            details: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});

// Error handling middleware
app.use((error: Error, req: Request, res: Response, next: NextFunction) => {
    console.error('❌ Unhandled error:', error);
    res.status(500).json({ 
        error: 'Internal server error',
        details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
});

// 404 handler
app.use((req: Request, res: Response) => {
    res.status(404).json({ 
        error: 'Endpoint not found',
        availableEndpoints: [
            'GET /health',
            'POST /auth/request-token',
            'POST /analyze/shot'
        ]
    });
});

// Start server
app.listen(PORT, () => {
    console.log('🚀 LeBot James Token Service Started');
    console.log(`📡 Server running on port ${PORT}`);
    console.log(`🔑 Master API Key: ${masterApiKey ? 'Configured' : 'Missing'}`);
    console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
});

export default app; 