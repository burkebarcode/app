//
//  VenuesManager.swift
//  barcode
//
//  Created by Claude on 12/4/25.
//

import Foundation
import Combine

@MainActor
class VenuesManager: ObservableObject {
    @Published var venues: [VenueResponse] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    func fetchVenues() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedVenues = try await apiService.getVenues(limit: 100)
            self.venues = fetchedVenues
        } catch {
            self.errorMessage = "Failed to load venues: \(error.localizedDescription)"
            print("Error fetching venues: \(error)")
        }

        isLoading = false
    }

    func searchVenues(query: String) async {
        guard !query.isEmpty else {
            await fetchVenues()
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let results = try await apiService.searchVenues(query: query)
            self.venues = results
        } catch {
            self.errorMessage = "Failed to search venues: \(error.localizedDescription)"
            print("Error searching venues: \(error)")
        }

        isLoading = false
    }

    func createVenue(
        name: String,
        description: String,
        venueType: String,
        address: String?,
        city: String?,
        state: String?,
        country: String?,
        lat: Double?,
        lng: Double?,
        hasBeer: Bool,
        hasWine: Bool,
        hasCocktails: Bool
    ) async -> VenueResponse? {
        isLoading = true
        errorMessage = nil

        do {
            let newVenue = try await apiService.createVenue(
                name: name,
                description: description,
                venueType: venueType,
                address: address,
                city: city,
                state: state,
                country: country,
                lat: lat,
                lng: lng,
                hasBeer: hasBeer,
                hasWine: hasWine,
                hasCocktails: hasCocktails
            )

            // Add to the beginning of the list
            self.venues.insert(newVenue, at: 0)
            isLoading = false
            return newVenue
        } catch {
            self.errorMessage = "Failed to create venue: \(error.localizedDescription)"
            print("Error creating venue: \(error)")
            isLoading = false
            return nil
        }
    }

    // Helper to convert VenueResponse to local Venue model
    func toVenue(_ response: VenueResponse) -> Venue {
        let venueType: VenueType
        switch response.venueType.lowercased() {
        case "bar":
            venueType = .bar
        case "restaurant":
            venueType = .restaurant
        default:
            venueType = .other
        }

        return Venue(
            id: UUID(uuidString: response.id) ?? UUID(),
            name: response.name,
            type: venueType,
            city: response.city ?? "",
            address: response.address,
            imageURL: nil,
            hasBeer: response.hasBeer == 1,
            hasWine: response.hasWine == 1,
            hasCocktails: response.hasCocktails == 1,
            isOfficial: true,
            createdByUserId: nil
        )
    }
}
