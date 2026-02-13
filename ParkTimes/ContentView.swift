//
//  ContentView.swift
//  ParkTimes
//
//  Created by Brevin Blalock on 8/28/23.
//

import SwiftUI

struct ContentView: View {

    @State private var parks: [ParkModel] = []
    @State private var loading = false
    @State private var errorMessage: String?

    private let disneyParkIds = [6, 5, 7, 8]
    private let universalParkIds = [64, 65]

    var disneyParks: [ParkModel] {
        parks.filter { disneyParkIds.contains($0.id) }
    }

    var universalParks: [ParkModel] {
        parks.filter { universalParkIds.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if loading {
                    ProgressView("Loading parks...")
                        .progressViewStyle(.circular)
                } else if let errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text(errorMessage)
                            .foregroundStyle(.secondary)
                        Button("Try Again") {
                            Task { await loadParks() }
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            if !disneyParks.isEmpty {
                                ParkSection(title: "Walt Disney World", parks: disneyParks)
                            }
                            if !universalParks.isEmpty {
                                ParkSection(title: "Universal Orlando", parks: universalParks)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Park Times")
            .task {
                if parks.isEmpty {
                    await loadParks()
                }
            }
        }
    }

    private func loadParks() async {
        loading = true
        errorMessage = nil

        let allIds = disneyParkIds + universalParkIds
        var loadedParks: [ParkModel] = []

        do {
            for id in allIds {
                let park = try await ParkService.getPark(parkId: id)
                loadedParks.append(park)
            }
            parks = loadedParks
        } catch {
            errorMessage = "Unable to load parks. Check your connection."
        }

        loading = false
    }
}

struct ParkSection: View {
    let title: String
    let parks: [ParkModel]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            ForEach(parks) { park in
                NavigationLink {
                    RidesView(parkId: park.id, parkName: park.name)
                } label: {
                    ParkCardView(park: park)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
