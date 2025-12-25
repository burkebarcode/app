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

    // Pre-filled beverage data from scan
    @Published var prefilledDrinkName: String?
    @Published var prefilledCategory: DrinkCategory?
    @Published var prefilledVarietal: String?
    @Published var prefilledWineStyle: WineStyle?
    @Published var prefilledVintage: String?
    @Published var prefilledRegion: String?

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
        prefilledDrinkName = nil
        prefilledCategory = nil
        prefilledVarietal = nil
        prefilledWineStyle = nil
        prefilledVintage = nil
        prefilledRegion = nil
    }

    func navigateToDrinkCollection(_ collection: DrinkCollection) {
        navigateToCollection = collection
    }

    func resetNavigationState() {
        navigateToCollection = nil
    }
}
