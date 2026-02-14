//
//  Models.swift
//  ParkTimes
//

import Foundation

struct ParkModel: Identifiable, Hashable {
    let id: String
    let name: String
}

struct LiveDataResponse: Codable {
    let id: String
    let name: String
    let liveData: [LiveEntity]
}

struct LiveEntity: Codable, Identifiable {
    let id: String
    let name: String
    let entityType: String
    let status: String?
    let lastUpdated: String?
    let queue: QueueData?
}

struct QueueData: Codable {
    let STANDBY: StandbyQueue?
}

struct StandbyQueue: Codable {
    let waitTime: Int?
}

extension LiveEntity {
    var isOpen: Bool {
        status == "OPERATING"
    }

    var waitTime: Int? {
        queue?.STANDBY?.waitTime
    }

    var isAttraction: Bool {
        entityType == "ATTRACTION"
    }
}

enum PTError: Error {
    case invalidUrl
    case invalidResponse
    case invalidData
}
