//
//  ParkActivityWidget.swift
//  ParkTimesWidgets
//
//  Lock Screen / Dynamic Island Live Activity showing live waits while
//  the user is in a park.
//

import WidgetKit
import SwiftUI
import ActivityKit

struct ParkActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ParkActivityAttributes.self) { context in
            // Lock Screen banner
            LockScreenActivityView(context: context)
                .activityBackgroundTint(Color(red: 0.05, green: 0.05, blue: 0.12))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.parkName)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.cyan)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.updated, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(context.state.rides.prefix(3)) { ride in
                            HStack {
                                Text(ride.name)
                                    .font(.caption2)
                                    .lineLimit(1)
                                Spacer()
                                Text(waitText(ride))
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(waitColor(ride))
                            }
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.cyan)
            } compactTrailing: {
                if let first = context.state.rides.first, let wait = first.wait, first.isOpen {
                    Text("\(wait)m")
                        .fontWeight(.bold)
                        .foregroundStyle(waitColor(first))
                }
            } minimal: {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.cyan)
            }
        }
    }

    private func waitText(_ ride: ParkActivityAttributes.RideWait) -> String {
        guard ride.isOpen else { return "Closed" }
        if let wait = ride.wait, wait > 0 { return "\(wait)m" }
        return "Walk-on"
    }

    private func waitColor(_ ride: ParkActivityAttributes.RideWait) -> Color {
        guard ride.isOpen else { return .gray }
        let wait = ride.wait ?? 0
        if wait < 30 { return .green }
        if wait < 60 { return .orange }
        return .red
    }
}

struct LockScreenActivityView: View {
    let context: ActivityViewContext<ParkActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .foregroundStyle(.cyan)
                Text(context.attributes.parkName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Spacer()
                if context.isStale {
                    Label("May be out of date", systemImage: "exclamationmark.circle")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange.opacity(0.8))
                } else {
                    Text("Updated \(context.state.updated, style: .time)")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            ForEach(context.state.rides.prefix(4)) { ride in
                HStack {
                    Text(ride.name)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundStyle(.white)
                    Spacer()
                    Text(waitText(ride))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(waitColor(ride))
                }
            }
        }
        .padding(14)
        .opacity(context.isStale ? 0.75 : 1)
    }

    private func waitText(_ ride: ParkActivityAttributes.RideWait) -> String {
        guard ride.isOpen else { return "Closed" }
        if let wait = ride.wait, wait > 0 { return "\(wait)m" }
        return "Walk-on"
    }

    private func waitColor(_ ride: ParkActivityAttributes.RideWait) -> Color {
        guard ride.isOpen else { return .gray }
        let wait = ride.wait ?? 0
        if wait < 30 { return .green }
        if wait < 60 { return .orange }
        return .red
    }
}
