//
//  RideDetailView.swift
//  ParkTimes
//

import SwiftUI
import MapKit
import Charts

struct RideDetailView: View {
    let ride: LiveEntity
    let location: EntityLocation?
    let park: ParkModel
    let timezone: TimeZone

    @EnvironmentObject private var favoritesStore: FavoritesStore
    @EnvironmentObject private var alertStore: AlertStore
    @State private var mapPosition: MapCameraPosition = .automatic

    private static let alertChoices = [15, 30, 45, 60]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Map
                if let location {
                    let coordinate = CLLocationCoordinate2D(
                        latitude: location.latitude,
                        longitude: location.longitude
                    )

                    Map(position: $mapPosition) {
                        Marker(ride.name, coordinate: coordinate)
                        UserAnnotation()
                    }
                    .mapStyle(.standard(elevation: .realistic))
                    .mapControls {
                        MapUserLocationButton()
                        MapCompass()
                    }
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .onAppear {
                        mapPosition = .region(MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
                        ))
                    }

                    Button {
                        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
                        mapItem.name = ride.name
                        mapItem.openInMaps(launchOptions: [
                            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
                        ])
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                .font(.title3)
                            Text("Get Walking Directions")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(.primary)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(.cyan.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }

                // Quick Stats
                quickStatsRow

                // Operating Hours
                if let hours = ride.operatingHours, !hours.isEmpty {
                    operatingHoursSection(hours)
                }

                // Showtimes (for shows)
                if ride.isShow, let showtimes = ride.showtimes, !showtimes.isEmpty {
                    showtimesSection(showtimes)
                }

                // Wait Forecast (for attractions)
                if ride.isAttraction, let forecast = ride.forecast, !forecast.isEmpty {
                    forecastSection(forecast)
                }

                // Queue Details
                if ride.isAttraction {
                    queueDetailsSection
                }
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .background(Color.midnight)
        .navigationTitle(ride.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    favoritesStore.toggle(ride: ride, park: park)
                } label: {
                    Image(systemName: favoritesStore.isFavorite(ride.id) ? "star.fill" : "star")
                        .foregroundStyle(.yellow)
                        .symbolEffect(.bounce, value: favoritesStore.isFavorite(ride.id))
                }
                .sensoryFeedback(.success, trigger: favoritesStore.isFavorite(ride.id))
                .accessibilityLabel(favoritesStore.isFavorite(ride.id) ? "Remove from favorites" : "Add to favorites")
            }
        }
    }

    // MARK: - Quick Stats Row

    private var quickStatsRow: some View {
        HStack(spacing: 10) {
            // Status
            DetailStat(
                label: "Status",
                value: statusText,
                color: statusColor
            )

            // Wait Time (attractions)
            if ride.isAttraction && ride.isOpen {
                DetailStat(
                    label: "Wait",
                    value: "\(ride.waitTime ?? 0)m",
                    color: Color.forWait(ride.waitTime ?? 0)
                )
            }

            // Lightning Lane
            if let llPrice = ride.lightningLanePrice {
                DetailStat(
                    label: "Lightning Lane",
                    value: llPrice,
                    color: .yellow
                )
            }
        }
    }

    private var statusText: String {
        if ride.isRefurbishment { return "Rehab" }
        if ride.isDown { return "Down" }
        return ride.isOpen ? "Open" : "Closed"
    }

    private var statusColor: Color {
        if ride.isRefurbishment { return .yellow }
        if ride.isDown { return .orange }
        return ride.isOpen ? .green : .red
    }

    // MARK: - Operating Hours

    private func operatingHoursSection(_ hours: [TimePeriod]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Operating Hours", systemImage: "clock")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(spacing: 8) {
                ForEach(hours) { period in
                    HStack {
                        Text(period.type?.capitalized ?? "Hours")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if let start = period.startTime, let end = period.endTime {
                            Text("\(start.toTime(in: timezone)) – \(end.toTime(in: timezone))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.surface)
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
        )
    }

    // MARK: - Showtimes

    private func showtimesSection(_ showtimes: [TimePeriod]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Showtimes", systemImage: "theatermasks.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            let now = Date()
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(showtimes) { show in
                    if let start = show.startTime {
                        let isPast = start.toDate().map { $0 < now } ?? false
                        Text(start.toTime(in: timezone))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(isPast ? Color.secondary.opacity(0.7) : .purple)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isPast ? Color.surface : .purple.opacity(0.15))
                            )
                            .accessibilityLabel(isPast ? "\(start.toTime(in: timezone)), already played" : start.toTime(in: timezone))
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
        )
    }

    // MARK: - Forecast Chart

    private func forecastSection(_ forecast: [ForecastEntry]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Wait Forecast", systemImage: "chart.xyaxis.line")
                .font(.headline)
                .foregroundStyle(.primary)

            if let comparison = forecastComparison(forecast) {
                Text(comparison)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            let now = Date()
            let times = forecast.compactMap { $0.time.toDate() }
            let showNow = (times.min().map { $0 <= now } ?? false) && (times.max().map { now <= $0 } ?? false)

            Chart {
                ForEach(forecast) { entry in
                    if let time = entry.time.toDate() {
                        AreaMark(
                            x: .value("Time", time),
                            y: .value("Wait", entry.waitTime)
                        )
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.cyan.opacity(0.3), .cyan.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        LineMark(
                            x: .value("Time", time),
                            y: .value("Wait", entry.waitTime)
                        )
                        .foregroundStyle(.cyan)
                        .lineStyle(StrokeStyle(lineWidth: 2))

                        PointMark(
                            x: .value("Time", time),
                            y: .value("Wait", entry.waitTime)
                        )
                        .foregroundStyle(.cyan)
                        .symbolSize(20)
                    }
                }

                if showNow {
                    RuleMark(x: .value("Now", now))
                        .foregroundStyle(.secondary.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        .annotation(position: .top, alignment: .center) {
                            Text("Now")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.secondary.opacity(0.25))
                    AxisValueLabel()
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 3)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.secondary.opacity(0.25))
                    AxisValueLabel(format: xAxisFormat)
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxisLabel("min", position: .trailing)
            .frame(height: 180)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
        )
    }

    /// "Posted 45m · forecast expected ~30m" — how the live wait compares to
    /// the prediction for this hour.
    private func forecastComparison(_ forecast: [ForecastEntry]) -> String? {
        guard ride.isOpen, let posted = ride.waitTime else { return nil }
        let now = Date()
        let nearest = forecast
            .compactMap { entry in entry.time.toDate().map { (date: $0, wait: entry.waitTime) } }
            .min { abs($0.date.timeIntervalSince(now)) < abs($1.date.timeIntervalSince(now)) }
        guard let nearest, abs(nearest.date.timeIntervalSince(now)) < 90 * 60 else { return nil }
        return "Posted \(posted)m · forecast expected ~\(nearest.wait)m"
    }

    private var xAxisFormat: Date.FormatStyle {
        var style = Date.FormatStyle.dateTime.hour()
        style.timeZone = timezone
        return style
    }

    // MARK: - Queue Details

    private var queueDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Queue Information", systemImage: "person.3.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(spacing: 8) {
                // Standby
                if let wait = ride.waitTime {
                    queueRow(
                        title: "Standby",
                        detail: "\(wait) min",
                        icon: "person.fill",
                        color: .primary
                    )
                }

                // Single Rider
                if let queue = ride.queue, queue.singleRider != nil {
                    queueRow(
                        title: "Single Rider",
                        detail: ride.singleRiderWait.map { "\($0) min" } ?? "Available",
                        icon: "person.crop.circle.badge.checkmark",
                        color: .mint
                    )
                }

                // Virtual Queue / Boarding Group
                if let boardingGroup = ride.queue?.boardingGroup {
                    queueRow(
                        title: "Virtual Queue",
                        detail: boardingGroupText(boardingGroup),
                        icon: "ticket.fill",
                        color: .purple
                    )
                }

                // Lightning Lane
                if let lightningLane = ride.queue?.paidReturnTime {
                    let stateText: String = {
                        let state = lightningLane.state?.displayName ?? "Unavailable"
                        if let price = lightningLane.price?.formatted {
                            return "\(price) · \(state)"
                        }
                        return state
                    }()
                    queueRow(
                        title: "Lightning Lane",
                        detail: stateText,
                        icon: "bolt.fill",
                        color: .yellow
                    )
                }

                // Return Time
                if let returnTime = ride.queue?.returnTime {
                    queueRow(
                        title: "Return Time",
                        detail: returnTime.state?.displayName ?? "Unavailable",
                        icon: "arrow.uturn.left.circle.fill",
                        color: .cyan
                    )
                }

                waitAlertRow
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
        )
    }

    private func boardingGroupText(_ group: BoardingGroup) -> String {
        var parts: [String] = []
        if let status = group.allocationStatus {
            parts.append(status.displayName)
        }
        if let start = group.currentGroupStart, let end = group.currentGroupEnd {
            parts.append("Groups \(start)–\(end)")
        }
        if let wait = group.estimatedWait {
            parts.append("~\(wait) min")
        }
        return parts.isEmpty ? "See app" : parts.joined(separator: " · ")
    }

    private var waitAlertRow: some View {
        HStack {
            Image(systemName: "bell.fill")
                .font(.subheadline)
                .foregroundStyle(alertStore.threshold(for: ride.id) == nil ? Color.secondary : .cyan)
                .frame(width: 24)

            Text("Wait Alert")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Menu {
                Button("Off") {
                    alertStore.set(threshold: nil, ride: ride, park: park)
                }
                ForEach(Self.alertChoices, id: \.self) { minutes in
                    Button("Under \(minutes) min") {
                        alertStore.set(threshold: minutes, ride: ride, park: park)
                        WaitAlertManager.requestAuthorization()
                        WaitAlertManager.scheduleBackgroundRefresh()
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(alertStore.threshold(for: ride.id).map { "Under \($0) min" } ?? "Off")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(.cyan)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.surface)
        )
        .accessibilityElement(children: .combine)
    }

    private func queueRow(title: String, detail: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(detail)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.surface)
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Detail Stat Card

struct DetailStat: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .monospacedDigit()
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
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
        .accessibilityLabel("\(label): \(value)")
    }
}
