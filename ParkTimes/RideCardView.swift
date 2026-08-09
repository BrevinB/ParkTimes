//
//  RideCardView.swift
//  ParkTimes
//

import SwiftUI

struct RideCardView: View {
    let ride: LiveEntity
    var timezone: TimeZone? = nil

    @EnvironmentObject private var favoritesStore: FavoritesStore

    private var statusColor: Color {
        if ride.isRefurbishment { return .yellow }
        if ride.isDown { return .orange }
        return ride.isOpen ? .green : .red
    }

    private var lastUpdatedText: String {
        guard let date = ride.lastUpdatedDate else { return "" }
        return PTFormat.relative.localizedString(for: date, relativeTo: Date.now)
    }

    private enum ShowState {
        case upcoming(Date)
        case doneForToday
        case none
    }

    private var showState: ShowState {
        guard let showtimes = ride.showtimes, !showtimes.isEmpty else { return .none }
        if let next = ride.nextShowtime() { return .upcoming(next) }
        return .doneForToday
    }

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(statusColor.gradient)
                .frame(width: 4)
                .padding(.vertical, 8)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        if favoritesStore.isFavorite(ride.id) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.yellow)
                        }
                        Text(ride.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    HStack(spacing: 6) {
                        if let llPrice = ride.lightningLanePrice {
                            HStack(spacing: 2) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 8))
                                Text(llPrice)
                                    .font(.caption2)
                            }
                            .foregroundStyle(.yellow)
                        }

                        if ride.lightningLanePrice != nil && !lastUpdatedText.isEmpty {
                            Text("·")
                                .font(.caption2)
                                .foregroundStyle(.secondary.opacity(0.5))
                        }

                        if !lastUpdatedText.isEmpty {
                            Text(lastUpdatedText)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                trailingBadge
            }
            .padding(.leading, 12)
            .padding(.trailing, 14)
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.cardBackground)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder
    private var trailingBadge: some View {
        if ride.isShow {
            switch showState {
            case .upcoming(let next):
                badge(PTFormat.time(next, in: timezone), color: .purple, prominent: false, textColor: .purple)
            case .doneForToday:
                badge("Done today", color: .secondary, prominent: false, textColor: .secondary)
            case .none:
                if !ride.isOpen {
                    badge("Closed", color: .secondary, prominent: false, textColor: .secondary)
                }
            }
        } else if ride.isOpen {
            if let wait = ride.waitTime, wait > 0 {
                Text("\(wait) min")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.forWait(wait).gradient))
            } else {
                HStack(spacing: 3) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 9))
                    Text("Walk-on")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundStyle(.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(.green.opacity(0.15)))
            }
        } else if ride.isDown {
            badge("Down", color: .orange, prominent: false, textColor: .orange)
        } else if ride.isRefurbishment {
            badge("Rehab", color: .yellow, prominent: false, textColor: .yellow.opacity(0.9))
        } else {
            badge("Closed", color: .secondary, prominent: false, textColor: .secondary)
        }
    }

    private func badge(_ text: String, color: Color, prominent: Bool, textColor: Color) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(color.opacity(0.12)))
    }

    private var accessibilityText: String {
        var parts: [String] = [ride.name]
        if favoritesStore.isFavorite(ride.id) { parts.append("favorite") }

        if ride.isShow {
            switch showState {
            case .upcoming(let next): parts.append("next show at \(PTFormat.time(next, in: timezone))")
            case .doneForToday: parts.append("done for today")
            case .none: parts.append(ride.isOpen ? "open" : "closed")
            }
        } else if ride.isOpen {
            if let wait = ride.waitTime, wait > 0 {
                parts.append("open, \(wait) minute wait")
            } else {
                parts.append("open, walk on")
            }
        } else if ride.isDown {
            parts.append("temporarily down")
        } else if ride.isRefurbishment {
            parts.append("closed for refurbishment")
        } else {
            parts.append("closed")
        }

        if let llPrice = ride.lightningLanePrice {
            parts.append("Lightning Lane \(llPrice)")
        }
        return parts.joined(separator: ", ")
    }
}
