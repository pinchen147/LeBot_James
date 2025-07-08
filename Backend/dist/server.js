import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import { GoogleGenerativeAI } from '@google/generative-ai';
dotenv.config();
const app = express();
const PORT = parseInt(process.env.PORT || '3000', 10);
app.use(helmet());
app.use(cors({
    origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
    credentials: true
}));
app.use(express.json({ limit: '10mb' }));
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
    next();
});
const masterApiKey = process.env.GOOGLE_API_KEY;
if (!masterApiKey) {
    console.error('❌ GOOGLE_API_KEY is not set in environment variables');
    process.exit(1);
}
const genAI = new GoogleGenerativeAI(masterApiKey);
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        service: 'lebot-james-token-service'
    });
});
app.post('/auth/request-token', async (req, res) => {
    console.log('📋 Received ephemeral token request');
    try {
        const { deviceId, userId } = req.body;
        if (!deviceId) {
            res.status(400).json({
                error: 'Device ID is required'
            });
            return;
        }
        const now = new Date();
        const expireTime = new Date(now.getTime() + 30 * 60 * 1000);
        const newSessionExpireTime = new Date(now.getTime() + 2 * 60 * 1000);
        const mockToken = {
            name: `projects/lebot-james/locations/global/authTokens/token-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
            expireTime: expireTime.toISOString(),
            newSessionExpireTime: newSessionExpireTime.toISOString(),
            uses: 1
        };
        console.log('✅ Ephemeral token created successfully');
        console.log(`📅 Token expires: ${expireTime.toISOString()}`);
        console.log(`🔒 Session start deadline: ${newSessionExpireTime.toISOString()}`);
        res.json({
            token: mockToken.name,
            expiresAt: mockToken.expireTime,
            sessionStartDeadline: mockToken.newSessionExpireTime
        });
    }
    catch (error) {
        console.error('❌ Error creating ephemeral token:', error);
        res.status(500).json({
            error: 'Failed to create authentication token',
            details: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});
app.post('/analyze/shot', async (req, res) => {
    console.log('🏀 Received shot analysis request');
    try {
        const { imageBase64, lastTip } = req.body;
        if (!imageBase64) {
            res.status(400).json({
                error: 'Image data is required'
            });
            return;
        }
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
        try {
            const analysisResult = JSON.parse(text);
            res.json(analysisResult);
        }
        catch (parseError) {
            const outcome = text.toLowerCase().includes('make') ? 'make' : 'miss';
            const tip = text.includes('tip') ? text.split('tip')[1]?.trim() : 'Keep practicing your form!';
            res.json({ outcome, tip });
        }
    }
    catch (error) {
        console.error('❌ Error analyzing shot:', error);
        res.status(500).json({
            error: 'Failed to analyze shot',
            details: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});
app.use((error, req, res, next) => {
    console.error('❌ Unhandled error:', error);
    res.status(500).json({
        error: 'Internal server error',
        details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
});
app.use((req, res) => {
    res.status(404).json({
        error: 'Endpoint not found',
        availableEndpoints: [
            'GET /health',
            'POST /auth/request-token',
            'POST /analyze/shot'
        ]
    });
});
app.listen(PORT, '0.0.0.0', () => {
    console.log('🚀 LeBot James Token Service Started');
    console.log(`📡 Server running on port ${PORT}`);
    console.log(`🌍 Server accessible at: http://0.0.0.0:${PORT}`);
    console.log(`🔑 Master API Key: ${masterApiKey ? 'Configured' : 'Missing'}`);
    console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
});
export default app;
//# sourceMappingURL=server.js.map