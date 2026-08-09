//
//  Models.swift
//  ParkTimes
//

import Foundation

// MARK: - Park

struct ParkModel: Identifiable, Hashable {
    let id: String
    let name: String
    let subtitle: String
    var timezone: TimeZone? = nil
}

enum ParkCatalog {
    static let orlando = TimeZone(identifier: "America/New_York")

    // Subtitles are deliberately our own words — no official park slogans.
    static let disneyParks: [ParkModel] = [
        ParkModel(id: "75ea578a-adc8-4116-a54d-dccb60765ef9", name: "Magic Kingdom", subtitle: "Classics & nightly fireworks", timezone: orlando),
        ParkModel(id: "47f90d2c-e191-4239-a466-5892ef59a88b", name: "EPCOT", subtitle: "Around the world in a day", timezone: orlando),
        ParkModel(id: "288747d1-8b4f-4a64-867e-ea7c9b27bad8", name: "Hollywood Studios", subtitle: "Thrills with a movie-set feel", timezone: orlando),
        ParkModel(id: "1c84a229-8862-4648-9c71-378ddd2c7693", name: "Animal Kingdom", subtitle: "Wild landscapes & big coasters", timezone: orlando),
    ]

    static let universalParks: [ParkModel] = [
        ParkModel(id: "267615cc-8943-4c2a-ae2c-5da728ca591f", name: "Islands of Adventure", subtitle: "Seven islands of thrills", timezone: orlando),
        ParkModel(id: "eb3f4560-2383-4a36-9152-6b3e5ed6bc57", name: "Universal Studios", subtitle: "Studio-lot rides & shows", timezone: orlando),
        ParkModel(id: "12dbb85b-265f-44e6-bccf-f1faa17211fc", name: "Epic Universe", subtitle: "The newest park in Orlando", timezone: orlando),
    ]
}

// MARK: - Lenient String Enums

/// String-backed enums that survive unknown API values instead of failing to decode.
enum EntityStatus: RawRepresentable, Codable, Equatable, Hashable {
    case operating
    case down
    case closed
    case refurbishment
    case unknown(String)

    init(rawValue: String) {
        switch rawValue {
        case "OPERATING": self = .operating
        case "DOWN": self = .down
        case "CLOSED": self = .closed
        case "REFURBISHMENT": self = .refurbishment
        default: self = .unknown(rawValue)
        }
    }

    var rawValue: String {
        switch self {
        case .operating: return "OPERATING"
        case .down: return "DOWN"
        case .closed: return "CLOSED"
        case .refurbishment: return "REFURBISHMENT"
        case .unknown(let value): return value
        }
    }
}

enum EntityType: RawRepresentable, Codable, Equatable, Hashable {
    case attraction
    case show
    case restaurant
    case land
    case park
    case destination
    case hotel
    case unknown(String)

    init(rawValue: String) {
        switch rawValue {
        case "ATTRACTION": self = .attraction
        case "SHOW": self = .show
        case "RESTAURANT": self = .restaurant
        case "LAND": self = .land
        case "PARK": self = .park
        case "DESTINATION": self = .destination
        case "HOTEL": self = .hotel
        default: self = .unknown(rawValue)
        }
    }

    var rawValue: String {
        switch self {
        case .attraction: return "ATTRACTION"
        case .show: return "SHOW"
        case .restaurant: return "RESTAURANT"
        case .land: return "LAND"
        case .park: return "PARK"
        case .destination: return "DESTINATION"
        case .hotel: return "HOTEL"
        case .unknown(let value): return value
        }
    }
}

enum QueueState: RawRepresentable, Codable, Equatable, Hashable {
    case available
    case paused
    case closed
    case finished
    case tempFull
    case unknown(String)

    init(rawValue: String) {
        switch rawValue {
        case "AVAILABLE": self = .available
        case "PAUSED": self = .paused
        case "CLOSED": self = .closed
        case "FINISHED": self = .finished
        case "TEMP_FULL": self = .tempFull
        default: self = .unknown(rawValue)
        }
    }

    var rawValue: String {
        switch self {
        case .available: return "AVAILABLE"
        case .paused: return "PAUSED"
        case .closed: return "CLOSED"
        case .finished: return "FINISHED"
        case .tempFull: return "TEMP_FULL"
        case .unknown(let value): return value
        }
    }

    var displayName: String {
        switch self {
        case .available: return "Available"
        case .paused: return "Paused"
        case .closed: return "Closed"
        case .finished: return "Finished"
        case .tempFull: return "Temporarily Full"
        case .unknown(let value): return value.capitalized
        }
    }
}

enum ScheduleType: RawRepresentable, Codable, Equatable, Hashable {
    case operating
    case ticketedEvent
    case extraHours
    case info
    case unknown(String)

    init(rawValue: String) {
        switch rawValue {
        case "OPERATING": self = .operating
        case "TICKETED_EVENT": self = .ticketedEvent
        case "EXTRA_HOURS": self = .extraHours
        case "INFO": self = .info
        default: self = .unknown(rawValue)
        }
    }

    var rawValue: String {
        switch self {
        case .operating: return "OPERATING"
        case .ticketedEvent: return "TICKETED_EVENT"
        case .extraHours: return "EXTRA_HOURS"
        case .info: return "INFO"
        case .unknown(let value): return value
        }
    }
}

// MARK: - Live Data

struct LiveDataResponse: Codable {
    let id: String
    let name: String
    let liveData: [LiveEntity]
}

struct LiveEntity: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let entityType: EntityType
    let parkId: String?
    let externalId: String?
    let status: EntityStatus?
    let lastUpdated: String?
    let queue: QueueData?
    let forecast: [ForecastEntry]?
    let operatingHours: [TimePeriod]?
    let showtimes: [TimePeriod]?
}

struct QueueData: Codable, Equatable, Hashable {
    let standby: StandbyQueue?
    let singleRider: StandbyQueue?
    let returnTime: ReturnTimeQueue?
    let paidReturnTime: PaidReturnTime?
    let paidStandby: StandbyQueue?
    let boardingGroup: BoardingGroup?

    enum CodingKeys: String, CodingKey {
        case standby = "STANDBY"
        case singleRider = "SINGLE_RIDER"
        case returnTime = "RETURN_TIME"
        case paidReturnTime = "PAID_RETURN_TIME"
        case paidStandby = "PAID_STANDBY"
        case boardingGroup = "BOARDING_GROUP"
    }
}

struct StandbyQueue: Codable, Equatable, Hashable {
    let waitTime: Int?
}

struct PaidReturnTime: Codable, Equatable, Hashable {
    let price: PriceInfo?
    let state: QueueState?
    let returnStart: String?
    let returnEnd: String?
}

struct PriceInfo: Codable, Equatable, Hashable {
    let amount: Int?
    let currency: String?
    let formatted: String?
}

struct ReturnTimeQueue: Codable, Equatable, Hashable {
    let state: QueueState?
    let returnStart: String?
    let returnEnd: String?
}

struct BoardingGroup: Codable, Equatable, Hashable {
    let allocationStatus: QueueState?
    let currentGroupStart: Int?
    let currentGroupEnd: Int?
    let estimatedWait: Int?
}

struct ForecastEntry: Codable, Identifiable, Equatable, Hashable {
    let time: String
    let waitTime: Int
    let percentage: Int

    var id: String { time }
}

struct TimePeriod: Codable, Identifiable, Equatable, Hashable {
    let type: String?
    let startTime: String?
    let endTime: String?

    var id: String { "\(type ?? "")-\(startTime ?? "")" }
}

// MARK: - Schedule

struct ScheduleResponse: Codable {
    let id: String
    let name: String
    let schedule: [ScheduleEntry]
}

struct ScheduleEntry: Codable, Identifiable, Equatable {
    let date: String
    let type: ScheduleType
    let openingTime: String?
    let closingTime: String?
    let description: String?

    var id: String { "\(date)-\(type.rawValue)-\(description ?? "")" }
}

// MARK: - Children (Locations)

struct ChildrenResponse: Codable {
    let id: String
    let name: String
    let children: [ChildEntity]
}

struct ChildEntity: Codable, Identifiable {
    let id: String
    let name: String
    let entityType: EntityType
    let slug: String?
    let parentId: String?
    let externalId: String?
    let location: EntityLocation?
}

struct EntityLocation: Codable, Equatable {
    let latitude: Double
    let longitude: Double
}

// MARK: - Entity Details

struct EntityDetails: Codable {
    let id: String
    let name: String
    let timezone: String?
    let location: EntityLocation?
}

// MARK: - Destinations

struct DestinationsResponse: Codable {
    let destinations: [Destination]
}

struct Destination: Codable, Identifiable {
    let id: String
    let name: String
    let slug: String?
    let parks: [DestinationPark]
}

struct DestinationPark: Codable, Identifiable {
    let id: String
    let name: String
}

// MARK: - LiveEntity Helpers

extension LiveEntity {
    var isOpen: Bool { status == .operating }
    var isDown: Bool { status == .down }
    var isRefurbishment: Bool { status == .refurbishment }
    var waitTime: Int? { queue?.standby?.waitTime }
    var singleRiderWait: Int? { queue?.singleRider?.waitTime }
    var isAttraction: Bool { entityType == .attraction }
    var isShow: Bool { entityType == .show }

    var lightningLanePrice: String? {
        queue?.paidReturnTime?.price?.formatted
    }

    var lightningLaneAvailable: Bool {
        queue?.paidReturnTime?.state == .available
    }

    var returnTimeAvailable: Bool {
        queue?.returnTime?.state == .available
    }

    var lastUpdatedDate: Date? {
        lastUpdated.flatMap { PTFormat.parseISO($0) }
    }

    /// The next showtime that hasn't started yet, relative to `now`.
    func nextShowtime(after now: Date = Date()) -> Date? {
        showtimes?
            .compactMap { $0.startTime?.toDate() }
            .filter { $0 > now }
            .min()
    }
}

// MARK: - Sections

enum RideSortOrder: String, CaseIterable, Identifiable {
    case wait = "Longest Wait"
    case name = "A to Z"
    case lightningLane = "Lightning Lane Price"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .wait: return "clock"
        case .name: return "textformat.abc"
        case .lightningLane: return "bolt"
        }
    }
}

/// One-pass bucketing of a park's live entities into displayable sections plus
/// summary stats. Stats always reflect the full entity list; sections respect search.
struct RideSections {
    var favorites: [LiveEntity] = []
    var open: [LiveEntity] = []
    var shows: [LiveEntity] = []
    var down: [LiveEntity] = []
    var closed: [LiveEntity] = []
    var refurbishment: [LiveEntity] = []
    var openCount = 0
    var totalAttractions = 0
    var avgWait = 0
    var maxWait = 0

    var isEmpty: Bool {
        favorites.isEmpty && open.isEmpty && shows.isEmpty && down.isEmpty && closed.isEmpty && refurbishment.isEmpty
    }

    static func build(
        entities: [LiveEntity],
        search: String = "",
        favoriteIds: Set<String> = [],
        sort: RideSortOrder = .wait
    ) -> RideSections {
        var sections = RideSections()
        var waitSum = 0
        var waitCount = 0

        for entity in entities {
            if entity.isAttraction {
                sections.totalAttractions += 1
                if entity.isOpen {
                    sections.openCount += 1
                    if let wait = entity.waitTime, wait > 0 {
                        waitSum += wait
                        waitCount += 1
                        sections.maxWait = max(sections.maxWait, wait)
                    }
                }
            }

            guard search.isEmpty || entity.name.localizedCaseInsensitiveContains(search) else { continue }
            guard entity.isAttraction || entity.isShow else { continue }

            if favoriteIds.contains(entity.id) {
                sections.favorites.append(entity)
            }

            if entity.isShow {
                sections.shows.append(entity)
            } else if entity.isOpen {
                sections.open.append(entity)
            } else if entity.isDown {
                sections.down.append(entity)
            } else if entity.isRefurbishment {
                sections.refurbishment.append(entity)
            } else {
                sections.closed.append(entity)
            }
        }

        if waitCount > 0 { sections.avgWait = waitSum / waitCount }

        switch sort {
        case .wait:
            sections.open.sort { ($0.waitTime ?? 0) > ($1.waitTime ?? 0) }
        case .name:
            sections.open.sort { $0.name < $1.name }
        case .lightningLane:
            sections.open.sort { ($0.queue?.paidReturnTime?.price?.amount ?? -1) > ($1.queue?.paidReturnTime?.price?.amount ?? -1) }
        }
        sections.favorites.sort { ($0.waitTime ?? 0) > ($1.waitTime ?? 0) }
        sections.shows.sort { $0.name < $1.name }
        sections.down.sort { $0.name < $1.name }
        sections.closed.sort { $0.name < $1.name }
        sections.refurbishment.sort { $0.name < $1.name }

        return sections
    }
}

struct LandGroup: Identifiable {
    let name: String
    let rides: [LiveEntity]

    var id: String { name }

    /// Groups attractions and shows by the land they belong to, open rides first
    /// (sorted by wait), then everything else alphabetically.
    static func build(
        entities: [LiveEntity],
        search: String = "",
        landNameById: [String: String]
    ) -> [LandGroup] {
        var buckets: [String: [LiveEntity]] = [:]
        for entity in entities where entity.isAttraction || entity.isShow {
            guard search.isEmpty || entity.name.localizedCaseInsensitiveContains(search) else { continue }
            let land = landNameById[entity.id] ?? "Elsewhere in the Park"
            buckets[land, default: []].append(entity)
        }

        return buckets
            .map { name, rides in
                let sorted = rides.sorted { a, b in
                    if a.isOpen != b.isOpen { return a.isOpen }
                    if a.isOpen { return (a.waitTime ?? 0) > (b.waitTime ?? 0) }
                    return a.name < b.name
                }
                return LandGroup(name: name, rides: sorted)
            }
            .sorted { $0.name < $1.name }
    }
}

// MARK: - Park Live Summary

struct ParkLiveSummary: Equatable {
    let openCount: Int
    let avgWait: Int

    static func from(entities: [LiveEntity]) -> ParkLiveSummary {
        let sections = RideSections.build(entities: entities)
        return ParkLiveSummary(openCount: sections.openCount, avgWait: sections.avgWait)
    }
}

// MARK: - Park Hours

/// Interprets a park's schedule for "today" in the park's own timezone.
struct ParkHoursInfo {
    let operating: ScheduleEntry?
    let earlyEntry: ScheduleEntry?
    let ticketedEvents: [ScheduleEntry]

    enum OpenState {
        case openNow(closes: Date)
        case opensLater(opens: Date)
        case closedToday
        case unknown
    }

    static func today(schedule: [ScheduleEntry], timezone: TimeZone, now: Date = Date()) -> ParkHoursInfo {
        let day = PTFormat.dayString(for: now, in: timezone)
        let todays = schedule.filter { $0.date == day }
        return ParkHoursInfo(
            operating: todays.first { $0.type == .operating },
            earlyEntry: todays.first { $0.type == .extraHours || $0.description == "Early Entry" },
            ticketedEvents: todays.filter { $0.type == .ticketedEvent }
        )
    }

    func openState(now: Date = Date()) -> OpenState {
        guard let operating,
              let open = operating.openingTime?.toDate(),
              let close = operating.closingTime?.toDate() else {
            return operating == nil ? .closedToday : .unknown
        }
        if now < open { return .opensLater(opens: open) }
        if now < close { return .openNow(closes: close) }
        return .closedToday
    }
}

// MARK: - Time Formatting

enum PTFormat {
    static let iso: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static let isoFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let relative: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    static func parseISO(_ string: String) -> Date? {
        iso.date(from: string) ?? isoFractional.date(from: string)
    }

    /// "9:00 AM" style, in the given timezone (locale-aware).
    static func time(_ date: Date, in timezone: TimeZone?) -> String {
        var style = Date.FormatStyle.dateTime.hour().minute()
        style.timeZone = timezone ?? .current
        return date.formatted(style)
    }

    /// "yyyy-MM-dd" for the given instant as seen in the given timezone —
    /// matches the API's schedule `date` strings.
    static func dayString(for date: Date, in timezone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezone
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}

extension String {
    func toDate() -> Date? {
        PTFormat.parseISO(self)
    }

    /// Formats an ISO timestamp as a clock time in the given timezone
    /// (falls back to the raw string if unparseable).
    func toTime(in timezone: TimeZone?) -> String {
        guard let date = toDate() else { return self }
        return PTFormat.time(date, in: timezone)
    }
}

// MARK: - Errors

enum PTError: LocalizedError {
    case invalidUrl
    case invalidResponse(statusCode: Int?)
    case decoding(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidUrl:
            return "That request couldn't be built."
        case .invalidResponse(let code):
            if let code { return "The server responded with an error (\(code))." }
            return "The server response couldn't be read."
        case .decoding(let underlying):
            return "The park data couldn't be read. (\(underlying.localizedDescription))"
        }
    }
}
