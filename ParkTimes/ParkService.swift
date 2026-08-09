//
//  ParkService.swift
//  ParkTimes
//

import Foundation

struct ParkService {

    private static let baseURL = "https://api.themeparks.wiki/v1"

    private static let decoder = JSONDecoder()

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.urlCache = URLCache(memoryCapacity: 4_000_000, diskCapacity: 32_000_000)
        config.requestCachePolicy = .useProtocolCachePolicy
        return URLSession(configuration: config)
    }()

    static func fetch<T: Decodable>(_ type: T.Type, path: String) async throws -> T {
        guard let url = URL(string: "\(baseURL)/\(path)") else {
            throw PTError.invalidUrl
        }

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw PTError.invalidResponse(statusCode: nil)
        }
        guard http.statusCode == 200 else {
            throw PTError.invalidResponse(statusCode: http.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw PTError.decoding(underlying: error)
        }
    }

    static func getLiveData(parkId: String) async throws -> [LiveEntity] {
        try await fetch(LiveDataResponse.self, path: "entity/\(parkId)/live").liveData
    }

    static func getSchedule(parkId: String) async throws -> [ScheduleEntry] {
        try await fetch(ScheduleResponse.self, path: "entity/\(parkId)/schedule").schedule
    }

    static func getChildren(parkId: String) async throws -> [ChildEntity] {
        try await fetch(ChildrenResponse.self, path: "entity/\(parkId)/children").children
    }

    static func getEntity(id: String) async throws -> EntityDetails {
        try await fetch(EntityDetails.self, path: "entity/\(id)")
    }

    static func getDestinations() async throws -> [Destination] {
        try await fetch(DestinationsResponse.self, path: "destinations").destinations
    }
}
