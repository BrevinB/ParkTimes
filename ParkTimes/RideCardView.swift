//
//  RideCardView.swift
//  ParkTimes
//

import SwiftUI

struct RideCardView: View {
    let ride: RideModel

    private var isOpen: Bool {
        ride.isOpen ?? false
    }

    private var statusColor: Color {
        isOpen ? .green : .red
    }

    private var lastUpdatedText: String {
        guard let lastUpdated = ride.lastUpdated else { return "" }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = isoFormatter.date(from: lastUpdated) {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return formatter.localizedString(for: date, relativeTo: Date.now)
        }

        // Fallback: try without fractional seconds
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: lastUpdated) {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return formatter.localizedString(for: date, relativeTo: Date.now)
        }

        return lastUpdated
    }

    private var waitTimeColor: Color {
        let waitTime = ride.waitTime ?? 0
        if waitTime < 30 {
            return .green
        } else if waitTime < 60 {
            return .orange
        } else {
            return .red
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text(ride.name ?? "Unknown Ride")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(isOpen ? "Open" : "Closed")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(statusColor)

                    if !lastUpdatedText.isEmpty {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(lastUpdatedText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if isOpen {
                VStack(spacing: 2) {
                    Text("\(ride.waitTime ?? 0)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(waitTimeColor)
                    Text("min")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 56)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(statusColor.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(statusColor.opacity(0.15), lineWidth: 1)
                )
        )
    }
}
