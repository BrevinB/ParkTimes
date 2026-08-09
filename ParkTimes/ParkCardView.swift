//
//  ParkCardView.swift
//  ParkTimes
//

import SwiftUI

struct ParkCardView: View {
    let park: ParkModel
    var summary: ParkLiveSummary? = nil

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: park.style.colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: park.style.icon)
                .font(.system(size: 90, weight: .thin))
                .foregroundStyle(.white.opacity(0.12))
                .rotationEffect(.degrees(-10))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .offset(x: -16, y: 8)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(park.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text(park.subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))

                    if let summary {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(summary.openCount > 0 ? .green : .red)
                                .frame(width: 6, height: 6)
                            Text(liveText(summary))
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.black.opacity(0.25)))
                        .padding(.top, 2)
                    }
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(18)
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: (park.style.colors.first ?? .blue).opacity(0.4), radius: 12, y: 6)
        .padding(.horizontal)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private func liveText(_ summary: ParkLiveSummary) -> String {
        guard summary.openCount > 0 else { return "Closed" }
        if summary.avgWait > 0 {
            return "\(summary.openCount) open · avg \(summary.avgWait)m"
        }
        return "\(summary.openCount) open"
    }

    private var accessibilityText: String {
        var text = "\(park.name). \(park.subtitle)."
        if let summary {
            text += summary.openCount > 0
                ? " \(summary.openCount) attractions open, average wait \(summary.avgWait) minutes."
                : " Currently closed."
        }
        return text
    }
}
