//
//  RidesView.swift
//  ParkTimes
//

import SwiftUI

struct RidesView: View {
    @State private var attractions: [LiveEntity] = []
    @State private var loading = false
    @State private var errorMessage: String?
    let parkId: String
    let parkName: String

    private var openAttractions: [LiveEntity] {
        attractions
            .filter { $0.isOpen }
            .sorted { ($0.waitTime ?? 0) > ($1.waitTime ?? 0) }
    }

    private var closedAttractions: [LiveEntity] {
        attractions
            .filter { !$0.isOpen }
            .sorted { $0.name < $1.name }
    }

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
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        if !openAttractions.isEmpty {
                            AttractionSectionView(
                                title: "Open",
                                count: openAttractions.count,
                                total: attractions.count,
                                attractions: openAttractions
                            )
                        }
                        if !closedAttractions.isEmpty {
                            AttractionSectionView(
                                title: "Closed",
                                count: closedAttractions.count,
                                total: attractions.count,
                                attractions: closedAttractions,
                                startExpanded: false
                            )
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
            let liveData = try await ParkService.getLiveData(parkId: parkId)
            attractions = liveData.filter { $0.isAttraction }
        } catch {
            errorMessage = "Unable to load rides. Check your connection."
        }

        loading = false
    }
}
