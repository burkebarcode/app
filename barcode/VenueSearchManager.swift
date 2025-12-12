//
//  VenueSearchManager.swift
//  barcode
//
//  Created by Claude on 12/8/25.
//

import Foundation
import MapKit
import CoreLocation
import Combine

struct DiscoveredVenue: Identifiable, Equatable {
    let id: String
    let name: String
    let category: String
    let coordinate: CLLocationCoordinate2D
    let address: String?
    let distance: Double // meters
    let phoneNumber: String?
    let url: URL?

    static func == (lhs: DiscoveredVenue, rhs: DiscoveredVenue) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
class VenueSearchManager: ObservableObject {
    @Published var venues: [DiscoveredVenue] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var lastSearchLocation: CLLocation?
    private var cachedResults: [DiscoveredVenue] = []
    private var cacheTimestamp: Date?
    private let cacheExpirationInterval: TimeInterval = 300 // 5 minutes

    private let searchCategories = [
        "bar",
        "wine bar",
        "cocktail bar",
        "brewery",
        "pub",
        "nightlife",
        "restaurant"
    ]

    func searchNearby(location: CLLocation, drinkFilter: DrinkTypeFilter = .all) async {
        // Check if we can use cached results
        if let cached = getCachedResults(for: location, filter: drinkFilter) {
            self.venues = cached
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            var allResults: [DiscoveredVenue] = []

            // Search each category
            for category in searchCategories {
                let categoryResults = try await searchCategory(category, near: location)
                allResults.append(contentsOf: categoryResults)
            }

            // Deduplicate by name and proximity
            let deduped = deduplicateVenues(allResults)

            // Apply drink type filter
            let filtered = applyDrinkFilter(deduped, filter: drinkFilter)

            // Sort by distance
            let sorted = filtered.sorted { $0.distance < $1.distance }

            // Limit results
            let limited = Array(sorted.prefix(50))

            // Cache results
            cachedResults = limited
            cacheTimestamp = Date()
            lastSearchLocation = location

            self.venues = limited
        } catch {
            errorMessage = "Failed to search venues: \(error.localizedDescription)"
            print("Search error: \(error)")
        }

        isLoading = false
    }

    private func searchCategory(_ category: String, near location: CLLocation) async throws -> [DiscoveredVenue] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = category
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 2000,
            longitudinalMeters: 2000
        )

        let search = MKLocalSearch(request: request)
        let response = try await search.start()

        return response.mapItems.compactMap { mapItem -> DiscoveredVenue? in
            guard let name = mapItem.name else { return nil }

            let itemLocation = CLLocation(
                latitude: mapItem.placemark.coordinate.latitude,
                longitude: mapItem.placemark.coordinate.longitude
            )
            let distance = location.distance(from: itemLocation)

            // Create unique ID from coordinate
            let id = "\(mapItem.placemark.coordinate.latitude),\(mapItem.placemark.coordinate.longitude)"

            let address = formatAddress(mapItem.placemark)
            let category = mapItem.pointOfInterestCategory?.rawValue ?? "Venue"

            return DiscoveredVenue(
                id: id,
                name: name,
                category: formatCategory(category),
                coordinate: mapItem.placemark.coordinate,
                address: address,
                distance: distance,
                phoneNumber: mapItem.phoneNumber,
                url: mapItem.url
            )
        }
    }

    private func deduplicateVenues(_ venues: [DiscoveredVenue]) -> [DiscoveredVenue] {
        var seen = Set<String>()
        return venues.filter { venue in
            let key = venue.id
            if seen.contains(key) {
                return false
            }
            seen.insert(key)
            return true
        }
    }

    private func applyDrinkFilter(_ venues: [DiscoveredVenue], filter: DrinkTypeFilter) -> [DiscoveredVenue] {
        switch filter {
        case .all:
            return venues
        case .wine:
            return venues.filter { venue in
                venue.category.lowercased().contains("wine") ||
                venue.name.lowercased().contains("wine")
            }
        case .beer:
            return venues.filter { venue in
                venue.category.lowercased().contains("brew") ||
                venue.category.lowercased().contains("pub") ||
                venue.category.lowercased().contains("beer") ||
                venue.name.lowercased().contains("brew") ||
                venue.name.lowercased().contains("beer")
            }
        case .cocktails:
            return venues.filter { venue in
                venue.category.lowercased().contains("cocktail") ||
                venue.category.lowercased().contains("lounge") ||
                venue.category.lowercased().contains("nightlife") ||
                venue.name.lowercased().contains("cocktail")
            }
        case .nonAlcoholic:
            return venues.filter { venue in
                venue.category.lowercased().contains("cafe") ||
                venue.category.lowercased().contains("coffee") ||
                venue.category.lowercased().contains("juice") ||
                venue.name.lowercased().contains("cafe") ||
                venue.name.lowercased().contains("coffee")
            }
        }
    }

    private func getCachedResults(for location: CLLocation, filter: DrinkTypeFilter) -> [DiscoveredVenue]? {
        guard let lastLocation = lastSearchLocation,
              let cacheTime = cacheTimestamp else {
            return nil
        }

        // Check if cache is expired
        if Date().timeIntervalSince(cacheTime) > cacheExpirationInterval {
            return nil
        }

        // Check if location hasn't changed significantly (within 500m)
        if lastLocation.distance(from: location) < 500 {
            return applyDrinkFilter(cachedResults, filter: filter)
        }

        return nil
    }

    private func formatAddress(_ placemark: MKPlacemark) -> String? {
        var components: [String] = []

        if let street = placemark.thoroughfare {
            components.append(street)
        }
        if let city = placemark.locality {
            components.append(city)
        }

        return components.isEmpty ? nil : components.joined(separator: ", ")
    }

    private func formatCategory(_ category: String) -> String {
        // Clean up category names
        let cleaned = category.replacingOccurrences(of: "MKPOICategory", with: "")
        return cleaned.capitalized
    }
}
