# Live Activity — Order Tracker (iOS) Setup

A Lock Screen / Dynamic Island card that shows live order status in 4 steps:
**Confirmed → Preparing → On the way → Delivered** (`cancelled` ends the card).

The code is scaffolded. The steps below are the ones that **must** be done in
Xcode / dashboards and can't be scripted.

---

## What's already in the repo

| Layer | File |
|---|---|
| Activity data model (typed) | `ios/Shared/OrderActivityAttributes.swift` |
| Native ActivityKit control | `ios/Runner/LiveActivityManager.swift` |
| MethodChannel registration | `ios/Runner/AppDelegate.swift` |
| Lock Screen + Dynamic Island UI | `ios/OrderTrackingWidget/OrderTrackingLiveActivity.swift` |
| Widget bundle entry | `ios/OrderTrackingWidget/OrderTrackingWidgetBundle.swift` |
| Widget Info.plist + entitlements | `ios/OrderTrackingWidget/` |
| Dart control + status mapping | `lib/services/live_activity_service.dart` |
| Start call | `lib/pages/checkout.dart` (after order placed) |
| Update/end call | `lib/services/order_tracking_service.dart` (on poll) |
| `NSSupportsLiveActivities` | `ios/Runner/Info.plist` |
| App Group entitlement | `ios/Runner/Runner.entitlements` |

App Group used everywhere: **`group.com.loook.v1.liveactivity`**
MethodChannel name: **`com.loook.apploook/live_activity`**

---

## Step 1 — Create the Widget Extension target (Xcode, required)

1. `open ios/Runner.xcworkspace`
2. **File ▸ New ▸ Target… ▸ Widget Extension**
   - Product Name: **`OrderTrackingWidget`**  ← must match the folder name
   - ✅ **Include Live Activity**
   - Uncheck "Include Configuration App Intent"
   - Embed in: **Runner**
3. When prompted "Activate scheme?" → **Cancel** (keep Runner scheme).
4. Xcode generates placeholder files inside a new group. **Delete** the
   auto-generated `.swift` files (move to trash) and instead **add the existing
   files** from `ios/OrderTrackingWidget/`:
   - Right-click the `OrderTrackingWidget` group ▸ **Add Files to "Runner"…**
   - Select `OrderTrackingLiveActivity.swift` and `OrderTrackingWidgetBundle.swift`
   - Target membership: **OrderTrackingWidget only**
5. Set the target's **Info.plist** to `ios/OrderTrackingWidget/Info.plist`
   (target ▸ Build Settings ▸ *Info.plist File*).
6. Set **iOS Deployment Target = 16.2** on the widget target. (The native
   control uses iOS 16.2+ ActivityKit APIs — `ActivityContent` /
   `pushTokenUpdates`. Below 16.2 the feature is a safe no-op.)

## Step 2 — Share the attributes file with BOTH targets

1. Add `ios/Shared/OrderActivityAttributes.swift` to the project if not present.
2. Select it ▸ File Inspector ▸ **Target Membership** ▸ check **Runner** AND
   **OrderTrackingWidget**. (Both targets compile this same struct — that's how
   start/update and rendering stay in sync.)

## Step 3 — App Group capability (both targets)

For **Runner** and **OrderTrackingWidget**:
- Signing & Capabilities ▸ **+ Capability ▸ App Groups**
- Add **`group.com.loook.v1.liveactivity`** (already in the entitlements files).
- For the widget target, point *Code Signing Entitlements* at
  `ios/OrderTrackingWidget/OrderTrackingWidget.entitlements`.

## Step 4 — Build & test LOCAL updates (works now, no backend)

```bash
flutter run --release   # Live Activities don't show in debug reliably; use a real device
```

- Place an order → a card appears on the Lock Screen + Dynamic Island.
- While the app is open/backgrounded, the status poller
  (`OrderTrackingService.updateOrderStatus`) advances the card automatically.
- `delivered`/`cancelled` ends it.

> Local updates only fire while the app is alive. For updates while the phone is
> **locked and the app is killed**, do Step 5.

---

## Step 5 — Push updates while locked (OneSignal)

OneSignal is **not yet installed** in this project (only a leftover
`OneSignalNotificationServiceExtension` folder exists). FCM cannot deliver Live
Activity pushes, so use OneSignal (or direct APNs).

### 5a. Install the SDK
```yaml
# pubspec.yaml
dependencies:
  onesignal_flutter: ^5.2.0
```
```bash
flutter pub get && cd ios && pod install
```

### 5b. Initialize OneSignal (in `lib/main.dart`, after Firebase init)
```dart
OneSignal.initialize('YOUR_ONESIGNAL_APP_ID');
OneSignal.Notifications.requestPermission(true);
```

### 5c. Register the activity push token with OneSignal
The native side already streams the per-activity push token to Dart via the
`onPushToken` callback. Wire it once at startup:
```dart
LiveActivityService.instance.onPushToken = (activityId, token) {
  // Associates this Live Activity with OneSignal so it can be pushed.
  OneSignal.LiveActivities.enterLiveActivity(activityId, token);
};
```

### 5d. Backend: send an update
Call the OneSignal REST API when your order status changes. The
`event_updates` keys MUST match `OrderActivityAttributes.ContentState`:
```jsonc
POST https://api.onesignal.com/apps/{APP_ID}/activities/activity/{ACTIVITY_ID}/notifications
Authorization: Key {REST_API_KEY}
{
  "event": "update",
  "event_updates": {
    "statusKey": "onTheWay",
    "statusText": "On the way",
    "stepIndex": 2,
    "etaMinutes": 12
  },
  "name": "order_update"
}
```
Use `"event": "end"` to dismiss the card.

> The `{ACTIVITY_ID}` is the value returned by `startActivity` (persisted in
> SharedPreferences under `live_activity_ids` and passed to OneSignal in 5c).
> Send it to your backend when the order is created so it knows which activity
> to push.

### Alternative: direct APNs
Skip OneSignal and have your server send an APNs request with header
`apns-push-type: liveactivity`, topic `com.loook.v1.push-type.liveactivity`,
and an `aps.content-state` matching the same 4 fields. You manage the push token
(forwarded via `onPushToken`) yourself.

---

## 4-step status mapping (single source of truth)

`LiveActivityService.mapStatus()` in Dart mirrors the existing
`api_order_tracking_card._getStatusText` mapping:

| Delever status | step | statusKey |
|---|---|---|
| new, open, pending, accepted, confirmed | 0 | `confirmed` |
| cooking, preparing, production, book(ed) | 1 | `preparing` |
| ready, on_the_way, delivering, go, finish | 2 | `onTheWay` |
| delivered, completed, closed | 3 | `delivered` (ends) |
| cancel(led) | — | `cancelled` (ends) |

---

## Troubleshooting

- **Card never appears**: real device only; Settings ▸ Face ID & Passcode ▸
  allow Live Activities; Settings ▸ [App] ▸ Live Activities ON.
- **`areActivitiesEnabled` false**: user disabled them in Settings.
- **Build error "OrderActivityAttributes not found"**: target membership
  (Step 2) not checked for that target.
- **Push update does nothing**: `event_updates` keys must exactly match the
  ContentState fields; activity must have been started with `pushType: .token`
  (it is) and its token registered (5c).
