//
//  AttractionSectionView.swift
//  ParkTimes
//

import SwiftUI

struct AttractionSectionView: View {
    let title: String
    let count: Int
    let total: Int
    let attractions: [LiveEntity]
    var startExpanded: Bool = true

    @State private var isExpanded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        Text("\(count)/\(total) attractions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                }
                .padding(.horizontal, 4)
            }

            if isExpanded {
                ForEach(attractions) { ride in
                    RideCardView(ride: ride)
                }
            }
        }
        .onAppear {
            isExpanded = startExpanded
        }
    }
}
