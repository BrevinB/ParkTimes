//
//  ParkCardView.swift
//  ParkTimes
//

import SwiftUI

struct ParkCardView: View {
    let park: ParkModel

    private var iconImage: String {
        switch park.id {
        case 5: return "EpcotImg"
        case 6: return "MagicKingdomImg"
        case 7: return "HollywoodStudiosImg"
        case 8: return "AnimalKingdomImg"
        case 64: return "IslandOfAdventureImg"
        case 65: return "UniversalStudiosImg"
        default: return "MagicKingdomImg"
        }
    }

    private var accentColor: Color {
        switch park.id {
        case 5: return .purple
        case 6: return .blue
        case 7: return .red
        case 8: return .green
        case 64, 65: return .orange
        default: return .blue
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(iconImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(park.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text("View wait times")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: accentColor.opacity(0.15), radius: 8, y: 4)
        )
    }
}
