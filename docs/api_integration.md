# API Integration Documentation

## Overview
This document describes the DukaApp Flutter mobile app integration with the live DukaApp backend API for authentication, session management, and the API foundation layer.

---

## API Base Configuration

| Item | Value |
|------|-------|
| Base URL | `https://dukaapp.net` |
| App API Base | `/api/v1/app` |
| Full Base | `https://dukaapp.net/api/v1/app/` |

Configured centrally in `lib/core/config/api_config.dart` via `ApiConfig.baseUrl` and `ApiConfig.appApiBase`.

---

## Authentication Endpoints

### Sign In
```
POST /api/v1/app/auth/signin
```
**Parameters:**
- `username` (or `email` or `phone`)
- `password`

**Response:** JWT token + user/session data

### Register
```
POST /api/v1/app/auth/register
```
**Parameters:**
- `username`, `email`, `phone`, `password`
- `country`, `iso`, `region`
- `shop_name`, `shop_type`, `lob_id`

### Password Reset
```
POST /api/v1/app/auth/reset/send
```
**Parameters:**
- `username` OR `phone` OR `email`

### Sign Out
```
GET /api/v1/app/auth/signout
```
Authenticated endpoint.

### Add Shop
```
POST /api/v1/app/auth/addshop
```
Authenticated. Parameters: `shop_name`, `shop_type`, `lob_id`

### Switch Shop
```
POST /api/v1/app/auth/switchshop/{shop_id}
```
Authenticated. Parameter: `shop_id`

### Auth Constants
```
GET /api/v1/app/auth/constants
```
Public endpoint. Returns business categories, shop types, etc.

---

## Request Models

### Login Request
```json
{
  "username": "identifier",
  "email": "identifier",
  "phone": "identifier",
  "password": "secret"
}
```

### Register Request
```json
{
  "username": "john",
  "email": "john@example.com",
  "phone": "+254712345678",
  "password": "secret",
  "country": "Kenya",
  "iso": "+254",
  "region": "Nairobi",
  "shop_name": "My Shop",
  "shop_type": "retail",
  "lob_id": 1
}
```

---

## Response Models

### AuthResult
```dart
class AuthResult {
  final bool success;
  final String? message;
  final String? token;
  final User? user;
  final Shop? shop;
  final List<Shop>? shops;
}
```

### User
```dart
class User {
  final dynamic id;
  final String? username;
  final String? email;
  final String? phone;
  final String? country;
  final String? region;
  final String? iso;
  final String? role;
  final String? avatar;
}
```

### Shop
```dart
class Shop {
  final dynamic id;
  final String? shopName;
  final String? shopType;
  final dynamic lobId;
  final String? lobName;
  final bool? isActive;
}
```

---

## Token Storage

- JWT stored via `flutter_secure_storage`
- Key: `access_token`
- Never stored in SharedPreferences or plain text
- Never logged or printed

---

## Cache Strategy

| Data | Storage | TTL | Invalidation |
|------|---------|-----|-------------|
| Auth Token | Secure Storage | Until logout | signOut() |
| User Session | Secure Storage | Until logout | signOut() |
| Active Shop | Secure Storage | Until shop switch | switchShop() |
| Permissions | Secure Storage | Until shop/user change | signOut() |
| Auth Constants | LocalStorage (SharedPreferences) | 24 hours | Never auto-invalidated |

---

## Session Restoration

On app start:
1. Check SecureStorage for `access_token`
2. If no token → show Login
3. If token exists → call `GET /api/v1/app/get/getdata/session_user`
4. If API call succeeds → restore session → show Dashboard
5. If API call fails → use cached user data if available → show Dashboard
6. If no cached data → clear token → show Login

---

## Error Handling

All errors are caught at the repository layer and converted to user-friendly messages:
- Network unavailable → "Unable to connect to DukaApp..."
- Timeout → "Connection timed out..."
- 401 Unauthorized → "Your session has expired..."
- Server errors → "A server error occurred..."

Raw exceptions are never displayed to the user.

---

## 401 Handling

Centralized via `_ErrorInterceptor` in ApiClient:
1. Detects HTTP 401 responses
2. Clears secure token
3. Clears user-specific cached data
4. Redirects to Login screen
5. Prevents retry loops

---

## Architecture

```
LoginPage
  ↓
AuthController (Riverpod StateNotifier)
  ↓
AuthRepository
  ↓
AuthRemoteDatasource
  ↓
ApiClient (Dio)
  ↓
DukaApp API
```

---

## Dependencies Added

| Package | Version | Purpose |
|---------|---------|---------|
| dio | ^5.7.0 | HTTP client |
| internet_connection_checker_plus | ^2.7.3 | Network connectivity |
| flutter_secure_storage | ^9.2.4 | Secure token storage |
| shared_preferences | ^2.3.4 | Local cache for non-sensitive data |

---

## Future Integration Plan

After authentication is fully tested:
1. Dashboard API integration
2. Stock management
3. Sales
4. Purchases
5. Customers
6. Staff
7. Reports
8. Microfinance
9. Manufacturing
10. Online Shop

All future modules will reuse the same `ApiClient`, `SecureStorageService`, and `CacheManager` infrastructure.
