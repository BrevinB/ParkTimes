//
//  DestinationsView.swift
//  ParkTimes
//
//  Browse every destination the themeparks.wiki API knows about and jump
//  into any park's live wait times.
//

import SwiftUI

struct DestinationsView: View {
    @State private var destinations: [Destination] = []
    @State private var loading = false
    @State private var errorMessage: String?
    @State private var searchText = ""

    private var filtered: [Destination] {
        let sorted = destinations.sorted { $0.name < $1.name }
        guard !searchText.isEmpty else { return sorted }
        return sorted.filter { destination in
            destination.name.localizedCaseInsensitiveContains(searchText)
                || destination.parks.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        Group {
            if loading && destinations.isEmpty {
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage, destinations.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary.opacity(0.6))
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task { await load() }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filtered.isEmpty && !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        ForEach(filtered) { destination in
                            DestinationSection(destination: destination)
                        }
                    }
                    .padding()
                }
                .scrollIndicators(.hidden)
            }
        }
        .magicBackground()
        .navigationTitle("Destinations")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search destinations & parks")
        .task {
            await load()
        }
    }

    private func load() async {
        guard destinations.isEmpty else { return }
        loading = true
        errorMessage = nil
        do {
            destinations = try await ParkService.getDestinations()
        } catch {
            errorMessage = "Unable to load destinations.\nCheck your connection and try again."
        }
        loading = false
    }
}

private struct DestinationSection: View {
    let destination: Destination

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(destination.name)
                .font(.headline)
                .foregroundStyle(.primary)

            ForEach(destination.parks) { park in
                NavigationLink {
                    RidesView(park: ParkModel(id: park.id, name: park.name, subtitle: destination.name))
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.subheadline)
                            .foregroundStyle(.cyan.opacity(0.7))
                            .frame(width: 24)
                        Text(park.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.cardBackground)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
