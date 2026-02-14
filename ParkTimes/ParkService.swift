//
//  ParkService.swift
//  ParkTimes
//

import Foundation

struct ParkService {

    static func getLiveData(parkId: String) async throws -> [LiveEntity] {
        let endpoint = "https://api.themeparks.wiki/v1/entity/\(parkId)/live"

        guard let url = URL(string: endpoint) else {
            throw PTError.invalidUrl
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw PTError.invalidResponse
        }

        do {
            let decoded = try JSONDecoder().decode(LiveDataResponse.self, from: data)
            return decoded.liveData
        } catch {
            throw PTError.invalidData
        }
    }
}
