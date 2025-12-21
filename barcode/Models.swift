//
//  Models.swift
//  barcode
//
//  Created by Burke Butler on 11/18/25.
//

import Foundation

// Represents a unique drink with all its tastings
struct DrinkCollection: Identifiable {
    let id: String // Composite of name + category
    let name: String
    let category: DrinkCategory
    let tastings: [Rating] // All tasting instances

    var timesTried: Int {
        tastings.count
    }

    var averageRating: Double? {
        // Prefer score over stars
        let scores = tastings.compactMap { $0.score }
        if !scores.isEmpty {
            return scores.reduce(0, +) / Double(scores.count)
        }

        // Fallback to stars for backward compatibility (convert to 0-10 scale)
        let stars = tastings.compactMap { $0.stars }
        guard !stars.isEmpty else { return nil }
        return Double(stars.reduce(0, +)) * 2.0 / Double(stars.count) // Convert 1-5 stars to 0-10 scale
    }

    var lastTried: Date? {
        tastings.map { $0.dateLogged }.max()
    }

    var latestTasting: Rating? {
        tastings.sorted { $0.dateLogged > $1.dateLogged }.first
    }
}

struct User: Identifiable, Codable {
    let id: UUID
    var username: String
    var displayName: String
    var avatarURL: String?

    init(id: UUID = UUID(), username: String, displayName: String, avatarURL: String? = nil) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.avatarURL = avatarURL
    }
}

struct Comment: Identifiable, Codable {
    let id: UUID
    var userId: UUID
    var text: String
    var datePosted: Date

    init(id: UUID = UUID(), userId: UUID, text: String, datePosted: Date = Date()) {
        self.id = id
        self.userId = userId
        self.text = text
        self.datePosted = datePosted
    }

    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: datePosted, relativeTo: Date())
    }
}

struct FeedPost: Identifiable, Codable {
    let id: UUID
    var userId: UUID
    var venueId: UUID?
    var drinkName: String
    var category: DrinkCategory
    var stars: Int?
    var notes: String?
    var photoURL: String?
    var datePosted: Date
    var likedBy: [UUID]
    var comments: [Comment]

    init(
        id: UUID = UUID(),
        userId: UUID,
        venueId: UUID? = nil,
        drinkName: String,
        category: DrinkCategory,
        stars: Int? = nil,
        notes: String? = nil,
        photoURL: String? = nil,
        datePosted: Date = Date(),
        likedBy: [UUID] = [],
        comments: [Comment] = []
    ) {
        self.id = id
        self.userId = userId
        self.venueId = venueId
        self.drinkName = drinkName
        self.category = category
        self.stars = stars.map { min(max($0, 1), 5) }
        self.notes = notes
        self.photoURL = photoURL
        self.datePosted = datePosted
        self.likedBy = likedBy
        self.comments = comments
    }

    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: datePosted, relativeTo: Date())
    }

    var likeCount: Int {
        likedBy.count
    }

    var commentCount: Int {
        comments.count
    }
}

enum VenueType: String, CaseIterable, Codable {
    case bar = "Bar"
    case restaurant = "Restaurant"
    case other = "Other"
}

enum DrinkCategory: String, CaseIterable, Codable {
    case wine = "wine"
    case beer = "beer"
    case cocktail = "cocktail"
    case other = "other"
}

struct Venue: Identifiable, Codable {
    let id: UUID
    var name: String
    var type: VenueType
    var city: String
    var address: String?
    var imageURL: String?
    var hasBeer: Bool
    var hasWine: Bool
    var hasCocktails: Bool
    var isOfficial: Bool
    var createdByUserId: UUID?

    init(
        id: UUID = UUID(),
        name: String,
        type: VenueType,
        city: String,
        address: String? = nil,
        imageURL: String? = nil,
        hasBeer: Bool = false,
        hasWine: Bool = false,
        hasCocktails: Bool = false,
        isOfficial: Bool = true,
        createdByUserId: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.city = city
        self.address = address
        self.imageURL = imageURL
        self.hasBeer = hasBeer
        self.hasWine = hasWine
        self.hasCocktails = hasCocktails
        self.isOfficial = isOfficial
        self.createdByUserId = createdByUserId
    }
}

// Wine-specific details
struct WineDetails: Codable, Equatable {
    var varietal: String?
    var region: String?
    var vintage: String?
    var style: WineStyle?
    var sweetness: SweetnessLevel?
    var body: WineBody?
    var tannin: TastingLevel?
    var acidity: TastingLevel?
    var winery: String?
}

// Beer-specific details
struct BeerDetails: Codable, Equatable {
    var style: BeerStyle?
    var brewery: String?
    var abv: String?
    var ibu: String?
    var servingType: ServingType?
    var bitterness: FlavorLevel?
    var hoppiness: FlavorLevel?
    var maltiness: FlavorLevel?
    var mouthfeel: Mouthfeel?
}

// Cocktail-specific details
struct CocktailDetails: Codable, Equatable {
    var baseSpirit: BaseSpirit?
    var cocktailFamily: CocktailFamily?
    var preparationStyle: PreparationStyle?
    var glassType: GlassType?
    var garnish: String?
    var sweetness: BalanceLevel?
    var booziness: BalanceLevel?
    var balance: BalanceLevel?
    var recipeNotes: String?
}

enum WineStyle: String, CaseIterable, Codable {
    case red = "Red"
    case white = "White"
    case rose = "Rosé"
    case orange = "Orange"
    case sparkling = "Sparkling"
    case dessert = "Dessert"
}

enum SweetnessLevel: String, CaseIterable, Codable {
    case dry = "Dry"
    case offDry = "Off-Dry"
    case semiSweet = "Semi-Sweet"
    case sweet = "Sweet"
}

enum WineBody: String, CaseIterable, Codable {
    case light = "Light"
    case medium = "Medium"
    case full = "Full"
}

enum TastingLevel: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

enum BeerStyle: String, CaseIterable, Codable {
    case ipa = "IPA"
    case pale_ale = "Pale Ale"
    case lager = "Lager"
    case pilsner = "Pilsner"
    case stout = "Stout"
    case porter = "Porter"
    case sour = "Sour"
    case wheat = "Wheat Beer"
    case amber = "Amber Ale"
    case brown = "Brown Ale"
    case saison = "Saison"
    case belgian = "Belgian"
    case other = "Other"
}

enum ServingType: String, CaseIterable, Codable {
    case draft = "Draft"
    case can = "Can"
    case bottle = "Bottle"
    case flight = "Flight"
}

enum FlavorLevel: String, CaseIterable, Codable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
}

enum Mouthfeel: String, CaseIterable, Codable {
    case light = "Light"
    case medium = "Medium"
    case full = "Full"
    case creamy = "Creamy"
}

enum BaseSpirit: String, CaseIterable, Codable {
    case gin = "Gin"
    case rum = "Rum"
    case tequila = "Tequila"
    case whiskey = "Whiskey"
    case vodka = "Vodka"
    case mezcal = "Mezcal"
    case bourbon = "Bourbon"
    case scotch = "Scotch"
    case brandy = "Brandy"
    case cognac = "Cognac"
    case other = "Other"
}

enum CocktailFamily: String, CaseIterable, Codable {
    case sour = "Sour"
    case old_fashioned = "Old Fashioned"
    case martini = "Martini"
    case highball = "Highball"
    case tiki = "Tiki"
    case spritz = "Spritz"
    case flip = "Flip"
    case fizz = "Fizz"
    case punch = "Punch"
    case other = "Other"
}

enum PreparationStyle: String, CaseIterable, Codable {
    case shaken = "Shaken"
    case stirred = "Stirred"
    case built = "Built"
    case blended = "Blended"
    case muddled = "Muddled"
}

enum GlassType: String, CaseIterable, Codable {
    case coupe = "Coupe"
    case martini = "Martini"
    case rocks = "Rocks"
    case highball = "Highball"
    case collins = "Collins"
    case nick_and_nora = "Nick & Nora"
    case hurricane = "Hurricane"
    case tiki_mug = "Tiki Mug"
    case wine = "Wine Glass"
    case other = "Other"
}

enum BalanceLevel: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

struct MediaItem: Identifiable, Codable {
    let id: String
    let url: String        // Thumbnail URL for list view
    let fullUrl: String    // Full-size URL for detail view
    let objectKey: String
    let width: Int?
    let height: Int?

    enum CodingKeys: String, CodingKey {
        case id, url, objectKey, width, height
        case fullUrl = "full_url"
    }
}

struct Rating: Identifiable, Codable {
    let id: UUID
    var venueId: UUID?
    var drinkName: String
    var category: DrinkCategory
    var stars: Int? // Deprecated - kept for backward compatibility
    var score: Double? // New: 0.0-10.0 decimal score
    var notes: String?
    var dateLogged: Date

    var photoNames: [String]
    var media: [MediaItem]?
    var tags: [String]

    // Category-specific details
    var wineDetails: WineDetails?
    var beerDetails: BeerDetails?
    var cocktailDetails: CocktailDetails?

    init(
        id: UUID = UUID(),
        venueId: UUID? = nil,
        drinkName: String,
        category: DrinkCategory,
        stars: Int? = nil,
        score: Double? = nil,
        notes: String? = nil,
        dateLogged: Date = Date(),
        photoNames: [String] = [],
        media: [MediaItem]? = nil,
        tags: [String] = [],
        wineDetails: WineDetails? = nil,
        beerDetails: BeerDetails? = nil,
        cocktailDetails: CocktailDetails? = nil
    ) {
        self.id = id
        self.venueId = venueId
        self.drinkName = drinkName
        self.category = category
        self.stars = stars.map { min(max($0, 1), 5) }
        self.score = score.map { min(max($0, 0.0), 10.0) } // Clamp to 0.0-10.0
        self.notes = notes
        self.dateLogged = dateLogged
        self.photoNames = photoNames
        self.media = media
        self.tags = tags
        self.wineDetails = wineDetails
        self.beerDetails = beerDetails
        self.cocktailDetails = cocktailDetails
    }

    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: dateLogged, relativeTo: Date())
    }
}
