# Cache Strategy Documentation

## Overview
This document describes the caching strategy used in the DukaApp Flutter mobile application.

---

## Cache Layers

### 1. Secure Storage (`flutter_secure_storage`)
**Purpose:** Sensitive data that must persist across app restarts.

| Key | Content | TTL | Invalidation |
|-----|---------|-----|-------------|
| `access_token` | JWT token | Until logout | `signOut()` |
| `refresh_token` | Refresh token (if provided) | Until logout | `signOut()` |
| `session_data` | Session metadata | Until logout | `signOut()` |
| `user_data` | Current user profile | Until logout | `signOut()` |
| `active_shop_data` | Active shop info | Until shop switch | `switchShop()` or `signOut()` |
| `permissions_data` | User permissions | Until shop/user change | `signOut()` |

**Rules:**
- Never logged or printed
- Never stored in SharedPreferences
- Cleared on sign out
- Cleared on 401 unauthorized

---

### 2. Local Cache (`shared_preferences`)
**Purpose:** Non-sensitive data with TTL-based expiration.

| Key | Content | TTL | Invalidation |
|-----|---------|-----|-------------|
| `auth_constants` | Business categories, shop types | 24 hours | Auto-expired |
| `_cache_timestamp_<key>` | Cache timestamp for TTL checks | Matches key TTL | Removed with key |

**Rules:**
- Used for slow-changing reference data
- TTL-based expiration
- Force refresh available via `forceRefresh` parameter

---

## Cache Manager

The `CacheManager` class provides:
- **Request de-duplication**: Prevents duplicate simultaneous API calls
- **TTL-based expiration**: Automatic cache invalidation
- **Force refresh**: Override cache and fetch fresh data

```dart
final result = await cacheManager.get(
  key: 'session_user',
  fetcher: () => apiClient.get('/get/getdata/session_user'),
  ttl: const Duration(minutes: 5),
  forceRefresh: false,
);
```

---

## Data Categories

### A. Session Data (Very Short-lived)
- User profile
- Active shop
- Permissions
- Refresh after login/shop switch

### B. Static / Slow-Changing Data (Long Cache)
- Business categories (auth/constants)
- Shop types
- Regions
- TTL: 24 hours

### C. Dynamic Business Data (Short TTL)
- Dashboard data
- Stock levels
- Sales data
- Orders
- TTL: 5-15 minutes

### D. Write Operations
- Never treat local cache as confirmation
- Writes must be confirmed by the API
- Cache updated only after successful API response

---

## Request De-duplication

When multiple widgets request the same data simultaneously:

```
Request 1 → API (single network call)
Request 2 → waits for Request 1
Both receive the same result
```

Implemented in `CacheManager` using `Completer` pattern.

---

## Rules

1. **DO NOT** cache authentication tokens in normal cache
2. **DO NOT** cache write operation results permanently
3. **DO** use TTL for all non-sensitive cached data
4. **DO** clear user-specific cache on sign out
5. **DO** preserve app-wide static cache (like constants) unless necessary
6. **DO NOT** call API unnecessarily - use cache when valid
7. **DO** distinguish between cached session and fresh server data
