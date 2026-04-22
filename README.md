# PinGate Identity & OTP Service

PinGate Identity & OTP Service is a secure, production-grade authentication service responsible for customer identity verification, OTP-based authentication, session lifecycle management, and security monitoring.

The system models real-world authentication workflows used in fintech platforms, where users authenticate using a national identifier and a One-Time Pin (OTP). It is designed with a strong emphasis on security, auditability, and scalability.

---

## Overview

This service provides a controlled authentication pipeline:

1. A customer initiates an authentication request
2. A one-time verification code is generated and delivered through a secure channel
3. The customer verifies the code within a defined time window
4. A session is established upon successful verification
5. Authentication activity is monitored and recorded for audit and security purposes

---

## Core Capabilities

- OTP-based authentication workflows
- Secure session management
- Trusted device recognition
- Login attempt tracking
- Fraud signal detection
- Auditable authentication events
- Extensible architecture for integration into larger systems

---

## System Architecture

The service follows Clean Architecture principles to ensure maintainability and scalability.

```
src/
 ├── PinGate.Api
 ├── PinGate.Application
 ├── PinGate.Domain
 ├── PinGate.Infrastructure
 ├── PinGate.Contracts

tests/
 ├── PinGate.UnitTests
 ├── PinGate.IntegrationTests
```

### Architectural Principles

- Separation of concerns across layers
- Domain-driven design
- Dependency inversion
- Clear boundary between domain models and external contracts
- Testability and modular design

---

## High-Level Flow

```
Client
  │
  │  Authentication Request
  ▼
API Layer
  ▼
Application Layer
  ▼
Verification Service
  ▼
Secure Storage / Messaging Layer
  │
  │  Verification Code Delivery
  ▼
Client
  │
  │  Verification Submission
  ▼
Application Layer
  ▼
Session Management
  ▼
Persistent Storage
  ▼
Session Established
```

---

## Core Modules

### Verification Request
Handles initiation of authentication and code generation.

### Verification Processing
Validates submitted verification codes and enforces policy rules.

### Session Management
Manages session lifecycle, including creation, refresh, and termination.

### Device Trust
Tracks recognized devices and supports risk-based authentication decisions.

### Login Monitoring
Records authentication attempts and outcomes.

### Risk and Fraud Signals
Identifies anomalous behavior and triggers protective actions.

---

## API Endpoints

### Authentication

```
POST   /api/auth/request-otp
POST   /api/auth/verify-otp
POST   /api/auth/refresh
POST   /api/auth/logout
```

### Sessions and Devices

```
GET    /api/auth/sessions
POST   /api/auth/trusted-devices
```

### Monitoring

```
GET    /api/auth/login-history
```

---

## Request and Response Examples

### Request Verification Code

POST /api/auth/request-otp

Request:

```json
{
  "identifier": "masked-or-hashed-identifier",
  "contact": "masked-contact"
}
```

Response:

```json
{
  "challengeId": "opaque-challenge-id",
  "expiresInSeconds": 300
}
```

---

### Verify Code

POST /api/auth/verify-otp

Request:

```json
{
  "challengeId": "opaque-challenge-id",
  "verificationCode": "******",
  "deviceInfo": {
    "deviceId": "device-reference",
    "deviceName": "user-device"
  }
}
```

Response:

```json
{
  "accessToken": "opaque-token",
  "expiresIn": 3600
}
```

---

### Refresh Session

POST /api/auth/refresh

Request:

```json
{
  "refreshToken": "opaque-token"
}
```

Response:

```json
{
  "accessToken": "opaque-token",
  "expiresIn": 3600
}
```

---

### Logout

POST /api/auth/logout

Request:

```json
{
  "sessionId": "session-reference"
}
```

Response:

```json
{
  "status": "success"
}
```

---

## Domain Model (Conceptual)

```
CustomerIdentity
OtpChallenge
SessionToken
TrustedDevice
LoginAttempt
FraudFlag
```

Note: Internal structures are abstracted to avoid exposing sensitive implementation details.

---

## Business Rules

- Verification codes expire within a limited time window
- Rate limits are enforced on request and verification attempts
- Accounts may be temporarily restricted after repeated failed attempts
- Unrecognized devices may require additional verification
- Authentication events are recorded for audit purposes

---

## Security Considerations

This system is designed following security-first principles:

- Sensitive data is never stored or transmitted in plain form
- Authentication flows are protected against replay and brute-force attacks
- Rate limiting and throttling are enforced at multiple levels
- All authentication activity is logged for audit and monitoring
- The system is designed to integrate with broader security infrastructure

Implementation details are intentionally abstracted to avoid exposing security-sensitive mechanisms.

---

## Infrastructure Overview

- ASP.NET Core (.NET)
- Relational database for persistence
- In-memory or distributed cache for transient data
- Background processing for cleanup and maintenance tasks
- API documentation via OpenAPI

---

## Background Processing

- Expiration of verification challenges
- Cleanup of inactive sessions
- Monitoring of authentication patterns

---

## Observability

- Structured logging for authentication flows
- Audit trails for compliance and traceability
- Metrics for monitoring system health and usage patterns

---

## Getting Started

```bash
git clone https://github.com/Marothi-Mohale/PinGate-API.git
cd PinGate-API
dotnet restore
dotnet run --project src/PinGate.Api
```

Access API documentation:

```
https://localhost:<port>/swagger
```

---

## Testing

```bash
dotnet test
```

---

## Design Considerations

This system is designed to reflect production-grade authentication services:

- Security-first design approach
- Scalable architecture for high request volumes
- Maintainable and testable codebase
- Alignment with enterprise authentication patterns

---

## Author

Marothi Mohale  
Software Developer (C# / .NET)  
https://github.com/Marothi-Mohale

---


- Ability to apply Clean Architecture in real-world scenarios
