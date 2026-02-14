//
//  ParkCardView.swift
//  ParkTimes
//

import SwiftUI

struct ParkCardView: View {
    let park: ParkModel

    private var iconImage: String {
        switch park.id {
        case "47f90d2c-e191-4239-a466-5892ef59a88b": return "EpcotImg"
        case "75ea578a-adc8-4116-a54d-dccb60765ef9": return "MagicKingdomImg"
        case "288747d1-8b4f-4a64-867e-ea7c9b27bad8": return "HollywoodStudiosImg"
        case "1c84a229-8862-4648-9c71-378ddd2c7693": return "AnimalKingdomImg"
        case "267615cc-8943-4c2a-ae2c-5da728ca591f": return "IslandOfAdventureImg"
        case "eb3f4560-2383-4a36-9152-6b3e5ed6bc57": return "UniversalStudiosImg"
        case "12dbb85b-265f-44e6-bccf-f1faa17211fc": return "UniversalStudiosImg"
        default: return "MagicKingdomImg"
        }
    }

    private var accentColor: Color {
        switch park.id {
        case "47f90d2c-e191-4239-a466-5892ef59a88b": return .purple
        case "75ea578a-adc8-4116-a54d-dccb60765ef9": return .blue
        case "288747d1-8b4f-4a64-867e-ea7c9b27bad8": return .red
        case "1c84a229-8862-4648-9c71-378ddd2c7693": return .green
        case "267615cc-8943-4c2a-ae2c-5da728ca591f",
             "eb3f4560-2383-4a36-9152-6b3e5ed6bc57",
             "12dbb85b-265f-44e6-bccf-f1faa17211fc": return .orange
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
