//
//  ParkTimesTests.swift
//  ParkTimesTests
//

import Foundation
import Testing
@testable import ParkTimes

// MARK: - Helpers

private func makeEntity(
    id: String = UUID().uuidString,
    name: String = "Test Ride",
    type: EntityType = .attraction,
    status: EntityStatus? = .operating,
    wait: Int? = nil,
    llAmount: Int? = nil,
    showtimes: [TimePeriod]? = nil
) -> LiveEntity {
    let queue: QueueData? = (wait != nil || llAmount != nil) ? QueueData(
        standby: wait.map { StandbyQueue(waitTime: $0) },
        singleRider: nil,
        returnTime: nil,
        paidReturnTime: llAmount.map {
            PaidReturnTime(
                price: PriceInfo(amount: $0, currency: "USD", formatted: "$\($0 / 100)"),
                state: .available,
                returnStart: nil,
                returnEnd: nil
            )
        },
        paidStandby: nil,
        boardingGroup: nil
    ) : nil

    return LiveEntity(
        id: id,
        name: name,
        entityType: type,
        parkId: nil,
        externalId: nil,
        status: status,
        lastUpdated: nil,
        queue: queue,
        forecast: nil,
        operatingHours: nil,
        showtimes: showtimes
    )
}

private let newYork = TimeZone(identifier: "America/New_York")!

// MARK: - Lenient Enum Decoding

@Suite struct EnumDecodingTests {
    @Test func unknownStatusSurvivesDecoding() throws {
        let json = """
        {"id": "1", "name": "Ride", "entityType": "ATTRACTION", "status": "SOMETHING_NEW"}
        """.data(using: .utf8)!
        let entity = try JSONDecoder().decode(LiveEntity.self, from: json)
        #expect(entity.status == .unknown("SOMETHING_NEW"))
        #expect(!entity.isOpen)
    }

    @Test func knownValuesDecode() throws {
        let json = """
        {"id": "1", "name": "Ride", "entityType": "SHOW", "status": "OPERATING",
         "queue": {"STANDBY": {"waitTime": 25}, "SINGLE_RIDER": {"waitTime": 10}}}
        """.data(using: .utf8)!
        let entity = try JSONDecoder().decode(LiveEntity.self, from: json)
        #expect(entity.isShow)
        #expect(entity.isOpen)
        #expect(entity.waitTime == 25)
        #expect(entity.singleRiderWait == 10)
    }
}

// MARK: - Section Building

@Suite struct RideSectionsTests {
    private var entities: [LiveEntity] {
        [
            makeEntity(id: "a", name: "Alpha", status: .operating, wait: 45),
            makeEntity(id: "b", name: "Beta", status: .operating, wait: 10),
            makeEntity(id: "c", name: "Gamma", status: .down),
            makeEntity(id: "d", name: "Delta", status: .closed),
            makeEntity(id: "e", name: "Epsilon", status: .refurbishment),
            makeEntity(id: "f", name: "Fireworks", type: .show, status: .operating),
            makeEntity(id: "g", name: "Grill", type: .restaurant, status: .operating),
        ]
    }

    @Test func bucketsByStatus() {
        let sections = RideSections.build(entities: entities)
        #expect(sections.open.map(\.id) == ["a", "b"])
        #expect(sections.down.map(\.id) == ["c"])
        #expect(sections.closed.map(\.id) == ["d"])
        #expect(sections.refurbishment.map(\.id) == ["e"])
        #expect(sections.shows.map(\.id) == ["f"])
        // Restaurants excluded entirely
        #expect(sections.totalAttractions == 5)
    }

    @Test func statsComputedFromOpenAttractions() {
        let sections = RideSections.build(entities: entities)
        #expect(sections.openCount == 2)
        #expect(sections.avgWait == 27)   // (45 + 10) / 2
        #expect(sections.maxWait == 45)
    }

    @Test func searchFiltersSectionsButNotStats() {
        let sections = RideSections.build(entities: entities, search: "Alpha")
        #expect(sections.open.map(\.id) == ["a"])
        #expect(sections.closed.isEmpty)
        // Stats still reflect the whole park
        #expect(sections.openCount == 2)
        #expect(sections.maxWait == 45)
    }

    @Test func favoritesArePinned() {
        let sections = RideSections.build(entities: entities, favoriteIds: ["b", "f"])
        #expect(Set(sections.favorites.map(\.id)) == ["b", "f"])
        // Favorites also remain in their regular sections
        #expect(sections.open.contains { $0.id == "b" })
    }

    @Test func sortByWaitDescending() {
        let sections = RideSections.build(entities: entities, sort: .wait)
        #expect(sections.open.first?.id == "a")
    }

    @Test func sortByName() {
        let sections = RideSections.build(entities: entities, sort: .name)
        #expect(sections.open.map(\.name) == ["Alpha", "Beta"])
    }

    @Test func sortByLightningLanePrice() {
        let priced = [
            makeEntity(id: "cheap", status: .operating, wait: 5, llAmount: 900),
            makeEntity(id: "pricey", status: .operating, wait: 5, llAmount: 2500),
            makeEntity(id: "none", status: .operating, wait: 5),
        ]
        let sections = RideSections.build(entities: priced, sort: .lightningLane)
        #expect(sections.open.map(\.id) == ["pricey", "cheap", "none"])
    }

    @Test func emptySearchResultReportsEmpty() {
        let sections = RideSections.build(entities: entities, search: "zzz-no-match")
        #expect(sections.isEmpty)
    }
}

// MARK: - Land Grouping

@Suite struct LandGroupTests {
    @Test func groupsByLandWithFallback() {
        let entities = [
            makeEntity(id: "a", name: "Alpha", status: .operating, wait: 20),
            makeEntity(id: "b", name: "Beta", status: .closed),
            makeEntity(id: "c", name: "Homeless Ride", status: .operating, wait: 5),
        ]
        let groups = LandGroup.build(
            entities: entities,
            landNameById: ["a": "Fantasyland", "b": "Fantasyland"]
        )
        #expect(groups.map(\.name) == ["Elsewhere in the Park", "Fantasyland"])
        // Open before closed within a land
        #expect(groups[1].rides.map(\.id) == ["a", "b"])
    }
}

// MARK: - Park Hours

@Suite struct ParkHoursTests {
    private func schedule(day: String) -> [ScheduleEntry] {
        [
            ScheduleEntry(
                date: day, type: .operating,
                openingTime: "\(day)T09:00:00-04:00",
                closingTime: "\(day)T22:00:00-04:00",
                description: nil
            ),
            ScheduleEntry(
                date: day, type: .ticketedEvent,
                openingTime: "\(day)T19:00:00-04:00",
                closingTime: "\(day)T23:59:00-04:00",
                description: "Special Party"
            ),
        ]
    }

    @Test func picksTodayInParkTimezone() {
        // 3 AM UTC on Aug 9 is still Aug 8 in New York.
        let now = PTFormat.parseISO("2026-08-09T03:00:00Z")!
        let info = ParkHoursInfo.today(
            schedule: schedule(day: "2026-08-08"),
            timezone: newYork,
            now: now
        )
        #expect(info.operating != nil)
        #expect(info.ticketedEvents.count == 1)
    }

    @Test func openStateTransitions() {
        let info = ParkHoursInfo.today(
            schedule: schedule(day: "2026-08-08"),
            timezone: newYork,
            now: PTFormat.parseISO("2026-08-08T16:00:00-04:00")!
        )

        let before = PTFormat.parseISO("2026-08-08T08:00:00-04:00")!
        let during = PTFormat.parseISO("2026-08-08T12:00:00-04:00")!
        let after = PTFormat.parseISO("2026-08-08T23:00:00-04:00")!

        if case .opensLater = info.openState(now: before) {} else { Issue.record("expected opensLater") }
        if case .openNow = info.openState(now: during) {} else { Issue.record("expected openNow") }
        if case .closedToday = info.openState(now: after) {} else { Issue.record("expected closedToday") }
    }
}

// MARK: - Time Formatting

@Suite struct TimeFormattingTests {
    @Test func dayStringRespectsTimezone() {
        let instant = PTFormat.parseISO("2026-08-09T03:00:00Z")!
        #expect(PTFormat.dayString(for: instant, in: newYork) == "2026-08-08")
        #expect(PTFormat.dayString(for: instant, in: TimeZone(identifier: "UTC")!) == "2026-08-09")
    }

    @Test func parsesBothISOVariants() {
        #expect(PTFormat.parseISO("2026-08-09T09:00:00-04:00") != nil)
        #expect(PTFormat.parseISO("2026-08-09T09:00:00.123-04:00") != nil)
        #expect(PTFormat.parseISO("not a date") == nil)
    }

    @Test func timeFormatsInParkTimezone() {
        let instant = PTFormat.parseISO("2026-08-09T13:00:00Z")!  // 9 AM in New York
        let formatted = PTFormat.time(instant, in: newYork)
        #expect(formatted.contains("9"))
    }
}

// MARK: - Showtimes

@Suite struct ShowtimeTests {
    @Test func nextShowtimeSkipsPastShows() {
        let entity = makeEntity(type: .show, showtimes: [
            TimePeriod(type: "Performance", startTime: "2026-08-08T14:00:00-04:00", endTime: nil),
            TimePeriod(type: "Performance", startTime: "2026-08-08T18:00:00-04:00", endTime: nil),
            TimePeriod(type: "Performance", startTime: "2026-08-08T21:00:00-04:00", endTime: nil),
        ])
        let now = PTFormat.parseISO("2026-08-08T19:00:00-04:00")!
        let next = entity.nextShowtime(after: now)
        #expect(next == PTFormat.parseISO("2026-08-08T21:00:00-04:00"))
    }

    @Test func nextShowtimeNilWhenDoneForToday() {
        let entity = makeEntity(type: .show, showtimes: [
            TimePeriod(type: "Performance", startTime: "2026-08-08T14:00:00-04:00", endTime: nil),
        ])
        let now = PTFormat.parseISO("2026-08-08T19:00:00-04:00")!
        #expect(entity.nextShowtime(after: now) == nil)
    }
}

// MARK: - Deep Links

@Suite struct DeepLinkTests {
    @Test @MainActor func rideURLRoundTrips() {
        let url = DeepLinkRouter.rideURL(parkId: "park-1", rideId: "ride-9", parkName: "Magic Kingdom")
        let router = DeepLinkRouter.shared
        router.handle(url: url)

        #expect(router.pendingPark?.id == "park-1")
        #expect(router.consumePendingRide(for: "park-1") == "ride-9")
        // One-shot: consuming again yields nothing.
        #expect(router.consumePendingRide(for: "park-1") == nil)
        router.pendingPark = nil
    }

    @Test @MainActor func knownParkResolvesFromCatalog() {
        let mk = ParkCatalog.disneyParks[0]
        let router = DeepLinkRouter.shared
        router.handle(url: URL(string: "parktimes://park/\(mk.id)")!)

        #expect(router.pendingPark?.name == "Magic Kingdom")
        #expect(router.pendingPark?.timezone != nil)
        router.pendingPark = nil
    }

    @Test @MainActor func rideConsumeIsParkScoped() {
        let router = DeepLinkRouter.shared
        router.handle(url: DeepLinkRouter.rideURL(parkId: "park-A", rideId: "r1", parkName: "A"))

        // A different park must not steal the pending ride.
        #expect(router.consumePendingRide(for: "park-B") == nil)
        #expect(router.consumePendingRide(for: "park-A") == "r1")
        router.pendingPark = nil
    }

    @Test @MainActor func foreignSchemeIgnored() {
        let router = DeepLinkRouter.shared
        router.handle(url: URL(string: "https://example.com/park/x")!)
        #expect(router.pendingPark == nil)
    }
}

// MARK: - Park Cache

@Suite struct ParkCacheTests {
    @Test func roundTripsSnapshot() {
        let parkId = "test-park-\(UUID().uuidString)"
        defer { ParkCache.remove(parkId: parkId) }

        let snapshot = ParkCache.Snapshot(
            fetched: Date(timeIntervalSince1970: 1_755_000_000),
            entities: [makeEntity(id: "r1", name: "Ride One", status: .operating, wait: 25)],
            schedule: [ScheduleEntry(date: "2026-08-16", type: .operating, openingTime: nil, closingTime: nil, description: nil)],
            locations: ["r1": EntityLocation(latitude: 28.4, longitude: -81.5)],
            landNameById: ["r1": "Fantasyland"],
            timezoneId: "America/New_York"
        )
        ParkCache.save(snapshot, parkId: parkId)

        let loaded = ParkCache.load(parkId: parkId)
        #expect(loaded != nil)
        #expect(loaded?.entities.first?.waitTime == 25)
        #expect(loaded?.landNameById["r1"] == "Fantasyland")
        #expect(loaded?.timezoneId == "America/New_York")
        #expect(loaded?.fetched == snapshot.fetched)
    }

    @Test func loadMissingReturnsNil() {
        #expect(ParkCache.load(parkId: "never-saved-\(UUID().uuidString)") == nil)
    }
}

// MARK: - Wait Alerts

@Suite struct WaitAlertTests {
    @Test func triggersOnlyWhenOpenAndUnderThreshold() {
        let entities = [
            makeEntity(id: "low", status: .operating, wait: 20),
            makeEntity(id: "high", status: .operating, wait: 90),
            makeEntity(id: "shut", status: .closed, wait: 5),
        ]
        let alerts = [
            WaitAlert(id: "low", rideName: "Low", parkId: "p", threshold: 30),
            WaitAlert(id: "high", rideName: "High", parkId: "p", threshold: 30),
            WaitAlert(id: "shut", rideName: "Shut", parkId: "p", threshold: 30),
            WaitAlert(id: "missing", rideName: "Missing", parkId: "p", threshold: 30),
        ]
        let triggered = AlertStore.triggered(by: entities, alerts: alerts)
        #expect(triggered.map(\.alert.id) == ["low"])
        #expect(triggered.first?.wait == 20)
    }
}
