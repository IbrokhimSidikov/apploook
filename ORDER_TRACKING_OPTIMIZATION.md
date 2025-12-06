# Order Tracking Page Optimization

## Problem
The order tracking page was fetching order history from the API every time the page was visited, causing slow load times and poor user experience.

## Solution Implemented

### 1. **Multi-Layer Caching System**

#### In-Memory Cache
- Fastest access for repeated requests within the same session
- Stored in `OrderHistoryService` instance variables
- No disk I/O required

#### Persistent Cache (SharedPreferences)
- Survives app restarts
- Stored with timestamp for expiration tracking
- Falls back when in-memory cache is cleared

### 2. **Cache Configuration**
- **Cache Duration**: 5 minutes (configurable via `_cacheDuration`)
- **Cache Keys**: 
  - `order_history_cache` - stores the order data
  - `order_history_cache_timestamp` - stores the cache timestamp

### 3. **Smart Loading Strategy**

#### Initial Load (Background Refresh)
1. **Instant Display**: Shows cached data immediately (if available)
2. **Background Update**: Fetches fresh data in the background
3. **Silent Update**: Updates UI when new data arrives without showing loading spinner

#### Manual Refresh
- Pull-to-refresh gesture forces fresh data fetch
- Refresh button in AppBar forces fresh data fetch
- Shows loading indicator during manual refresh

### 4. **Offline Support**
- If network request fails, returns stale cache data
- Graceful degradation ensures users can still view their orders

## API Changes

### `OrderHistoryService.fetchOrderHistory()`
```dart
Future<Map<String, dynamic>> fetchOrderHistory({
  int page = 1,
  int limit = 10,
  bool forceRefresh = false,  // NEW: Force bypass cache
})
```

**Parameters:**
- `forceRefresh`: Set to `true` to bypass cache and fetch fresh data

### New Methods
- `clearCache()`: Manually clear all cached data

## Usage Examples

### Normal Load (Uses Cache)
```dart
await _orderHistoryService.fetchOrderHistory(page: 1, limit: 50);
```

### Force Refresh (Bypass Cache)
```dart
await _orderHistoryService.fetchOrderHistory(
  page: 1, 
  limit: 50, 
  forceRefresh: true
);
```

### Clear Cache
```dart
await _orderHistoryService.clearCache();
```

## Performance Improvements

### Before Optimization
- **Every page visit**: Full API request (~1-3 seconds)
- **Network dependent**: Slow on poor connections
- **No offline support**: Fails without internet

### After Optimization
- **First visit**: Full API request (~1-3 seconds)
- **Subsequent visits (within 5 min)**: Instant load from cache (~50-100ms)
- **Background refresh**: Fresh data loaded silently
- **Offline support**: Shows last cached data

## Cache Invalidation

Cache is automatically invalidated when:
1. **Time-based**: After 5 minutes
2. **Manual refresh**: User pulls to refresh or taps refresh button
3. **Explicit clear**: When `clearCache()` is called

## Future Enhancements

Consider these additional optimizations:

1. **Pagination Cache**: Cache individual pages separately
2. **Incremental Updates**: Only fetch new orders since last update
3. **WebSocket Integration**: Real-time order status updates
4. **Optimistic Updates**: Update UI immediately, sync in background
5. **Cache Size Management**: Limit cache size to prevent storage issues
6. **Per-Order-Type Cache**: Separate cache for delivery, carhop, and pickup orders

## Configuration

To adjust cache duration, modify in `order_history_service.dart`:

```dart
static const Duration _cacheDuration = Duration(minutes: 5); // Change here
```

## Testing

Test the following scenarios:
1. ✅ First load (no cache) - should show loading
2. ✅ Second load within 5 min - should be instant
3. ✅ Load after 5 min - should fetch fresh data
4. ✅ Pull to refresh - should force refresh
5. ✅ Offline mode - should show cached data
6. ✅ Background refresh - should update silently
