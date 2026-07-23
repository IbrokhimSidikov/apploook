import ActivityKit
import Foundation

// Native bridge that owns the ActivityKit lifecycle. Driven from Dart through
// the MethodChannel registered in AppDelegate.
//
// Local updates (app foreground/background) flow through update(). Updates while
// the phone is LOCKED and the app is killed must come via push — for that we
// expose the per-activity push token through `onPushToken`, which AppDelegate
// forwards to Dart so it can be registered with OneSignal.
@available(iOS 16.2, *)
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    // Called whenever ActivityKit issues/refreshes a push token for an activity.
    // (activityId, hexToken)
    var onPushToken: ((String, String) -> Void)?

    private var activities: [String: Activity<OrderActivityAttributes>] = [:]

    func areActivitiesEnabled() -> Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    @discardableResult
    func start(orderId: String,
               branchName: String,
               state: OrderActivityAttributes.ContentState) throws -> String {
        let attributes = OrderActivityAttributes(orderId: orderId, branchName: branchName)
        let content = ActivityContent(state: state, staleDate: nil)

        // pushType: .token makes the activity push-updatable (required for OneSignal).
        let activity = try Activity.request(
            attributes: attributes,
            content: content,
            pushType: .token
        )
        activities[activity.id] = activity
        observePushToken(for: activity)
        return activity.id
    }

    func update(id: String, state: OrderActivityAttributes.ContentState) async {
        guard let activity = activity(for: id) else { return }
        await activity.update(ActivityContent(state: state, staleDate: nil))
    }

    func end(id: String, finalState: OrderActivityAttributes.ContentState?) async {
        guard let activity = activity(for: id) else { return }
        let content = finalState.map { ActivityContent(state: $0, staleDate: nil) }
        // .default keeps the card briefly on the Lock Screen, then it dismisses.
        await activity.end(content, dismissalPolicy: .default)
        activities[id] = nil
    }

    func endAll() async {
        for activity in Activity<OrderActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        activities.removeAll()
    }

    // MARK: - Helpers

    private func activity(for id: String) -> Activity<OrderActivityAttributes>? {
        activities[id] ?? Activity<OrderActivityAttributes>.activities.first { $0.id == id }
    }

    private func observePushToken(for activity: Activity<OrderActivityAttributes>) {
        Task {
            for await tokenData in activity.pushTokenUpdates {
                let token = tokenData.map { String(format: "%02x", $0) }.joined()
                self.onPushToken?(activity.id, token)
            }
        }
    }
}
