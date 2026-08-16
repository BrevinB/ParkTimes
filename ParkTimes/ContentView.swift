//
//  ContentView.swift
//  ParkTimes
//
//  Created by Brevin Blalock on 8/28/23.
//

import SwiftUI

struct ContentView: View {

    @State private var summaries: [String: ParkLiveSummary] = [:]
    @State private var path = NavigationPath()
    @ObservedObject private var deepLinks = DeepLinkRouter.shared

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 10) {
                            Text(greeting)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            Image(systemName: "sparkles")
                                .font(.title2)
                                .foregroundStyle(.yellow.opacity(0.85))
                                .accessibilityHidden(true)
                        }
                        Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(MagicCopy.greetingSubline(hour: Calendar.current.component(.hour, from: Date())))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.cyan.opacity(0.75))
                    }
                    .padding(.horizontal)

                    ResortSection(title: "Walt Disney World", parks: ParkCatalog.disneyParks, summaries: summaries)
                    ResortSection(title: "Universal Orlando", parks: ParkCatalog.universalParks, summaries: summaries)

                    NavigationLink {
                        DestinationsView()
                    } label: {
                        MoreDestinationsCard()
                    }
                    .buttonStyle(MagicCardButtonStyle())

                    NavigationLink {
                        AboutView()
                    } label: {
                        Text("About ParkTimes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical)
            }
            .scrollIndicators(.hidden)
            .magicBackground()
            .refreshable {
                await loadSummaries()
            }
            .navigationDestination(for: ParkModel.self) { park in
                RidesView(park: park)
            }
            .onOpenURL { url in
                deepLinks.handle(url: url)
            }
            .onChange(of: deepLinks.pendingPark) { _, park in
                if let park {
                    path.append(park)
                    deepLinks.pendingPark = nil
                }
            }
            .task {
                openParkFromLaunchArguments()
                await loadSummaries()
            }
        }
    }

    /// Screenshot/demo hook: `-openPark <park-id>` deep-opens a park on launch.
    private func openParkFromLaunchArguments() {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "-openPark"),
              arguments.indices.contains(flagIndex + 1) else { return }
        let parkId = arguments[flagIndex + 1]
        if let park = (ParkCatalog.disneyParks + ParkCatalog.universalParks).first(where: { $0.id == parkId }) {
            path.append(park)
        }
    }

    private func loadSummaries() async {
        let parks = ParkCatalog.disneyParks + ParkCatalog.universalParks
        await withTaskGroup(of: (String, ParkLiveSummary)?.self) { group in
            for park in parks {
                group.addTask {
                    guard let entities = try? await ParkService.getLiveData(parkId: park.id) else { return nil }
                    return (park.id, ParkLiveSummary.from(entities: entities))
                }
            }
            for await result in group {
                if let (id, summary) = result {
                    summaries[id] = summary
                }
            }
        }
    }
}

struct ResortSection: View {
    let title: String
    let parks: [ParkModel]
    let summaries: [String: ParkLiveSummary]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(parks.count) parks")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            ForEach(parks) { park in
                NavigationLink {
                    RidesView(park: park)
                } label: {
                    ParkCardView(park: park, summary: summaries[park.id])
                }
                .buttonStyle(MagicCardButtonStyle())
            }
        }
    }
}

struct MoreDestinationsCard: View {
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "globe")
                .font(.title2)
                .foregroundStyle(.cyan)

            VStack(alignment: .leading, spacing: 3) {
                Text("More Destinations")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("Disneyland, Tokyo, Paris and beyond")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.cyan.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ContentView()
        .environmentObject(FavoritesStore.shared)
        .environmentObject(AlertStore.shared)
}
