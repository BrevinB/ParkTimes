//
//  RidesView.swift
//  ParkTimes
//

import SwiftUI

struct RidesView: View {
    @EnvironmentObject private var favoritesStore: FavoritesStore
    @ObservedObject private var liveActivity = LiveActivityController.shared
    @Environment(\.scenePhase) private var scenePhase

    @State private var entities: [LiveEntity] = []
    @State private var schedule: [ScheduleEntry] = []
    @State private var locations: [String: EntityLocation] = [:]
    @State private var landNameById: [String: String] = [:]
    @State private var timezone: TimeZone?
    @State private var loading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var sortOrder: RideSortOrder = .wait
    @State private var viewMode: ViewMode = .status
    @State private var lastUpdated: Date?
    @State private var showRefreshFailed = false
    @State private var showMap = false
    @State private var pulse = false
    @State private var autoOpenedRide: LiveEntity?

    let park: ParkModel

    enum ViewMode: String, CaseIterable, Identifiable {
        case status = "By Status"
        case land = "By Land"
        var id: String { rawValue }
    }

    private var tz: TimeZone { timezone ?? park.timezone ?? .current }

    private var sections: RideSections {
        RideSections.build(
            entities: entities,
            search: searchText,
            favoriteIds: favoritesStore.ids,
            sort: sortOrder
        )
    }

    private var landGroups: [LandGroup] {
        LandGroup.build(entities: entities, search: searchText, landNameById: landNameById)
    }

    var body: some View {
        Group {
            if loading {
                loadingView
            } else if let errorMessage {
                errorView(errorMessage)
            } else {
                contentView
            }
        }
        .magicBackground()
        .navigationTitle(park.name)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search attractions & shows")
        .toolbar {
            if liveActivity.isActive(for: park.id) {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .foregroundStyle(.cyan)
                        .symbolEffect(.variableColor.iterative, options: .repeating)
                        .accessibilityLabel("Live Activity running for this park")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                optionsMenu
            }
        }
        .sheet(isPresented: $showMap) {
            ParkMapView(park: park, entities: entities, locations: locations, timezone: tz)
        }
        .navigationDestination(item: $autoOpenedRide) { ride in
            RideDetailView(ride: ride, location: locations[ride.id], park: park, timezone: tz)
        }
        .task(id: park.id) {
            await loadData()
            handleLaunchArguments()
        }
        .task {
            // Wait times go stale fast — refresh quietly every minute.
            // Break on cancellation (sleep throws) so navigating away doesn't
            // fire one last doomed request.
            while true {
                do {
                    try await Task.sleep(for: .seconds(60))
                } catch {
                    break
                }
                await loadData()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, let lastUpdated, Date().timeIntervalSince(lastUpdated) > 60 {
                Task { await loadData() }
            }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(MagicCopy.loadingPhrase(seed: park.id.hashValue))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.cyan.opacity(0.7))

                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.cardBackground)
                    .frame(height: 64)

                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.cardBackground)
                            .frame(height: 88)
                    }
                }

                VStack(spacing: 10) {
                    ForEach(0..<8, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.cardBackground)
                            .frame(height: 62)
                    }
                }
            }
            .padding()
            .opacity(pulse ? 0.45 : 1)
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
            .onAppear { pulse = true }
        }
        .scrollIndicators(.hidden)
        .scrollDisabled(true)
        .accessibilityLabel("Loading attractions")
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 40))
                .foregroundStyle(.secondary.opacity(0.6))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await loadData() }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var contentView: some View {
        let sections = self.sections

        return ScrollView {
            LazyVStack(spacing: 20) {
                ParkHoursBar(
                    info: ParkHoursInfo.today(schedule: schedule, timezone: tz),
                    timezone: tz
                )

                HStack(spacing: 10) {
                    StatCard(title: "Open", value: "\(sections.openCount)", icon: "checkmark.circle.fill", color: .green)
                    StatCard(title: "Avg Wait", value: "\(sections.avgWait)m", icon: "gauge.medium", color: .cyan)
                    StatCard(title: "Max Wait", value: "\(sections.maxWait)m", icon: "flame.fill", color: .orange)
                }

                if let lastUpdated {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption2)
                        Text("Updated \(Text(lastUpdated, style: .relative)) ago")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }

                if !searchText.isEmpty && sections.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 36))
                            .foregroundStyle(.purple.opacity(0.7))
                        Text("Nothing here matches \u{201C}\(searchText)\u{201D}")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                        Text("Try a different attraction or show name.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 32)
                } else if viewMode == .status {
                    statusSections(sections)
                } else {
                    landSections
                }
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .refreshable {
            await loadData()
        }
        .overlay(alignment: .top) {
            if showRefreshFailed {
                Label(MagicCopy.refreshFailed, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.orange.opacity(0.85)))
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 6)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showRefreshFailed)
    }

    @ViewBuilder
    private func statusSections(_ sections: RideSections) -> some View {
        if !sections.favorites.isEmpty {
            AttractionSectionView(
                title: "Favorites", icon: "star.fill", color: .yellow,
                attractions: sections.favorites, locations: locations, park: park, timezone: tz
            )
        }
        if !sections.open.isEmpty {
            AttractionSectionView(
                title: "Open", icon: "checkmark.circle.fill", color: .green,
                attractions: sections.open, locations: locations, park: park, timezone: tz
            )
        }
        if !sections.shows.isEmpty {
            AttractionSectionView(
                title: "Shows", icon: "theatermasks.fill", color: .purple,
                attractions: sections.shows, locations: locations, park: park, timezone: tz
            )
        }
        if !sections.down.isEmpty {
            AttractionSectionView(
                title: "Temporarily Down", icon: "exclamationmark.triangle.fill", color: .orange,
                attractions: sections.down, locations: locations, park: park, timezone: tz
            )
        }
        if !sections.closed.isEmpty {
            AttractionSectionView(
                title: "Closed", icon: "xmark.circle.fill", color: .red,
                attractions: sections.closed, locations: locations, park: park, timezone: tz,
                startExpanded: false
            )
        }
        if !sections.refurbishment.isEmpty {
            AttractionSectionView(
                title: "Refurbishment", icon: "wrench.and.screwdriver.fill", color: .yellow,
                attractions: sections.refurbishment, locations: locations, park: park, timezone: tz,
                startExpanded: false
            )
        }
    }

    @ViewBuilder
    private var landSections: some View {
        if landNameById.isEmpty {
            Text("This park doesn't publish land information.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 24)
        } else {
            ForEach(landGroups) { group in
                AttractionSectionView(
                    title: group.name, icon: "map.fill", color: .cyan,
                    attractions: group.rides, locations: locations, park: park, timezone: tz
                )
            }
        }
    }

    private var optionsMenu: some View {
        Menu {
            Picker("View", selection: $viewMode) {
                ForEach(ViewMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }

            Picker("Sort open rides", selection: $sortOrder) {
                ForEach(RideSortOrder.allCases) { order in
                    Label(order.rawValue, systemImage: order.icon).tag(order)
                }
            }

            Divider()

            Button {
                showMap = true
            } label: {
                Label("Park Map", systemImage: "map")
            }

            if liveActivity.isSupported {
                if liveActivity.isActive(for: park.id) {
                    Button(role: .destructive) {
                        liveActivity.end()
                    } label: {
                        Label("Stop Live Activity", systemImage: "stop.circle")
                    }
                } else {
                    Button {
                        liveActivity.start(park: park, entities: entities, favoriteIds: favoritesStore.ids)
                    } label: {
                        Label("Start Live Activity", systemImage: "clock.badge.checkmark")
                    }
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundStyle(.primary)
        }
    }

    /// Screenshot/demo hooks: `-openRide <name-fragment>` pushes a ride's
    /// detail after loading; `-openMap` presents the park map.
    private func handleLaunchArguments() {
        let arguments = ProcessInfo.processInfo.arguments
        if let flagIndex = arguments.firstIndex(of: "-openRide"),
           arguments.indices.contains(flagIndex + 1),
           autoOpenedRide == nil {
            let fragment = arguments[flagIndex + 1]
            autoOpenedRide = entities.first { $0.name.localizedCaseInsensitiveContains(fragment) }
        }
        if arguments.contains("-openMap") {
            showMap = true
        }
    }

    // MARK: - Data

    private func loadData() async {
        if entities.isEmpty { loading = true }
        errorMessage = nil

        if timezone == nil && park.timezone == nil {
            if let details = try? await ParkService.getEntity(id: park.id), let tzId = details.timezone {
                timezone = TimeZone(identifier: tzId)
            }
        }

        do {
            async let liveResult = ParkService.getLiveData(parkId: park.id)
            async let schedResult = ParkService.getSchedule(parkId: park.id)
            async let childResult = ParkService.getChildren(parkId: park.id)

            entities = try await liveResult
            lastUpdated = Date()

            schedule = (try? await schedResult) ?? schedule

            if let children = try? await childResult {
                var lands: [String: String] = [:]
                for child in children where child.entityType == .land {
                    lands[child.id] = child.name
                }

                var newLocations: [String: EntityLocation] = [:]
                var newLandNames: [String: String] = [:]
                for child in children {
                    if let location = child.location {
                        newLocations[child.id] = location
                    }
                    if let parentId = child.parentId, let landName = lands[parentId] {
                        newLandNames[child.id] = landName
                    }
                }
                locations = newLocations
                landNameById = newLandNames
            }

            WaitAlertManager.evaluate(entities: entities)
            liveActivity.update(parkId: park.id, entities: entities, favoriteIds: favoritesStore.ids)
        } catch {
            // A request cancelled by navigation isn't a failure — stay quiet.
            let wasCancelled = Task.isCancelled
                || error is CancellationError
                || (error as? URLError)?.code == .cancelled
            if wasCancelled {
                loading = false
                return
            }

            if entities.isEmpty {
                errorMessage = (error as? PTError)?.errorDescription
                    ?? "Unable to load rides.\nCheck your connection and try again."
            } else {
                showRefreshFailed = true
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    showRefreshFailed = false
                }
            }
        }

        loading = false
    }
}

// MARK: - Park Hours Bar

struct ParkHoursBar: View {
    let info: ParkHoursInfo
    let timezone: TimeZone

    var body: some View {
        let state = info.openState()

        HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .font(.title3)
                .foregroundStyle(.cyan)

            VStack(alignment: .leading, spacing: 3) {
                statusLine(state)

                if let operating = info.operating,
                   let open = operating.openingTime, let close = operating.closingTime {
                    Text("\(open.toTime(in: timezone)) – \(close.toTime(in: timezone))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let early = info.earlyEntry, let earlyOpen = early.openingTime {
                    Text("Early Entry from \(earlyOpen.toTime(in: timezone))")
                        .font(.caption)
                        .foregroundStyle(.cyan.opacity(0.7))
                }

                ForEach(info.ticketedEvents) { event in
                    if let start = event.openingTime, let end = event.closingTime {
                        Text("\(event.description ?? "Special event"): \(start.toTime(in: timezone)) – \(end.toTime(in: timezone))")
                            .font(.caption)
                            .foregroundStyle(.purple.opacity(0.9))
                    }
                }
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.cyan.opacity(0.2), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func statusLine(_ state: ParkHoursInfo.OpenState) -> some View {
        switch state {
        case .openNow(let closes):
            label("Open now · Closes \(PTFormat.time(closes, in: timezone))", color: .green)
        case .opensLater(let opens):
            label("Opens at \(PTFormat.time(opens, in: timezone))", color: .orange)
        case .closedToday:
            label("Closed for today", color: .red)
        case .unknown:
            label("Park hours", color: .white.opacity(0.7))
        }
    }

    private func label(_ text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(text)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .monospacedDigit()
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }
}
