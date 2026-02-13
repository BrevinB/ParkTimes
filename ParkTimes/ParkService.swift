//
//  ParkService.swift
//  ParkTimes
//

import Foundation

struct ParkService {

    static func getPark(parkId: Int) async throws -> ParkModel {
        let endpoint = "https://queue-times.com/en-US/parks/\(parkId).json"

        guard let url = URL(string: endpoint) else {
            throw PTError.invalidUrl
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw PTError.invalidResponse
        }

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(ParkModel.self, from: data)
        } catch {
            throw PTError.invalidData
        }
    }

    static func getRides(parkId: Int) async throws -> LandsAndRides {
        let endpoint = "https://queue-times.com/en-US/parks/\(parkId)/queue_times.json"

        guard let url = URL(string: endpoint) else {
            throw PTError.invalidUrl
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw PTError.invalidResponse
        }

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(LandsAndRides.self, from: data)
        } catch {
            throw PTError.invalidData
        }
    }
}
