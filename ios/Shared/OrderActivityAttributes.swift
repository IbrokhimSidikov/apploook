import ActivityKit
import Foundation

// IMPORTANT: This file must belong to BOTH targets:
//   - Runner            (so LiveActivityManager can start/update activities)
//   - OrderTrackingWidget (so the SwiftUI widget can render them)
// In Xcode, select this file -> File Inspector -> Target Membership -> check both.

@available(iOS 16.1, *)
struct OrderActivityAttributes: ActivityAttributes {
    // Dynamic data that changes over the life of the order.
    // The keys here MUST match the `content-state` JSON your backend sends
    // through OneSignal / APNs for push updates while the phone is locked.
    public struct ContentState: Codable, Hashable {
        var statusKey: String   // "confirmed" | "preparing" | "onTheWay" | "delivered" | "cancelled"
        var statusText: String  // human-readable label, e.g. "On the way"
        var stepIndex: Int      // 0...3 for the progress bar
        var etaMinutes: Int     // estimated minutes remaining (0 = unknown / arrived)
    }

    // Static data, set once when the activity starts.
    var orderId: String
    var branchName: String
}
