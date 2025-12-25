//
//  MyLogView.swift
//  barcode
//
//  Created by Burke Butler on 11/18/25.
//

import SwiftUI

enum LogViewMode: String, CaseIterable {
    case collection = "Collection"
    case timeline = "Timeline"
}

struct MyLogView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var postsManager = PostsManager()
    @StateObject private var venuesManager = VenuesManager()
    @State private var viewMode: LogViewMode = .collection
    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var selectedCategory: DrinkCategory? = nil // nil = "All"
    @FocusState private var isSearchFocused: Bool
    @State private var preselectedVenue: Venue?
    @State private var preselectedDiscoveredVenue: DiscoveredVenue?
    @State private var prefilledDrinkName: String?
    @State private var prefilledCategory: DrinkCategory?
    @State private var prefilledVarietal: String?
    @State private var prefilledWineStyle: WineStyle?
    @State private var prefilledVintage: String?
    @State private var prefilledRegion: String?

    // Convert PostResponse to Rating for display
    func toRating(_ post: PostResponse) -> Rating? {
        guard let userUUID = UUID(uuidString: post.userId),
              let postUUID = UUID(uuidString: post.id),
              let createdDate = ISO8601DateFormatter().date(from: post.createdAt) else {
            return nil
        }

        // Venue is now optional
        let venueUUID = post.venueId.flatMap { UUID(uuidString: $0) }

        let category = DrinkCategory(rawValue: post.drinkCategory) ?? .other

        // Convert wine details
        var wineDetails: WineDetails? = nil
        if let wd = post.wineDetails {
            print("DEBUG: Wine details from API - wineStyle: \(wd.wineStyle ?? "nil"), sweetness: \(wd.sweetness ?? "nil"), body: \(wd.body ?? "nil"), tannin: \(wd.tannin ?? "nil"), acidity: \(wd.acidity ?? "nil")")
            wineDetails = WineDetails(
                varietal: wd.varietal,
                region: wd.region,
                vintage: wd.vintage,
                style: wd.wineStyle.flatMap { WineStyle(rawValue: $0) },
                sweetness: wd.sweetness.flatMap { SweetnessLevel(rawValue: $0) },
                body: wd.body.flatMap { WineBody(rawValue: $0) },
                tannin: wd.tannin.flatMap { TastingLevel(rawValue: $0) },
                acidity: wd.acidity.flatMap { TastingLevel(rawValue: $0) },
                winery: wd.winery
            )
            print("DEBUG: Converted wine details - style: \(wineDetails?.style?.rawValue ?? "nil"), sweetness: \(wineDetails?.sweetness?.rawValue ?? "nil")")
        } else {
            print("DEBUG: post.wineDetails is nil for post category: \(post.drinkCategory)")
        }

        // Convert beer details
        var beerDetails: BeerDetails? = nil
        if let bd = post.beerDetails {
            beerDetails = BeerDetails(
                style: bd.beerStyle.flatMap { BeerStyle(rawValue: $0) },
                brewery: bd.brewery,
                abv: bd.abv.map { String($0) },
                ibu: bd.ibu.map { String($0) },
                servingType: bd.serving.flatMap { ServingType(rawValue: $0) },
                bitterness: nil,
                hoppiness: nil,
                maltiness: nil,
                mouthfeel: bd.acidity.flatMap { Mouthfeel(rawValue: $0) }
            )
        }

        // Convert cocktail details
        var cocktailDetails: CocktailDetails? = nil
        if let cd = post.cocktailDetails {
            cocktailDetails = CocktailDetails(
                baseSpirit: cd.baseSpirit.flatMap { BaseSpirit(rawValue: $0) },
                cocktailFamily: cd.cocktailFamily.flatMap { CocktailFamily(rawValue: $0) },
                preparationStyle: cd.preparation.flatMap { PreparationStyle(rawValue: $0) },
                glassType: nil,
                garnish: cd.garnish,
                sweetness: cd.sweetness.flatMap { BalanceLevel(rawValue: $0) },
                booziness: cd.booziness.flatMap { BalanceLevel(rawValue: $0) },
                balance: cd.balance.flatMap { BalanceLevel(rawValue: $0) },
                recipeNotes: nil
            )
        }

        // Convert media items
        let media = post.media?.map { mediaResponse in
            print("DEBUG MyLogView toRating: Converting media - id=\(mediaResponse.id), url=\(mediaResponse.url), fullUrl=\(mediaResponse.fullUrl)")
            return MediaItem(
                id: mediaResponse.id,
                url: mediaResponse.url,
                fullUrl: mediaResponse.fullUrl,
                objectKey: mediaResponse.objectKey,
                width: mediaResponse.width,
                height: mediaResponse.height
            )
        }
        if let mediaCount = media?.count {
            print("DEBUG MyLogView toRating: Post \(post.drinkName) has \(mediaCount) media items")
        } else {
            print("DEBUG MyLogView toRating: Post \(post.drinkName) has NO media")
        }

        return Rating(
            id: postUUID,
            venueId: venueUUID,
            drinkName: post.drinkName,
            category: category,
            stars: post.stars,
            score: post.score,
            notes: post.notes,
            dateLogged: createdDate,
            photoNames: [],
            media: media,
            tags: [],
            wineDetails: wineDetails,
            beerDetails: beerDetails,
            cocktailDetails: cocktailDetails
        )
    }

    var filteredPosts: [PostResponse] {
        var posts = postsManager.posts

        // Apply category filter
        if let category = selectedCategory {
            posts = posts.filter { $0.drinkCategory == category.rawValue }
        }

        // Apply search filter
        if !searchText.isEmpty {
            posts = posts.filter { post in
                post.drinkName.localizedCaseInsensitiveContains(searchText) ||
                (post.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        return posts
    }

    var drinkCollections: [DrinkCollection] {
        // Convert filtered posts to ratings
        let ratings = filteredPosts.compactMap { toRating($0) }

        // Group by drink name + category + varietal (for wines)
        let grouped = Dictionary(grouping: ratings) { rating in
            let varietal = rating.wineDetails?.varietal ?? ""
            return "\(rating.drinkName.lowercased())_\(rating.category.rawValue)_\(varietal.lowercased())"
        }

        // Create DrinkCollection objects
        return grouped.map { key, tastings in
            let first = tastings.first!
            return DrinkCollection(
                id: key,
                name: first.drinkName,
                category: first.category,
                tastings: tastings.sorted { $0.dateLogged > $1.dateLogged }
            )
        }.sorted { collection1, collection2 in
            // Sort by most recent tasting
            guard let date1 = collection1.lastTried,
                  let date2 = collection2.lastTried else {
                return false
            }
            return date1 > date2
        }
    }

    var venuesWithRatings: [UUID] {
        // Get unique venue IDs from filtered posts (excluding posts without venues)
        let venueIds = Set(filteredPosts.compactMap { post in
            post.venueId.flatMap { UUID(uuidString: $0) }
        })

        // Sort by most recent post
        return venueIds.sorted { venueId1, venueId2 in
            let posts1 = filteredPosts.filter { $0.venueId == venueId1.uuidString }
            let posts2 = filteredPosts.filter { $0.venueId == venueId2.uuidString }

            guard let date1Str = posts1.first?.createdAt,
                  let date2Str = posts2.first?.createdAt,
                  let date1 = ISO8601DateFormatter().date(from: date1Str),
                  let date2 = ISO8601DateFormatter().date(from: date2Str) else {
                return false
            }
            return date1 > date2
        }
    }

    func getRatingsForVenue(_ venue: Venue) -> [Rating] {
        postsManager.posts
            .filter { $0.venueId == venue.id.uuidString }
            .compactMap { toRating($0) }
            .sorted { $0.dateLogged > $1.dateLogged }
    }

    var allRatingsTimeline: [Rating] {
        // Use filteredPosts which already applies both category and search filters
        filteredPosts
            .compactMap { toRating($0) }
            .sorted { $0.dateLogged > $1.dateLogged }
    }

    var totalVenues: Int {
        venuesWithRatings.count
    }

    var averageRating: Double {
        guard !filteredPosts.isEmpty else { return 0 }
        let postsWithRatings = filteredPosts.compactMap { $0.stars }
        guard !postsWithRatings.isEmpty else { return 0 }
        let sum = postsWithRatings.reduce(0, +)
        return Double(sum) / Double(postsWithRatings.count)
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Hidden NavigationLink for programmatic navigation to collection detail
                if let collection = coordinator.navigateToCollection {
                    NavigationLink(
                        destination: DrinkCollectionDetailView(collection: collection)
                            .environmentObject(dataStore)
                            .environmentObject(postsManager),
                        isActive: Binding(
                            get: { coordinator.navigateToCollection != nil },
                            set: { if !$0 { coordinator.resetNavigationState() } }
                        )
                    ) {
                        EmptyView()
                    }
                    .hidden()
                }

            VStack(spacing: 0) {
                // Modern Header with Search
                VStack(spacing: 14) {
                    // Row 1: Search bar and add button
                    HStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)

                            TextField("Search drinks, venues...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.system(size: 16))
                                .focused($isSearchFocused)

                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                        Button(action: { showingAddSheet = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.blue)
                        }
                    }

                    // Row 2: Category filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            FilterChip(
                                title: "All",
                                icon: "line.3.horizontal.decrease.circle",
                                isSelected: selectedCategory == nil,
                                action: { selectedCategory = nil }
                            )

                            FilterChip(
                                title: "Wine",
                                icon: "wineglass",
                                isSelected: selectedCategory == .wine,
                                action: { selectedCategory = .wine }
                            )

                            FilterChip(
                                title: "Beer",
                                icon: "mug",
                                isSelected: selectedCategory == .beer,
                                action: { selectedCategory = .beer }
                            )

                            FilterChip(
                                title: "Cocktails",
                                icon: "mug",
                                isSelected: selectedCategory == .cocktail,
                                action: { selectedCategory = .cocktail }
                            )
                        }
                    }

                    // Row 3: Quick stats (filtered)
                    HStack(spacing: 20) {
                        StatPill(value: "\(filteredPosts.count)", label: "drinks")
                        StatPill(value: "\(totalVenues)", label: "venues")
                        StatPill(value: String(format: "%.1f", averageRating), label: "avg rating")

                        Spacer()
                    }

                    // Row 4: View mode toggle (de-emphasized)
                    Picker("View Mode", selection: $viewMode) {
                        ForEach(LogViewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 14)

                // Content based on view mode
                if postsManager.posts.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)

                        Text("No ratings yet")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)

                        Text("Start building your drink history")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Button(action: { showingAddSheet = true }) {
                            Text("Add Your First Drink")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.top, 8)
                    }
                    Spacer()
                } else {
                    if viewMode == .collection {
                        CollectionView(postsManager: postsManager, collections: drinkCollections)
                    } else {
                        TimelineView(postsManager: postsManager, ratings: allRatingsTimeline)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddSheet) {
                AddRatingSheet(
                    initialVenue: preselectedVenue,
                    discoveredVenue: preselectedDiscoveredVenue,
                    initialDrinkName: prefilledDrinkName,
                    initialCategory: prefilledCategory,
                    initialVarietal: prefilledVarietal,
                    initialWineStyle: prefilledWineStyle,
                    initialVintage: prefilledVintage,
                    initialRegion: prefilledRegion
                )
                .environmentObject(postsManager)
            }
            .task {
                async let posts: () = postsManager.fetchPosts()
                async let venues: () = venuesManager.fetchVenues()
                await posts
                await venues
                // Update dataStore with fetched venues
                dataStore.venues = venuesManager.venues.map { venuesManager.toVenue($0) }
            }
            .refreshable {
                async let posts: () = postsManager.fetchPosts()
                async let venues: () = venuesManager.fetchVenues()
                await posts
                await venues
                dataStore.venues = venuesManager.venues.map { venuesManager.toVenue($0) }
            }
            .onChange(of: coordinator.shouldOpenAddRating) { shouldOpen in
                if shouldOpen {
                    preselectedVenue = coordinator.preselectedVenue
                    preselectedDiscoveredVenue = coordinator.preselectedVenueFromDiscovery
                    prefilledDrinkName = coordinator.prefilledDrinkName
                    prefilledCategory = coordinator.prefilledCategory
                    prefilledVarietal = coordinator.prefilledVarietal
                    prefilledWineStyle = coordinator.prefilledWineStyle
                    prefilledVintage = coordinator.prefilledVintage
                    prefilledRegion = coordinator.prefilledRegion
                    showingAddSheet = true
                    // Delay resetting to ensure sheet has time to present
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        coordinator.resetAddRatingState()
                    }
                }
            }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Supporting Views

struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }
}

struct ByVenueView: View {
    @EnvironmentObject var dataStore: DataStore
    @ObservedObject var postsManager: PostsManager
    let venues: [UUID]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(venues, id: \.self) { venueId in
                    VenueLogCardById(postsManager: postsManager, venueId: venueId)
                        .environmentObject(dataStore)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
    }
}

struct CollectionView: View {
    @EnvironmentObject var dataStore: DataStore
    @ObservedObject var postsManager: PostsManager
    let collections: [DrinkCollection]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(collections) { collection in
                    NavigationLink(destination: DrinkCollectionDetailView(collection: collection)
                        .environmentObject(dataStore)
                        .environmentObject(postsManager)) {
                        DrinkCollectionCard(collection: collection)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
    }
}

struct TimelineView: View {
    @EnvironmentObject var dataStore: DataStore
    @ObservedObject var postsManager: PostsManager

    let ratings: [Rating]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(ratings) { rating in
                    let venue = dataStore.getVenue(for: rating)
                    NavigationLink(destination: RatingDetailView(rating: rating, venue: venue)
                        .environmentObject(postsManager)) {
                        TimelineRatingCard(rating: rating, venue: venue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
    }
}

struct VenueLogCardById: View {
    @EnvironmentObject var dataStore: DataStore
    @ObservedObject var postsManager: PostsManager
    let venueId: UUID

    // Get venue name from first post for this venue
    var venueName: String {
        // Try to find venue in dataStore first
        if let venue = dataStore.venues.first(where: { $0.id == venueId }) {
            return venue.name
        }
        // Fallback to showing venue ID
        return "Unknown Venue"
    }

    var venue: Venue? {
        dataStore.venues.first(where: { $0.id == venueId })
    }

    var body: some View {
        if let venue = venue {
            VenueLogCard(postsManager: postsManager, venue: venue)
        } else {
            // Show posts even if venue isn't loaded
            VenueLogCardSimple(postsManager: postsManager, venueId: venueId, venueName: venueName)
        }
    }
}

struct VenueLogCardSimple: View {
    @EnvironmentObject var dataStore: DataStore
    @ObservedObject var postsManager: PostsManager
    let venueId: UUID
    let venueName: String

    func toRating(_ post: PostResponse) -> Rating? {
        guard let userUUID = UUID(uuidString: post.userId),
              let postUUID = UUID(uuidString: post.id),
              let createdDate = ISO8601DateFormatter().date(from: post.createdAt) else {
            return nil
        }

        let venueUUID = post.venueId.flatMap { UUID(uuidString: $0) }

        let category = DrinkCategory(rawValue: post.drinkCategory) ?? .other

        // Convert details
        var wineDetails: WineDetails? = nil
        if let wd = post.wineDetails {
            wineDetails = WineDetails(
                varietal: wd.varietal,
                region: wd.region,
                vintage: wd.vintage,
                style: wd.wineStyle.flatMap { WineStyle(rawValue: $0) },
                sweetness: wd.sweetness.flatMap { SweetnessLevel(rawValue: $0) },
                body: wd.body.flatMap { WineBody(rawValue: $0) },
                tannin: wd.tannin.flatMap { TastingLevel(rawValue: $0) },
                acidity: wd.acidity.flatMap { TastingLevel(rawValue: $0) },
                winery: wd.winery
            )
        }

        var beerDetails: BeerDetails? = nil
        if let bd = post.beerDetails {
            beerDetails = BeerDetails(
                style: bd.beerStyle.flatMap { BeerStyle(rawValue: $0) },
                brewery: bd.brewery,
                abv: bd.abv.map { String($0) },
                ibu: bd.ibu.map { String($0) },
                servingType: bd.serving.flatMap { ServingType(rawValue: $0) },
                bitterness: nil,
                hoppiness: nil,
                maltiness: nil,
                mouthfeel: nil
            )
        }

        var cocktailDetails: CocktailDetails? = nil
        if let cd = post.cocktailDetails {
            cocktailDetails = CocktailDetails(
                baseSpirit: cd.baseSpirit.flatMap { BaseSpirit(rawValue: $0) },
                cocktailFamily: cd.cocktailFamily.flatMap { CocktailFamily(rawValue: $0) },
                preparationStyle: cd.preparation.flatMap { PreparationStyle(rawValue: $0) },
                glassType: nil,
                garnish: cd.garnish,
                sweetness: cd.sweetness.flatMap { BalanceLevel(rawValue: $0) },
                booziness: cd.booziness.flatMap { BalanceLevel(rawValue: $0) },
                balance: cd.balance.flatMap { BalanceLevel(rawValue: $0) },
                recipeNotes: nil
            )
        }

        // Convert media items
        let media = post.media?.map { mediaResponse in
            MediaItem(
                id: mediaResponse.id,
                url: mediaResponse.url,
                fullUrl: mediaResponse.fullUrl,
                objectKey: mediaResponse.objectKey,
                width: mediaResponse.width,
                height: mediaResponse.height
            )
        }

        return Rating(
            id: postUUID,
            venueId: venueUUID,
            drinkName: post.drinkName,
            category: category,
            stars: post.stars,
            score: post.score,
            notes: post.notes,
            dateLogged: createdDate,
            photoNames: [],
            media: media,
            tags: [],
            wineDetails: wineDetails,
            beerDetails: beerDetails,
            cocktailDetails: cocktailDetails
        )
    }

    var ratings: [Rating] {
        postsManager.posts
            .filter { $0.venueId == venueId.uuidString }
            .compactMap { toRating($0) }
            .sorted { $0.dateLogged > $1.dateLogged }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Compact venue header
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.gray)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(venueName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)

                    HStack(spacing: 6) {
                        Text("Venue")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)

                        if ratings.count > 0 {
                            Text("•")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            Text("\(ratings.count) drink\(ratings.count == 1 ? "" : "s")")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.systemBackground))

            // Ratings list
            VStack(spacing: 8) {
                ForEach(ratings) { rating in
                    let fallbackVenue = Venue(
                        id: venueId,
                        name: venueName,
                        type: .bar,
                        city: "",
                        imageURL: nil
                    )
                    let displayVenue = dataStore.venues.first(where: { $0.id == venueId }) ?? fallbackVenue

                    NavigationLink(destination: RatingDetailView(rating: rating, venue: displayVenue)
                        .environmentObject(postsManager)) {
                        CompactRatingRow(rating: rating)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .background(Color(.systemBackground))
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

struct VenueLogCard: View {
    @EnvironmentObject var dataStore: DataStore
    @ObservedObject var postsManager: PostsManager
    let venue: Venue

    func toRating(_ post: PostResponse) -> Rating? {
        guard let userUUID = UUID(uuidString: post.userId),
              let postUUID = UUID(uuidString: post.id),
              let createdDate = ISO8601DateFormatter().date(from: post.createdAt) else {
            return nil
        }

        let venueUUID = post.venueId.flatMap { UUID(uuidString: $0) }

        let category = DrinkCategory(rawValue: post.drinkCategory) ?? .other

        // Convert details
        var wineDetails: WineDetails? = nil
        if let wd = post.wineDetails {
            wineDetails = WineDetails(
                varietal: wd.varietal,
                region: wd.region,
                vintage: wd.vintage,
                style: wd.wineStyle.flatMap { WineStyle(rawValue: $0) },
                sweetness: wd.sweetness.flatMap { SweetnessLevel(rawValue: $0) },
                body: wd.body.flatMap { WineBody(rawValue: $0) },
                tannin: wd.tannin.flatMap { TastingLevel(rawValue: $0) },
                acidity: wd.acidity.flatMap { TastingLevel(rawValue: $0) },
                winery: wd.winery
            )
        }

        var beerDetails: BeerDetails? = nil
        if let bd = post.beerDetails {
            beerDetails = BeerDetails(
                style: bd.beerStyle.flatMap { BeerStyle(rawValue: $0) },
                brewery: bd.brewery,
                abv: bd.abv.map { String($0) },
                ibu: bd.ibu.map { String($0) },
                servingType: bd.serving.flatMap { ServingType(rawValue: $0) },
                bitterness: nil,
                hoppiness: nil,
                maltiness: nil,
                mouthfeel: nil
            )
        }

        var cocktailDetails: CocktailDetails? = nil
        if let cd = post.cocktailDetails {
            cocktailDetails = CocktailDetails(
                baseSpirit: cd.baseSpirit.flatMap { BaseSpirit(rawValue: $0) },
                cocktailFamily: cd.cocktailFamily.flatMap { CocktailFamily(rawValue: $0) },
                preparationStyle: cd.preparation.flatMap { PreparationStyle(rawValue: $0) },
                glassType: nil,
                garnish: cd.garnish,
                sweetness: cd.sweetness.flatMap { BalanceLevel(rawValue: $0) },
                booziness: cd.booziness.flatMap { BalanceLevel(rawValue: $0) },
                balance: cd.balance.flatMap { BalanceLevel(rawValue: $0) },
                recipeNotes: nil
            )
        }

        // Convert media items
        let media = post.media?.map { mediaResponse in
            MediaItem(
                id: mediaResponse.id,
                url: mediaResponse.url,
                fullUrl: mediaResponse.fullUrl,
                objectKey: mediaResponse.objectKey,
                width: mediaResponse.width,
                height: mediaResponse.height
            )
        }

        return Rating(
            id: postUUID,
            venueId: venueUUID,
            drinkName: post.drinkName,
            category: category,
            stars: post.stars,
            score: post.score,
            notes: post.notes,
            dateLogged: createdDate,
            photoNames: [],
            media: media,
            tags: [],
            wineDetails: wineDetails,
            beerDetails: beerDetails,
            cocktailDetails: cocktailDetails
        )
    }

    var ratings: [Rating] {
        postsManager.posts
            .filter { $0.venueId == venue.id.uuidString }
            .compactMap { toRating($0) }
            .sorted { $0.dateLogged > $1.dateLogged }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Compact venue header
            HStack(spacing: 10) {
                // Venue image thumbnail
                if let imageURL = venue.imageURL {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        default:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 60, height: 60)
                        }
                    }
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.gray)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(venue.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)

                    HStack(spacing: 6) {
                        Text(venue.type.rawValue)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)

                        if ratings.count > 0 {
                            Text("•")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            Text("\(ratings.count) drink\(ratings.count == 1 ? "" : "s")")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.systemBackground))

            // Ratings list
            VStack(spacing: 8) {
                ForEach(ratings) { rating in
                    NavigationLink(destination: RatingDetailView(rating: rating, venue: venue)
                        .environmentObject(postsManager)) {
                        CompactRatingRow(rating: rating)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .background(Color(.systemBackground))
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

struct CompactRatingRow: View {
    let rating: Rating

    var categoryColor: Color {
        switch rating.category {
        case .beer: return .orange
        case .wine: return .purple
        case .cocktail: return .blue
        case .other: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Small category indicator
            Circle()
                .fill(categoryColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(rating.drinkName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)

                HStack(spacing: 6) {
                    if let score = rating.score {
                        Text(String(format: "%.1f", score))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                    } else if let stars = rating.stars {
                        Text(String(format: "%.1f", Double(stars) * 2.0))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                    }

                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    Text(rating.relativeTime)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(8)
    }
}

struct DrinkCollectionCard: View {
    let collection: DrinkCollection

    var categoryColor: Color {
        switch collection.category {
        case .beer: return .orange
        case .wine: return .purple
        case .cocktail: return .blue
        case .other: return .gray
        }
    }

    var categoryIcon: String {
        switch collection.category {
        case .wine: return "wineglass.fill"
        case .beer: return "mug.fill"
        case .cocktail: return "martini.glass.fill"
        case .other: return "drop.fill"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail - use latest tasting's first media
            if let firstMedia = collection.latestTasting?.media?.first {
                AsyncImage(url: URL(string: firstMedia.url)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    default:
                        categoryThumbnail
                    }
                }
            } else {
                categoryThumbnail
            }

            VStack(alignment: .leading, spacing: 6) {
                // Drink name
                Text(collection.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                // Stats row
                HStack(spacing: 6) {
                    // Average rating
                    if let avgRating = collection.averageRating {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", avgRating))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                        }
                    }

                    Text("•")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    // Times tried
                    Text("\(collection.timesTried) tasting\(collection.timesTried == 1 ? "" : "s")")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                // Last tried date
                if let lastTried = collection.lastTried {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        let formatter = RelativeDateTimeFormatter()
                        Text("Last: \(formatter.localizedString(for: lastTried, relativeTo: Date()))")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Category icon + chevron
            VStack(spacing: 8) {
                Image(systemName: categoryIcon)
                    .font(.system(size: 20))
                    .foregroundColor(categoryColor)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    var categoryThumbnail: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(categoryColor.opacity(0.15))
            .frame(width: 80, height: 80)
            .overlay(
                Image(systemName: categoryIcon)
                    .font(.system(size: 32))
                    .foregroundColor(categoryColor.opacity(0.6))
            )
    }
}

struct TimelineRatingCard: View {
    let rating: Rating
    let venue: Venue?

    var categoryColor: Color {
        switch rating.category {
        case .beer: return .orange
        case .wine: return .purple
        case .cocktail: return .blue
        case .other: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Photo or placeholder
            if let firstMedia = rating.media?.first {
                let _ = print("TimelineRatingCard: media exists for \(rating.drinkName), url=\(firstMedia.url)")
                AsyncImage(url: URL(string: firstMedia.url)) { phase in
                    switch phase {
                    case .success(let image):
                        let _ = print("TimelineRatingCard: AsyncImage SUCCESS for \(rating.drinkName)")
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure(let error):
                        let _ = print("TimelineRatingCard: AsyncImage FAILED for \(rating.drinkName), error=\(error)")
                        RoundedRectangle(cornerRadius: 8)
                            .fill(categoryColor.opacity(0.15))
                            .frame(width: 80, height: 80)
                    case .empty:
                        let _ = print("TimelineRatingCard: AsyncImage EMPTY for \(rating.drinkName)")
                        RoundedRectangle(cornerRadius: 8)
                            .fill(categoryColor.opacity(0.15))
                            .frame(width: 80, height: 80)
                    @unknown default:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(categoryColor.opacity(0.15))
                            .frame(width: 80, height: 80)
                    }
                }
            } else {
                let _ = print("TimelineRatingCard: NO media for \(rating.drinkName)")
                RoundedRectangle(cornerRadius: 8)
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 80, height: 80)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(rating.drinkName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                HStack(spacing: 6) {
                    if let score = rating.score {
                        Text(String(format: "%.1f", score))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                    } else if let stars = rating.stars {
                        Text(String(format: "%.1f", Double(stars) * 2.0))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                    }

                    Text("•")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Text(rating.category.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(categoryColor)
                }

                if let venue = venue {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        Text(venue.name)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Text(rating.relativeTime)
                    .font(.system(size: 12))
                    .foregroundColor(Color(.tertiaryLabel))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

