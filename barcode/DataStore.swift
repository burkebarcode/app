//
//  DataStore.swift
//  barcode
//
//  Created by Burke Butler on 11/18/25.
//

import Foundation
import Combine

class DataStore: ObservableObject {
    @Published var venues: [Venue] = []
    @Published var ratings: [Rating] = []
    @Published var users: [User] = []
    @Published var feedPosts: [FeedPost] = []

    private let apiService = APIService.shared

    init() {
        // Remove mock data - will load from API
    }

    private func loadMockDataOLD() {
        // Create venues with detailed information
        let littleFox = Venue(
            name: "Little Fox Bar",
            type: .bar,
            city: "New York",
            address: "123 Broadway, Manhattan",
            imageURL: "https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=800",
            hasBeer: true,
            hasWine: false,
            hasCocktails: true
        )

        let romaTrattoria = Venue(
            name: "Roma Trattoria",
            type: .restaurant,
            city: "New York",
            address: "456 5th Ave, Manhattan",
            imageURL: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800",
            hasBeer: false,
            hasWine: true,
            hasCocktails: false
        )

        let theVineyard = Venue(
            name: "The Vineyard",
            type: .bar,
            city: "New York",
            address: "789 Park Ave, Manhattan",
            imageURL: "https://images.unsplash.com/photo-1572116469696-31de0f17cc34?w=800",
            hasBeer: true,
            hasWine: true,
            hasCocktails: true
        )

        let craftHouse = Venue(
            name: "Craft House",
            type: .restaurant,
            city: "New York",
            address: "321 Madison Ave, Manhattan",
            imageURL: "https://images.unsplash.com/photo-1544025162-d76694265947?w=800",
            hasBeer: true,
            hasWine: true,
            hasCocktails: false
        )

        let brooklynBrewery = Venue(
            name: "Brooklyn Brewery Taproom",
            type: .bar,
            city: "Brooklyn",
            address: "79 N 11th St, Brooklyn",
            imageURL: "https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=800",
            hasBeer: true,
            hasWine: false,
            hasCocktails: false
        )

        let speakeasyLounge = Venue(
            name: "The Speakeasy Lounge",
            type: .bar,
            city: "New York",
            address: "555 W 23rd St, Manhattan",
            imageURL: "https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=800",
            hasBeer: false,
            hasWine: true,
            hasCocktails: true
        )

        let gastropub = Venue(
            name: "The Gastropub",
            type: .restaurant,
            city: "Queens",
            address: "88 Steinway St, Queens",
            imageURL: "https://images.unsplash.com/photo-1533777324565-a040eb52facd?w=800",
            hasBeer: true,
            hasWine: true,
            hasCocktails: true
        )

        let wineBar = Venue(
            name: "Vino & Co",
            type: .bar,
            city: "New York",
            address: "222 Lafayette St, Manhattan",
            imageURL: "https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=800",
            hasBeer: false,
            hasWine: true,
            hasCocktails: false
        )

        venues = [littleFox, romaTrattoria, theVineyard, craftHouse, brooklynBrewery, speakeasyLounge, gastropub, wineBar]

        // Create ratings
        ratings = [
            Rating(
                venueId: littleFox.id,
                drinkName: "Negroni",
                category: .cocktail,
                stars: 5,
                notes: "Perfectly balanced, great gin",
                dateLogged: Date().addingTimeInterval(-2 * 24 * 60 * 60),
                photoNames: ["sampleDrink1", "sampleDrink2"],
                tags: ["test1", "test2"],
            ),
            Rating(
                venueId: littleFox.id,
                drinkName: "IPA House Blend",
                category: .beer,
                stars: 4,
                notes: "Hoppy and refreshing",
                dateLogged: Date().addingTimeInterval(-2 * 24 * 60 * 60 - 3600)
            ),
            Rating(
                venueId: romaTrattoria.id,
                drinkName: "Chianti Classico",
                
                category: .wine,
                stars: 5,
                notes: "Excellent pairing with pasta, smooth finish",
                dateLogged: Date().addingTimeInterval(-5 * 24 * 60 * 60)
            ),
            Rating(
                venueId: theVineyard.id,
                drinkName: "Pinot Noir",
                category: .wine,
                stars: 4,
                notes: "Light bodied, cherry notes",
                dateLogged: Date().addingTimeInterval(-7 * 24 * 60 * 60)
            ),
            Rating(
                venueId: craftHouse.id,
                drinkName: "Old Fashioned",
                category: .cocktail,
                stars: 5,
                notes: "Classic preparation, orange peel twist",
                dateLogged: Date().addingTimeInterval(-10 * 24 * 60 * 60)
            ),
            Rating(
                venueId: craftHouse.id,
                drinkName: "Local Amber Ale",
                category: .beer,
                stars: 3,
                notes: "Decent, a bit too malty for my taste",
                dateLogged: Date().addingTimeInterval(-10 * 24 * 60 * 60 - 1800)
            )
        ]

        // Create users
        let sarah = User(username: "sarah_drinks", displayName: "Sarah Chen", avatarURL: "https://i.pravatar.cc/150?img=1")
        let mike = User(username: "mike_barfly", displayName: "Mike Johnson", avatarURL: "https://i.pravatar.cc/150?img=12")
        let emma = User(username: "emma_vino", displayName: "Emma Rodriguez", avatarURL: "https://i.pravatar.cc/150?img=5")
        let james = User(username: "james_mixology", displayName: "James Williams", avatarURL: "https://i.pravatar.cc/150?img=13")
        let olivia = User(username: "olivia_craft", displayName: "Olivia Martinez", avatarURL: "https://i.pravatar.cc/150?img=9")

        users = [sarah, mike, emma, james, olivia]

        // Create feed posts
        feedPosts = [
            FeedPost(
                userId: sarah.id,
                venueId: littleFox.id,
                drinkName: "Espresso Martini",
                category: .cocktail,
                stars: 5,
                notes: "Best espresso martini I've ever had! Perfectly balanced and smooth.",
                photoURL: "https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=800",
                datePosted: Date().addingTimeInterval(-2 * 3600),
                likedBy: [mike.id, emma.id, james.id],
                comments: [
                    Comment(userId: mike.id, text: "Need to try this place!", datePosted: Date().addingTimeInterval(-1.5 * 3600)),
                    Comment(userId: emma.id, text: "Their espresso martinis are legendary 🔥", datePosted: Date().addingTimeInterval(-1 * 3600))
                ]
            ),
            FeedPost(
                userId: mike.id,
                venueId: brooklynBrewery.id,
                drinkName: "Brooklyn Lager",
                category: .beer,
                stars: 4,
                notes: "Classic NYC beer. Great atmosphere at the taproom too!",
                photoURL: "https://images.unsplash.com/photo-1608270586620-248524c67de9?w=800",
                datePosted: Date().addingTimeInterval(-5 * 3600),
                likedBy: [sarah.id, olivia.id],
                comments: [
                    Comment(userId: sarah.id, text: "Love this brewery!", datePosted: Date().addingTimeInterval(-4 * 3600))
                ]
            ),
            FeedPost(
                userId: emma.id,
                venueId: wineBar.id,
                drinkName: "Pinot Grigio",
                category: .wine,
                stars: 5,
                notes: "Crisp and refreshing! Perfect for a Friday evening with friends.",
                photoURL: "https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=800",
                datePosted: Date().addingTimeInterval(-8 * 3600),
                likedBy: [sarah.id, james.id, olivia.id, mike.id]
            ),
            FeedPost(
                userId: james.id,
                venueId: speakeasyLounge.id,
                drinkName: "Old Fashioned",
                category: .cocktail,
                stars: 5,
                notes: "Traditional recipe with a modern twist. The bourbon selection here is incredible.",
                photoURL: "https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=800",
                datePosted: Date().addingTimeInterval(-12 * 3600)
            ),
            FeedPost(
                userId: olivia.id,
                venueId: craftHouse.id,
                drinkName: "IPA Flight",
                category: .beer,
                stars: 4,
                notes: "Tried 4 different IPAs - the hazy IPA was my favorite!",
                photoURL: "https://images.unsplash.com/photo-1535958636474-b021ee887b13?w=800",
                datePosted: Date().addingTimeInterval(-18 * 3600)
            ),
            FeedPost(
                userId: sarah.id,
                venueId: theVineyard.id,
                drinkName: "Chardonnay",
                category: .wine,
                stars: 4,
                notes: "Nice and oaky, pairs well with their cheese board.",
                datePosted: Date().addingTimeInterval(-24 * 3600)
            ),
            FeedPost(
                userId: mike.id,
                venueId: gastropub.id,
                drinkName: "Negroni",
                category: .cocktail,
                stars: 5,
                notes: "Bitter, boozy, and beautiful. Exactly how it should be!",
                photoURL: "https://images.unsplash.com/photo-1551538827-9c037cb4f32a?w=800",
                datePosted: Date().addingTimeInterval(-30 * 3600)
            )
        ]
    }

    func addRating(venueName: String, venueType: VenueType, drinkName: String, category: DrinkCategory, stars: Int, notes: String) {
        // Find or create venue
        let venue: Venue
        if let existing = venues.first(where: { $0.name.lowercased() == venueName.lowercased() }) {
            venue = existing
        } else {
            venue = Venue(name: venueName, type: venueType, city: "New York")
            venues.append(venue)
        }

        // Create rating
        let rating = Rating(
            venueId: venue.id,
            drinkName: drinkName,
            category: category,
            stars: stars,
            notes: notes
        )
        ratings.insert(rating, at: 0) // Add to beginning for most recent first
    }

    func getRatings(for venue: Venue) -> [Rating] {
        ratings.filter { $0.venueId == venue.id }
            .sorted { $0.dateLogged > $1.dateLogged }
    }

    func getVenue(for rating: Rating) -> Venue? {
        venues.first { $0.id == rating.venueId }
    }

    func filteredVenues(by type: VenueType?) -> [Venue] {
        guard let type = type else { return venues }
        return venues.filter { $0.type == type }
    }

    // Get official venues for global search/browse
    func getOfficialVenues() -> [Venue] {
        venues.filter { $0.isOfficial }
    }

    // Get venues visible to a specific user (official + their own user-created)
    func getVisibleVenues(for userId: UUID) -> [Venue] {
        venues.filter { venue in
            venue.isOfficial || venue.createdByUserId == userId
        }
    }

    // Search official venues
    func searchOfficialVenues(query: String) -> [Venue] {
        guard !query.isEmpty else { return getOfficialVenues() }
        return getOfficialVenues().filter { venue in
            venue.name.localizedCaseInsensitiveContains(query) ||
            venue.city.localizedCaseInsensitiveContains(query) ||
            venue.address?.localizedCaseInsensitiveContains(query) ?? false
        }
    }

    // Add user-created venue
    func addUserVenue(name: String, type: VenueType, city: String, address: String?, userId: UUID) -> Venue {
        let venue = Venue(
            name: name,
            type: type,
            city: city,
            address: address,
            isOfficial: false,
            createdByUserId: userId
        )
        venues.append(venue)
        return venue
    }

    // Promote user venue to official (admin action)
    func promoteVenueToOfficial(venueId: UUID) {
        if let index = venues.firstIndex(where: { $0.id == venueId }) {
            venues[index].isOfficial = true
            venues[index].createdByUserId = nil
        }
    }

    // Get user-created venues for admin review
    func getUserCreatedVenues() -> [Venue] {
        venues.filter { !$0.isOfficial }
    }

    func getUser(for userId: UUID) -> User? {
        users.first { $0.id == userId }
    }

    func getVenue(for venueId: UUID) -> Venue? {
        venues.first { $0.id == venueId }
    }

    func toggleLike(postId: UUID, userId: UUID) {
        if let index = feedPosts.firstIndex(where: { $0.id == postId }) {
            if feedPosts[index].likedBy.contains(userId) {
                feedPosts[index].likedBy.removeAll { $0 == userId }
            } else {
                feedPosts[index].likedBy.append(userId)
            }
        }
    }

    func addComment(postId: UUID, userId: UUID, text: String) {
        if let index = feedPosts.firstIndex(where: { $0.id == postId }) {
            let comment = Comment(userId: userId, text: text)
            feedPosts[index].comments.append(comment)
        }
    }
}
