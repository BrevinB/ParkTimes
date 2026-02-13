//
//  RidesView.swift
//  ParkTimes
//

import SwiftUI

struct RidesView: View {
    @State private var results: LandsAndRides?
    @State private var loading = false
    @State private var errorMessage: String?
    let parkId: Int
    let parkName: String

    var body: some View {
        Group {
            if loading {
                ProgressView("Loading rides...")
                    .progressViewStyle(.circular)
            } else if let errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(errorMessage)
                        .foregroundStyle(.secondary)
                    Button("Try Again") {
                        Task { await loadRides() }
                    }
                    .buttonStyle(.bordered)
                }
            } else if let results {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(results.lands) { land in
                            LandSectionView(land: land)
                        }
                    }
                    .padding()
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle(parkName)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadRides()
        }
    }

    private func loadRides() async {
        loading = true
        errorMessage = nil

        do {
            results = try await ParkService.getRides(parkId: parkId)
        } catch {
            errorMessage = "Unable to load rides. Check your connection."
        }

        loading = false
    }
}
