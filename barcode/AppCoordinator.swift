//
//  AppCoordinator.swift
//  barcode
//
//  Created by Claude on 12/8/25.
//

import SwiftUI
import Combine

@MainActor
class AppCoordinator: ObservableObject {
    @Published var selectedTab: Int = 1 // Start on My Log tab
    @Published var shouldOpenAddRating: Bool = false
    @Published var preselectedVenue: Venue?
    @Published var preselectedVenueFromDiscovery: DiscoveredVenue?
    @Published var navigateToCollection: DrinkCollection?

    func logDrinkAtVenue(_ venue: DiscoveredVenue) {
        // Convert DiscoveredVenue to Venue
        let mappedVenue = Venue(
            id: UUID(), // Temporary ID
            name: venue.name,
            type: .bar, // Default type
            city: venue.address ?? "",
            imageURL: nil
        )

        preselectedVenue = mappedVenue
        preselectedVenueFromDiscovery = venue
        selectedTab = 1 // Switch to My Log tab
        shouldOpenAddRating = true
    }

    func resetAddRatingState() {
        shouldOpenAddRating = false
        preselectedVenue = nil
        preselectedVenueFromDiscovery = nil
    }

    func navigateToDrinkCollection(_ collection: DrinkCollection) {
        navigateToCollection = collection
    }

    func resetNavigationState() {
        navigateToCollection = nil
    }
}
