# LeBot James Token Service

Secure backend service for managing ephemeral authentication tokens for the LeBot James basketball coaching app.

## Architecture

This backend service provides:
- **Ephemeral Token Management**: Issues temporary, restricted API keys for direct client-to-Gemini communication
- **Shot Analysis Fallback**: Direct REST API for shot analysis when Live API is unavailable
- **Security**: Rate limiting, CORS, and secure token lifecycle management

## Setup

### 1. Install Dependencies

```bash
cd Backend
npm install
```

### 2. Environment Configuration

Create a `.env` file with your configuration:

```env
# Your Google API key
GOOGLE_API_KEY=your_google_api_key_here

# Server settings
PORT=3000
NODE_ENV=development

# CORS origins (your app domains)
ALLOWED_ORIGINS=http://localhost:3000
```

### 3. Development

```bash
# Start in development mode
npm run dev

# Build for production
npm run build

# Start production server
npm start
```

## API Endpoints

### Authentication

#### `POST /auth/request-token`
Request an ephemeral token for direct Gemini Live API access.

**Request:**
```json
{
  "deviceId": "device-uuid",
  "userId": "user-id-optional"
}
```

**Response:**
```json
{
  "token": "projects/lebot-james/locations/global/authTokens/token-xyz",
  "expiresAt": "2024-01-01T10:30:00Z",
  "sessionStartDeadline": "2024-01-01T10:02:00Z"
}
```

### Analysis

#### `POST /analyze/shot`
Direct shot analysis (fallback when Live API unavailable).

**Request:**
```json
{
  "imageBase64": "base64-encoded-image-data",
  "lastTip": "previous-tip-to-avoid-repetition"
}
```

**Response:**
```json
{
  "outcome": "make",
  "tip": "Keep your follow-through consistent"
}
```

### Health Check

#### `GET /health`
Service health status.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T10:00:00Z",
  "service": "lebot-james-token-service"
}
```

## Security Features

- **Helmet**: Security headers
- **CORS**: Cross-origin request protection
- **Rate Limiting**: Prevent abuse
- **Token Expiration**: Automatic token cleanup
- **Input Validation**: Request sanitization

## Deployment

### Heroku

```bash
# Login to Heroku
heroku login

# Create app
heroku create lebot-james-token-service

# Set environment variables
heroku config:set GOOGLE_API_KEY=your_key_here
heroku config:set NODE_ENV=production

# Deploy
git push heroku main
```

### Vercel

```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel --prod
```

### Google Cloud Run

```bash
# Build container
docker build -t lebot-james-token-service .

# Deploy to Cloud Run
gcloud run deploy lebot-james-token-service \
  --image gcr.io/your-project/lebot-james-token-service \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

## Development Notes

- The current implementation uses mock ephemeral tokens since the actual Google AI ephemeral token API may not be publicly available yet
- When the real ephemeral token API becomes available, update the `/auth/request-token` endpoint to use the actual Google AI SDK method
- The `/analyze/shot` endpoint serves as a fallback for direct analysis without WebSocket connections

## Testing

```bash
# Test token endpoint
curl -X POST http://localhost:3000/auth/request-token \
  -H "Content-Type: application/json" \
  -d '{"deviceId": "test-device"}'

# Test shot analysis
curl -X POST http://localhost:3000/analyze/shot \
  -H "Content-Type: application/json" \
  -d '{"imageBase64": "base64-image-data", "lastTip": ""}'
``` 