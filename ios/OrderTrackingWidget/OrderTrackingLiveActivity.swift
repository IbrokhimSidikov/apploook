import ActivityKit
import SwiftUI
import WidgetKit

// LOOOK brand yellow.
private let brand = Color(red: 0.996, green: 0.757, blue: 0.016)

@available(iOS 16.1, *)
struct OrderTrackingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: OrderActivityAttributes.self) { context in
            // MARK: Lock Screen / Banner
            LockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            // MARK: Dynamic Island (expanded)
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: iconName(for: context.state.statusKey))
                        .foregroundColor(brand)
                        .font(.title2)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.etaMinutes > 0 {
                        VStack(alignment: .trailing) {
                            Text("\(context.state.etaMinutes) min")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("ETA").font(.caption2).foregroundColor(.gray)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.statusText)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressBar(step: context.state.stepIndex)
                        .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: iconName(for: context.state.statusKey))
                    .foregroundColor(brand)
            } compactTrailing: {
                if context.state.etaMinutes > 0 {
                    Text("\(context.state.etaMinutes)m").foregroundColor(.white)
                }
            } minimal: {
                Image(systemName: iconName(for: context.state.statusKey))
                    .foregroundColor(brand)
            }
            .keylineTint(brand)
        }
    }
}

// MARK: - Lock Screen view

@available(iOS 16.1, *)
private struct LockScreenView: View {
    let context: ActivityViewContext<OrderActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconName(for: context.state.statusKey))
                    .foregroundColor(brand)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.statusText)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(context.attributes.branchName)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                if context.state.etaMinutes > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(context.state.etaMinutes)")
                            .font(.title2).bold()
                            .foregroundColor(brand)
                        Text("min").font(.caption2).foregroundColor(.gray)
                    }
                }
            }
            ProgressBar(step: context.state.stepIndex)
        }
        .padding()
    }
}

// MARK: - 4-step progress bar

@available(iOS 16.1, *)
private struct ProgressBar: View {
    let step: Int // 0...3
    private let labels = ["Confirmed", "Preparing", "On the way", "Delivered"]

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                ForEach(0..<4) { i in
                    Capsule()
                        .fill(i <= step ? brand : Color.gray.opacity(0.4))
                        .frame(height: 4)
                }
            }
            HStack {
                ForEach(0..<4) { i in
                    Text(labels[i])
                        .font(.system(size: 9))
                        .foregroundColor(i <= step ? .white : .gray)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Status -> SF Symbol

private func iconName(for statusKey: String) -> String {
    switch statusKey {
    case "confirmed":  return "checkmark.seal.fill"
    case "preparing":  return "frying.pan.fill"
    case "onTheWay":   return "bicycle"
    case "delivered":  return "bag.fill.badge.checkmark"
    case "cancelled":  return "xmark.circle.fill"
    default:           return "bag.fill"
    }
}
