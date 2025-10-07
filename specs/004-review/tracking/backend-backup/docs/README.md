# Pomodoro Genie API Documentation

This directory contains comprehensive API documentation for the Pomodoro Genie backend service.

## Overview

The Pomodoro Genie API is a RESTful service that provides endpoints for managing tasks, pomodoro sessions, user accounts, and productivity analytics. The API is designed to support cross-platform clients including mobile apps, web applications, and desktop clients.

## Documentation Files

- `swagger.yaml` - OpenAPI 3.0 specification with complete API documentation
- `README.md` - This file, providing setup and usage instructions
- `generate-docs.sh` - Script to generate HTML documentation from Swagger spec

## API Features

### Core Functionality
- **User Authentication**: JWT-based authentication with refresh tokens
- **Task Management**: Full CRUD operations for tasks and subtasks
- **Pomodoro Sessions**: Timer management with pause/resume capabilities
- **Real-time Sync**: Cross-device synchronization with conflict resolution
- **Analytics & Reporting**: Productivity metrics and custom reports
- **Push Notifications**: Real-time notifications for session events

### Technical Features
- **Rate Limiting**: Request throttling to prevent abuse
- **Data Validation**: Comprehensive input validation and sanitization
- **Error Handling**: Consistent error response format
- **Pagination**: Efficient handling of large data sets
- **Filtering & Search**: Advanced query capabilities
- **CORS Support**: Cross-origin request handling

## Quick Start

### Viewing the Documentation

#### Option 1: Swagger UI (Recommended)

```bash
# Install swagger-ui-serve
npm install -g swagger-ui-serve

# Serve the documentation
swagger-ui-serve backend/docs/swagger.yaml

# Open http://localhost:3000 in your browser
```

#### Option 2: Redoc

```bash
# Install redoc-cli
npm install -g redoc-cli

# Generate HTML documentation
redoc-cli build backend/docs/swagger.yaml --output backend/docs/api-docs.html

# Open the generated HTML file
open backend/docs/api-docs.html
```

#### Option 3: Online Swagger Editor

1. Go to [Swagger Editor](https://editor.swagger.io/)
2. Copy the contents of `swagger.yaml`
3. Paste into the editor to view and test

### Using the Documentation Script

```bash
# Make the script executable
chmod +x backend/docs/generate-docs.sh

# Generate HTML documentation
./backend/docs/generate-docs.sh

# Serve documentation locally
./backend/docs/generate-docs.sh --serve
```

## API Base URLs

- **Production**: `https://api.pomodoro-genie.com/v1`
- **Staging**: `https://staging-api.pomodoro-genie.com/v1`
- **Development**: `http://localhost:3000/v1`

## Authentication

Most endpoints require authentication via JWT Bearer token:

```bash
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     https://api.pomodoro-genie.com/v1/tasks
```

### Getting an Authentication Token

```bash
# Register a new user
curl -X POST https://api.pomodoro-genie.com/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "StrongPassword123!"
  }'

# Login to get tokens
curl -X POST https://api.pomodoro-genie.com/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "StrongPassword123!"
  }'
```

## Common Usage Examples

### Task Management

```bash
# Create a new task
curl -X POST https://api.pomodoro-genie.com/v1/tasks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Complete project documentation",
    "description": "Write comprehensive API documentation",
    "priority": "high",
    "estimated_pomodoros": 5,
    "tags": ["documentation", "urgent"]
  }'

# List tasks with filtering
curl "https://api.pomodoro-genie.com/v1/tasks?status=pending&priority=high" \
  -H "Authorization: Bearer $TOKEN"

# Update a task
curl -X PUT https://api.pomodoro-genie.com/v1/tasks/TASK_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "completed",
    "completed_pomodoros": 5
  }'
```

### Pomodoro Sessions

```bash
# Start a work session
curl -X POST https://api.pomodoro-genie.com/v1/pomodoro/sessions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "task_id": "TASK_ID",
    "session_type": "work",
    "planned_duration": 1500
  }'

# Pause a session
curl -X PUT https://api.pomodoro-genie.com/v1/pomodoro/sessions/SESSION_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "pause"
  }'

# Complete a session
curl -X PUT https://api.pomodoro-genie.com/v1/pomodoro/sessions/SESSION_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "complete",
    "actual_duration": 1495
  }'
```

### Reports and Analytics

```bash
# Generate a weekly report
curl "https://api.pomodoro-genie.com/v1/reports?type=weekly&start_date=2024-01-01T00:00:00Z&end_date=2024-01-07T23:59:59Z" \
  -H "Authorization: Bearer $TOKEN"

# Get analytics data
curl "https://api.pomodoro-genie.com/v1/reports/analytics?period=week&metrics=productivity_score,focus_time" \
  -H "Authorization: Bearer $TOKEN"
```

## Response Format

All API responses follow a consistent format:

### Success Response
```json
{
  "success": true,
  "data": { /* response data */ },
  "pagination": { /* pagination info if applicable */ }
}
```

### Error Response
```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": "Additional error details"
  },
  "success": false
}
```

## Rate Limiting

The API implements rate limiting with the following limits:

- **Authenticated users**: 100 requests per minute
- **Unauthenticated users**: 20 requests per minute

Rate limit headers are included in responses:

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1642694400
```

## Error Codes

Common error codes and their meanings:

| Code | Description |
|------|-------------|
| `VALIDATION_ERROR` | Invalid input data |
| `AUTHENTICATION_REQUIRED` | Missing or invalid authentication |
| `AUTHORIZATION_FAILED` | Insufficient permissions |
| `RESOURCE_NOT_FOUND` | Requested resource does not exist |
| `RATE_LIMIT_EXCEEDED` | Too many requests |
| `INTERNAL_SERVER_ERROR` | Server error |
| `SERVICE_UNAVAILABLE` | Service temporarily unavailable |

## Data Types and Validation

### Common Field Types

- **UUID**: Standard UUID format (e.g., `123e4567-e89b-12d3-a456-426614174000`)
- **DateTime**: ISO 8601 format (e.g., `2024-01-15T10:30:00Z`)
- **Email**: Valid email address format
- **Password**: Minimum 8 characters, maximum 128 characters
- **Duration**: Time in seconds (integer)

### Validation Rules

- **Task Title**: 1-200 characters, required
- **Task Description**: 0-1000 characters, optional
- **Email**: Must be valid email format
- **Password**: Must contain uppercase, lowercase, digit, and special character
- **Pomodoro Duration**: 60-7200 seconds (1 minute to 2 hours)

## Synchronization

The API supports cross-device synchronization using a push/pull model:

### Pull Changes
```bash
curl -X POST https://api.pomodoro-genie.com/v1/sync/pull \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "last_sync_timestamp": "2024-01-15T10:30:00Z",
    "device_id": "device_123"
  }'
```

### Push Changes
```bash
curl -X POST https://api.pomodoro-genie.com/v1/sync/push \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "device_123",
    "changes": [
      {
        "entity_type": "task",
        "entity_id": "TASK_ID",
        "operation": "update",
        "data": { /* updated task data */ },
        "timestamp": "2024-01-15T10:35:00Z"
      }
    ]
  }'
```

## Testing the API

### Using cURL

All examples in this documentation use cURL and can be run directly from the command line.

### Using Postman

1. Import the OpenAPI specification into Postman
2. Set up environment variables for base URL and authentication token
3. Use the pre-configured requests and examples

### Using HTTPie

```bash
# Install HTTPie
pip install httpie

# Example usage
http POST api.pomodoro-genie.com/v1/auth/login \
  email=john@example.com \
  password=StrongPassword123!

http GET api.pomodoro-genie.com/v1/tasks \
  Authorization:"Bearer $TOKEN"
```

## SDK and Client Libraries

Official client libraries are available for:

- **JavaScript/TypeScript**: `npm install pomodoro-genie-api`
- **Python**: `pip install pomodoro-genie-api`
- **Go**: `go get github.com/pomodoro-genie/go-client`
- **Swift**: Available through Swift Package Manager
- **Dart/Flutter**: Available on pub.dev

Example usage with JavaScript SDK:

```javascript
import { PomodoroGenieAPI } from 'pomodoro-genie-api';

const api = new PomodoroGenieAPI({
  baseURL: 'https://api.pomodoro-genie.com/v1',
  token: 'your-jwt-token'
});

// Create a task
const task = await api.tasks.create({
  title: 'Complete API documentation',
  priority: 'high',
  estimated_pomodoros: 3
});

// Start a pomodoro session
const session = await api.pomodoro.start({
  task_id: task.id,
  session_type: 'work',
  planned_duration: 1500
});
```

## WebSocket API

Real-time updates are available via WebSocket connection:

```javascript
const ws = new WebSocket('wss://api.pomodoro-genie.com/v1/ws');

ws.onopen = () => {
  // Authenticate
  ws.send(JSON.stringify({
    type: 'auth',
    token: 'your-jwt-token'
  }));
};

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  // Handle real-time updates
  console.log('Received update:', data);
};
```

## Performance Considerations

### Caching

The API implements caching at multiple levels:

- **HTTP Caching**: Standard cache headers for static content
- **Application Caching**: Redis-based caching for frequently accessed data
- **CDN Caching**: Global content delivery for static assets

### Pagination

Use pagination for large data sets:

```bash
# Get first page (20 items)
curl "https://api.pomodoro-genie.com/v1/tasks?page=1&limit=20" \
  -H "Authorization: Bearer $TOKEN"

# Get next page
curl "https://api.pomodoro-genie.com/v1/tasks?page=2&limit=20" \
  -H "Authorization: Bearer $TOKEN"
```

### Filtering and Search

Optimize queries using filtering:

```bash
# Filter by multiple criteria
curl "https://api.pomodoro-genie.com/v1/tasks?status=pending&priority=high&tags=urgent" \
  -H "Authorization: Bearer $TOKEN"

# Search by text
curl "https://api.pomodoro-genie.com/v1/tasks?search=documentation" \
  -H "Authorization: Bearer $TOKEN"
```

## Security

### Best Practices

1. **Always use HTTPS** in production
2. **Store JWT tokens securely** (never in localStorage for web apps)
3. **Implement token refresh** to maintain sessions
4. **Validate all input** on the client side as well
5. **Handle rate limiting** gracefully in your application
6. **Log security events** for monitoring

### Token Management

```javascript
// Example token refresh implementation
async function refreshToken() {
  try {
    const response = await fetch('/v1/auth/refresh', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${refreshToken}`
      },
      body: JSON.stringify({
        refresh_token: refreshToken
      })
    });

    const data = await response.json();
    accessToken = data.access_token;

    // Schedule next refresh
    setTimeout(refreshToken, (data.expires_in - 300) * 1000);
  } catch (error) {
    // Handle refresh failure (redirect to login)
    window.location.href = '/login';
  }
}
```

## Support and Resources

### Documentation Updates

This documentation is automatically generated from the OpenAPI specification. To request updates:

1. Submit an issue on the project repository
2. Create a pull request with proposed changes
3. Contact the API team directly

### API Status

Check the current API status and uptime:
- **Status Page**: https://status.pomodoro-genie.com
- **Health Check**: https://api.pomodoro-genie.com/v1/health

### Community and Support

- **GitHub Repository**: https://github.com/pomodoro-genie/api
- **Discord Community**: https://discord.gg/pomodoro-genie
- **Stack Overflow**: Tag your questions with `pomodoro-genie-api`
- **Support Email**: api-support@pomodoro-genie.com

### Changelog

API changes and updates are documented in:
- **API Changelog**: https://docs.pomodoro-genie.com/changelog
- **Breaking Changes**: https://docs.pomodoro-genie.com/breaking-changes
- **Migration Guides**: https://docs.pomodoro-genie.com/migrations