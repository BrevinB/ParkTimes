//
//  LandSectionView.swift
//  ParkTimes
//

import SwiftUI

struct LandSectionView: View {
    let land: LandModel
    @State private var isExpanded = true

    private var rideCount: Int {
        land.rides?.count ?? 0
    }

    private var openCount: Int {
        land.rides?.filter { $0.isOpen == true }.count ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(land.name ?? "Unknown Land")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        Text("\(openCount)/\(rideCount) open")
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
                ForEach(land.rides ?? []) { ride in
                    RideCardView(ride: ride)
                }
            }
        }
    }
}
