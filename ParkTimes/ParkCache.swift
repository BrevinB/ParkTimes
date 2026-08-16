//
//  ParkCache.swift
//  ParkTimes
//
//  Last-known-good snapshot of each park's data, persisted to the caches
//  directory. Cell service inside parks is unreliable — a cold launch shows
//  the cached waits instantly (honestly aged by the "updated X ago" line)
//  while the network refresh runs.
//

import Foundation

enum ParkCache {

    struct Snapshot: Codable {
        let fetched: Date
        let entities: [LiveEntity]
        let schedule: [ScheduleEntry]
        let locations: [String: EntityLocation]
        let landNameById: [String: String]
        let timezoneId: String?
    }

    private static var directory: URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ParkCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    private static func fileURL(for parkId: String) -> URL {
        directory.appendingPathComponent("\(parkId).json")
    }

    static func load(parkId: String) -> Snapshot? {
        guard let data = try? Data(contentsOf: fileURL(for: parkId)) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }

    static func save(_ snapshot: Snapshot, parkId: String) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL(for: parkId), options: .atomic)
    }

    static func remove(parkId: String) {
        try? FileManager.default.removeItem(at: fileURL(for: parkId))
    }
}
