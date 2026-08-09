//
//  ParkActivityAttributes.swift
//  ParkTimes
//
//  Shared between the app (starts/updates the activity) and the widget
//  extension (renders it).
//

import Foundation
#if canImport(ActivityKit)
import ActivityKit

struct ParkActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var rides: [RideWait]
        var updated: Date
    }

    struct RideWait: Codable, Hashable, Identifiable {
        var id: String
        var name: String
        var wait: Int?
        var isOpen: Bool
    }

    var parkId: String
    var parkName: String
}
#endif
