//
//  Models.swift
//  ParkTimes
//

import Foundation

struct ParkModel: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
}

struct LandModel: Codable, Identifiable {
    let id: Int?
    let name: String?
    let rides: [RideModel]?
}

struct RideModel: Codable, Identifiable {
    let id: Int?
    let name: String?
    let isOpen: Bool?
    let waitTime: Int?
    let lastUpdated: String?
}

struct LandsAndRides: Codable {
    let lands: [LandModel]
    let rides: [RideModel]
}

enum PTError: Error {
    case invalidUrl
    case invalidResponse
    case invalidData
}
