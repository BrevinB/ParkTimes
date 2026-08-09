//
//  RestroomService.swift
//  ParkTimes
//
//  Restroom locations come from OpenStreetMap (amenity=toilets), where park
//  interiors are mapped far more accurately than commercial POI databases.
//  Results are cached for 30 days per park — restrooms don't move often.
//
//  Data © OpenStreetMap contributors (ODbL) — attributed in the map UI
//  and About screen.
//

import Foundation

enum RestroomService {

    struct Restroom: Codable, Identifiable {
        let id: Int
        let latitude: Double
        let longitude: Double
    }

    private struct OverpassResponse: Codable {
        let elements: [Element]

        struct Element: Codable {
            let id: Int
            let lat: Double?
            let lon: Double?
            let center: Center?
        }

        struct Center: Codable {
            let lat: Double
            let lon: Double
        }
    }

    private struct CacheEntry: Codable {
        let fetched: Date
        let restrooms: [Restroom]
    }

    private static let mirrors = [
        "https://overpass-api.de/api/interpreter",
        "https://overpass.kumi.systems/api/interpreter",
    ]

    private static let cacheLifetime: TimeInterval = 30 * 24 * 3600

    /// Fetches restrooms inside a bounding box, with a per-park cache.
    static func restrooms(
        south: Double, west: Double, north: Double, east: Double,
        cacheKey: String
    ) async -> [Restroom] {
        let key = "restrooms.v1.\(cacheKey)"
        if let data = UserDefaults.standard.data(forKey: key),
           let cached = try? JSONDecoder().decode(CacheEntry.self, from: data),
           Date().timeIntervalSince(cached.fetched) < cacheLifetime,
           !cached.restrooms.isEmpty {
            return cached.restrooms
        }

        let query = "[out:json][timeout:20];nwr[\"amenity\"=\"toilets\"](\(south),\(west),\(north),\(east));out center;"

        for mirror in mirrors {
            guard let url = URL(string: mirror) else { continue }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = "data=\(query.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? query)"
                .data(using: .utf8)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 20

            guard let (data, response) = try? await URLSession.shared.data(for: request),
                  (response as? HTTPURLResponse)?.statusCode == 200,
                  let decoded = try? JSONDecoder().decode(OverpassResponse.self, from: data) else {
                continue
            }

            let restrooms = dedupe(decoded.elements.compactMap { element -> Restroom? in
                let lat = element.lat ?? element.center?.lat
                let lon = element.lon ?? element.center?.lon
                guard let lat, let lon else { return nil }
                return Restroom(id: element.id, latitude: lat, longitude: lon)
            })

            if !restrooms.isEmpty {
                let entry = CacheEntry(fetched: Date(), restrooms: restrooms)
                UserDefaults.standard.set(try? JSONEncoder().encode(entry), forKey: key)
            }
            return restrooms
        }

        return []
    }

    /// OSM often maps men's and women's rooms as separate nodes a few meters
    /// apart — collapse anything within ~20m into one pin.
    private static func dedupe(_ restrooms: [Restroom]) -> [Restroom] {
        var kept: [Restroom] = []
        for restroom in restrooms {
            let isDuplicate = kept.contains { other in
                let dLat = (other.latitude - restroom.latitude) * 111_000
                let dLon = (other.longitude - restroom.longitude) * 97_000
                return (dLat * dLat + dLon * dLon).squareRoot() < 20
            }
            if !isDuplicate {
                kept.append(restroom)
            }
        }
        return kept
    }
}
