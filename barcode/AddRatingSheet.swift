//
//  AddRatingSheet.swift
//  barcode
//
//  Created by Burke Butler on 11/18/25.
//

import SwiftUI
import Combine
internal import _LocationEssentials

struct AddRatingSheet: View {
    let initialVenue: Venue?
    let discoveredVenue: DiscoveredVenue?
    let initialDrinkName: String?
    let initialCategory: DrinkCategory?
    let initialVarietal: String?
    let initialWineStyle: WineStyle?
    let initialVintage: String?
    let initialRegion: String?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var postsManager: PostsManager
    @EnvironmentObject var coordinator: AppCoordinator

    @State private var selectedVenue: Venue?
    @State private var showingVenueSearch = false
    @State private var drinkCategory: DrinkCategory = .wine
    @State private var drinkName: String = ""
    @State private var rating: Int = 3 // Deprecated - keeping for backward compatibility
    @State private var score: Double = 7.5 // New decimal score
    @State private var notes: String = ""
    @State private var isSubmitting: Bool = false
    @State private var showingSuggestions: Bool = false
    @FocusState private var drinkNameFieldFocused: Bool

    // Photo upload
    @State private var selectedImages: [UIImage] = []
    @State private var showingImagePicker = false
    @StateObject private var mediaUploadService = MediaUploadService()

    // Category-specific details
    @State private var wineDetails = WineDetails()
    @State private var beerDetails = BeerDetails()
    @State private var cocktailDetails = CocktailDetails()

    // TODO: Replace with actual current user ID from auth system
    let currentUserId = UUID()

    init(
        initialVenue: Venue? = nil,
        discoveredVenue: DiscoveredVenue? = nil,
        initialDrinkName: String? = nil,
        initialCategory: DrinkCategory? = nil,
        initialVarietal: String? = nil,
        initialWineStyle: WineStyle? = nil,
        initialVintage: String? = nil,
        initialRegion: String? = nil
    ) {
        self.initialVenue = initialVenue
        self.discoveredVenue = discoveredVenue
        self.initialDrinkName = initialDrinkName
        self.initialCategory = initialCategory
        self.initialVarietal = initialVarietal
        self.initialWineStyle = initialWineStyle
        self.initialVintage = initialVintage
        self.initialRegion = initialRegion
    }

    var canSave: Bool {
        !drinkName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // Get varietals based on selected wine style (defaults to red if no style selected)
    var availableVarietals: [String] {
        let style = wineDetails.style ?? .red

        switch style {
        case .red:
            return [
                "Cabernet Sauvignon", "Merlot", "Pinot Noir", "Syrah", "Shiraz",
                "Malbec", "Zinfandel", "Tempranillo", "Sangiovese", "Nebbiolo",
                "Grenache", "Barbera", "Petite Sirah", "Carmenere", "Mourvedre",
                "Cabernet Franc", "Gamay", "Primitivo", "Touriga Nacional", "Blend", "Other"
            ]
        case .white:
            return [
                "Chardonnay", "Sauvignon Blanc", "Pinot Grigio", "Pinot Gris", "Riesling",
                "Moscato", "Gewürztraminer", "Viognier", "Albariño", "Grüner Veltliner",
                "Chenin Blanc", "Semillon", "Torrontés", "Vermentino", "Assyrtiko",
                "Soave", "Garganega", "Fiano", "Verdejo", "Blend", "Other"
            ]
        case .rose:
            return [
                "Grenache Rosé", "Syrah Rosé", "Pinot Noir Rosé", "Sangiovese Rosé",
                "Tempranillo Rosé", "Mourvèdre Rosé", "Provence Blend", "Blend", "Other"
            ]
        case .orange:
            return [
                "Pinot Grigio", "Ribolla Gialla", "Friulano", "Sauvignon Blanc",
                "Rkatsiteli", "Mtsvane", "Blend", "Other"
            ]
        case .sparkling:
            return [
                "Champagne", "Prosecco", "Cava", "Crémant", "Franciacorta",
                "Lambrusco", "Sekt", "Pét-Nat", "Blend", "Other"
            ]
        case .dessert:
            return [
                "Port", "Sauternes", "Ice Wine", "Late Harvest", "Moscato d'Asti",
                "Tokaji", "Vin Santo", "Pedro Ximénez", "Madeira", "Blend", "Other"
            ]
        }
    }

    // Get unique drink names from previous posts for typeahead
    var drinkSuggestions: [String] {
        guard !drinkName.isEmpty else { return [] }

        // Get unique drink names from posts
        let uniqueDrinks = Set(postsManager.posts.map { $0.drinkName })

        // Filter by current input (case-insensitive fuzzy match)
        let filtered = uniqueDrinks.filter { drink in
            drink.localizedCaseInsensitiveContains(drinkName)
        }

        // Sort by relevance: exact prefix matches first, then others
        let sorted = filtered.sorted { drink1, drink2 in
            let starts1 = drink1.lowercased().hasPrefix(drinkName.lowercased())
            let starts2 = drink2.lowercased().hasPrefix(drinkName.lowercased())
            if starts1 && !starts2 { return true }
            if !starts1 && starts2 { return false }
            return drink1.localizedCaseInsensitiveCompare(drink2) == .orderedAscending
        }

        return Array(sorted.prefix(5))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Scrollable Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Record tasting")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)

                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Category Selection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Category")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(DrinkCategory.allCases, id: \.self) { category in
                                    CategoryButton(
                                        category: category,
                                        isSelected: drinkCategory == category,
                                        onTap: { drinkCategory = category }
                                    )
                                }
                            }
                        }
                    }

                    // Section 1: What did you try? (required)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("What did you try?")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        VStack(alignment: .leading, spacing: 0) {
                            TextField("Wine name (e.g. Caymus Cabernet)", text: $drinkName)
                                .font(.system(size: 17))
                                .padding(14)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .autocorrectionDisabled()
                                .focused($drinkNameFieldFocused)
                                .onChange(of: drinkName) { _ in
                                    showingSuggestions = !drinkName.isEmpty && drinkNameFieldFocused
                                }
                                .onChange(of: drinkNameFieldFocused) { focused in
                                    showingSuggestions = focused && !drinkName.isEmpty
                                }

                            // Typeahead suggestions
                            if showingSuggestions && !drinkSuggestions.isEmpty {
                                VStack(spacing: 0) {
                                    ForEach(drinkSuggestions, id: \.self) { suggestion in
                                        Button(action: {
                                            drinkName = suggestion
                                            showingSuggestions = false
                                            drinkNameFieldFocused = false
                                        }) {
                                            HStack {
                                                Image(systemName: "clock.arrow.circlepath")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.secondary)

                                                Text(suggestion)
                                                    .font(.system(size: 15))
                                                    .foregroundColor(.primary)

                                                Spacer()
                                            }
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(Color(.systemBackground))
                                        }
                                        .buttonStyle(PlainButtonStyle())

                                        if suggestion != drinkSuggestions.last {
                                            Divider()
                                                .padding(.leading, 40)
                                        }
                                    }
                                }
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                .padding(.top, 4)
                            }
                        }
                    }

                    // Section 2: Wine Style (only for wine)
                    if drinkCategory == .wine {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Wine Style")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(WineStyle.allCases, id: \.self) { style in
                                        CompactWineStylePill(
                                            style: style,
                                            isSelected: wineDetails.style == style,
                                            onTap: {
                                                wineDetails.style = style
                                                // Reset varietal when style changes
                                                wineDetails.varietal = nil
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }

                    // Section 3: How was it? (required)
                    VStack(alignment: .leading, spacing: 10) {
                        ScoreSlider(score: $score)
                    }

                    // Section 4: Quick note (optional but encouraged)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quick note")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        ZStack(alignment: .topLeading) {
                            if notes.isEmpty {
                                Text("Quick thoughts (optional)")
                                    .foregroundColor(Color(.placeholderText))
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                            }

                            TextEditor(text: $notes)
                                .frame(minHeight: 80, maxHeight: 80)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }

                    // Section 5: Wine Details (optional, collapsed by default, only for wine)
                    if drinkCategory == .wine {

                        DisclosureGroup("Wine details (optional)") {
                        VStack(spacing: 16) {
                            // Varietal (dropdown based on wine style, defaults to red)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Varietal")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)

                                Menu {
                                    ForEach(availableVarietals, id: \.self) { varietal in
                                        Button(action: {
                                            wineDetails.varietal = varietal
                                        }) {
                                            HStack {
                                                Text(varietal)
                                                if wineDetails.varietal == varietal {
                                                    Spacer()
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(wineDetails.varietal ?? "Select varietal")
                                            .font(.system(size: 15))
                                            .foregroundColor(wineDetails.varietal != nil ? .primary : Color(.placeholderText))
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(10)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }

                            Divider()

                            // Tasting Profile
                            VStack(alignment: .leading, spacing: 12) {
                                // Sweetness
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Sweetness")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)

                                    HStack(spacing: 6) {
                                        ForEach(SweetnessLevel.allCases, id: \.self) { level in
                                            TastingLevelButton(
                                                label: level.rawValue,
                                                isSelected: wineDetails.sweetness == level,
                                                onTap: { wineDetails.sweetness = level }
                                            )
                                        }
                                    }
                                }

                                // Body
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Body")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)

                                    HStack(spacing: 6) {
                                        ForEach(WineBody.allCases, id: \.self) { body in
                                            TastingLevelButton(
                                                label: body.rawValue,
                                                isSelected: wineDetails.body == body,
                                                onTap: { wineDetails.body = body }
                                            )
                                        }
                                    }
                                }

                                // Tannin
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Tannin")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)

                                    HStack(spacing: 6) {
                                        ForEach(TastingLevel.allCases, id: \.self) { level in
                                            TastingLevelButton(
                                                label: level.rawValue,
                                                isSelected: wineDetails.tannin == level,
                                                onTap: { wineDetails.tannin = level }
                                            )
                                        }
                                    }
                                }

                                // Acidity
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Acidity")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)

                                    HStack(spacing: 6) {
                                        ForEach(TastingLevel.allCases, id: \.self) { level in
                                            TastingLevelButton(
                                                label: level.rawValue,
                                                isSelected: wineDetails.acidity == level,
                                                onTap: { wineDetails.acidity = level }
                                            )
                                        }
                                    }
                                }
                            }

                            Divider()

                            // Wine Identity
                            VStack(alignment: .leading, spacing: 12) {
                                // Region and Vintage
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Region")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.secondary)

                                        TextField("e.g. Napa", text: Binding(
                                            get: { wineDetails.region ?? "" },
                                            set: { wineDetails.region = $0.isEmpty ? nil : $0 }
                                        ))
                                        .font(.system(size: 15))
                                        .padding(10)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                        .autocorrectionDisabled()
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Vintage")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.secondary)

                                        TextField("Year", text: Binding(
                                            get: { wineDetails.vintage ?? "" },
                                            set: { wineDetails.vintage = $0.isEmpty ? nil : $0 }
                                        ))
                                        .font(.system(size: 15))
                                        .padding(10)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                        .keyboardType(.numberPad)
                                        .frame(width: 80)
                                    }
                                }
                            }
                        }
                        .padding(.top, 12)
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                    }

                    // Section 5: Context (optional, collapsed by default)
                    DisclosureGroup("Add context (optional)") {
                        VStack(spacing: 12) {
                            // Add photo button
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: selectedImages.isEmpty ? "camera" : "checkmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(selectedImages.isEmpty ? .secondary : .green)

                                    Text(selectedImages.isEmpty ? "Add photo" : "\(selectedImages.count) photo\(selectedImages.count == 1 ? "" : "s")")
                                        .font(.system(size: 16))
                                        .foregroundColor(.primary)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())

                            // Add place button
                            Button(action: {
                                showingVenueSearch = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: selectedVenue != nil ? "checkmark.circle.fill" : "mappin.circle")
                                        .font(.system(size: 18))
                                        .foregroundColor(selectedVenue != nil ? .green : .secondary)

                                    Text(selectedVenue?.name ?? "Add place")
                                        .font(.system(size: 16))
                                        .foregroundColor(.primary)

                                    Spacer()

                                    if selectedVenue != nil {
                                        Button(action: {
                                            selectedVenue = nil
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(.secondary)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.top, 8)
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)
                }

                // Sticky bottom button
                VStack(spacing: 0) {
                    Divider()

                    Button(action: {
                        Task {
                            await submitPost()
                        }
                    }) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }

                            Text(isSubmitting ? "Saving..." : "Save tasting")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background((canSave && !isSubmitting) ? Color.blue : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!canSave || isSubmitting)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingVenueSearch) {
                VenueSearchView(
                    currentUserId: currentUserId,
                    onVenueSelected: { venue in
                        selectedVenue = venue
                        showingVenueSearch = false
                    }
                )
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImages: $selectedImages, maxSelection: 5)
            }
            .onAppear {
                setInitialVenue()
                setInitialDrinkDetails()
            }
        }
    }

    func setInitialDrinkDetails() {
        if let name = initialDrinkName {
            drinkName = name
        }
        if let category = initialCategory {
            drinkCategory = category
        }
        if let varietal = initialVarietal {
            wineDetails.varietal = varietal
        }
        if let style = initialWineStyle {
            wineDetails.style = style
        }
        if let vintage = initialVintage {
            wineDetails.vintage = vintage
        }
        if let region = initialRegion {
            wineDetails.region = region
        }
    }

    func submitPost() async {
        isSubmitting = true

        print("DEBUG: submitPost called - selectedImages count: \(selectedImages.count)")

        // Convert wine details if any are filled out
        var wineDetailsReq: WineDetailsRequest? = nil
        if drinkCategory == .wine {
            wineDetailsReq = WineDetailsRequest(
                sweetness: wineDetails.sweetness?.rawValue ?? "",
                body: wineDetails.body?.rawValue ?? "",
                tannin: wineDetails.tannin?.rawValue ?? "",
                acidity: wineDetails.acidity?.rawValue ?? "",
                wineStyle: wineDetails.style?.rawValue ?? "",
                varietal: wineDetails.varietal ?? "",
                region: wineDetails.region ?? "",
                vintage: wineDetails.vintage ?? "",
                winery: wineDetails.winery ?? ""
            )
        }

        // Build venueDetails if we have a discovered venue
        var venueDetailsReq: VenueDetailsRequest? = nil
        if let discovered = discoveredVenue {
            // Extract address components from the full address string
            let addressComponents = discovered.address?.components(separatedBy: ", ") ?? []
            let city = addressComponents.count > 1 ? addressComponents[addressComponents.count - 2] : ""
            let state = addressComponents.count > 2 ? addressComponents[addressComponents.count - 1] : ""

            venueDetailsReq = VenueDetailsRequest(
                name: discovered.name,
                address: discovered.address,
                city: city,
                state: state,
                country: "US",
                lat: discovered.coordinate.latitude,
                lng: discovered.coordinate.longitude,
                externalPlaceId: discovered.id,
                mapProvider: "apple"
            )
        }

        let success = await postsManager.createPost(
            venueId: discoveredVenue == nil ? selectedVenue?.id.uuidString : nil,
            drinkName: drinkName,
            drinkCategory: drinkCategory.rawValue,
            stars: nil, // Deprecated - no longer using stars
            score: score,
            notes: notes,
            beerDetails: nil,
            wineDetails: wineDetailsReq,
            cocktailDetails: nil,
            venueDetails: venueDetailsReq
        )

        print("DEBUG: Post creation success: \(success), selectedImages.isEmpty: \(selectedImages.isEmpty)")

        // Upload photos if the post was created successfully
        if success, !selectedImages.isEmpty {
            print("DEBUG: Uploading \(selectedImages.count) images")
            // Get the newly created post ID from the posts list
            if let newPost = postsManager.posts.first {
                print("DEBUG: Post ID: \(newPost.id)")
                let mediaIDs = await mediaUploadService.uploadImages(selectedImages, postID: newPost.id)
                print("DEBUG: Uploaded media IDs: \(mediaIDs)")

                // Attach each media to the post
                for mediaID in mediaIDs {
                    let attached = await mediaUploadService.attachMediaToPost(mediaID: mediaID, postID: newPost.id)
                    print("DEBUG: Attached media \(mediaID) to post: \(attached)")
                }
            } else {
                print("DEBUG: No new post found in posts list")
            }
        } else if !selectedImages.isEmpty {
            print("DEBUG: Post creation failed, not uploading images")
        }

        isSubmitting = false

        if success {
            // Refresh posts to get the new one
            await postsManager.fetchPosts()

            // Find the drink collection for this drink
            // Convert posts to ratings
            let ratings = postsManager.posts.compactMap { post -> Rating? in
                guard let postUUID = UUID(uuidString: post.id),
                      let createdDate = ISO8601DateFormatter().date(from: post.createdAt) else {
                    return nil
                }

                let category = DrinkCategory(rawValue: post.drinkCategory) ?? .other
                let venueUUID = post.venueId.flatMap { UUID(uuidString: $0) }

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

                // Convert wine details
                let wineDetails: WineDetails? = post.wineDetails.map { wd in
                    WineDetails(
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

                // Convert beer details
                let beerDetails: BeerDetails? = post.beerDetails.map { bd in
                    BeerDetails(
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

                // Convert cocktail details
                let cocktailDetails: CocktailDetails? = post.cocktailDetails.map { cd in
                    CocktailDetails(
                        baseSpirit: cd.baseSpirit.flatMap { BaseSpirit(rawValue: $0) },
                        cocktailFamily: cd.cocktailFamily.flatMap { CocktailFamily(rawValue: $0) },
                        preparationStyle: cd.preparation.flatMap { PreparationStyle(rawValue: $0) },
                        glassType: cd.presentation.flatMap { GlassType(rawValue: $0) },
                        garnish: cd.garnish,
                        sweetness: cd.sweetness.flatMap { BalanceLevel(rawValue: $0) },
                        booziness: cd.booziness.flatMap { BalanceLevel(rawValue: $0) },
                        balance: cd.balance.flatMap { BalanceLevel(rawValue: $0) },
                        recipeNotes: nil
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

            // Find the collection for this drink
            let grouped = Dictionary(grouping: ratings) { rating in
                let varietal = rating.wineDetails?.varietal ?? ""
                return "\(rating.drinkName.lowercased())_\(rating.category.rawValue)_\(varietal.lowercased())"
            }

            let collections = grouped.map { key, tastings in
                let first = tastings.first!
                return DrinkCollection(
                    id: key,
                    name: first.drinkName,
                    category: first.category,
                    tastings: tastings.sorted { $0.dateLogged > $1.dateLogged }
                )
            }

            // Find the collection matching our new drink (including varietal for wines)
            if let targetCollection = collections.first(where: {
                let nameMatches = $0.name.lowercased() == drinkName.lowercased()
                let categoryMatches = $0.category == drinkCategory

                // For wines, also match varietal
                if drinkCategory == .wine {
                    let varietalMatches = $0.latestTasting?.wineDetails?.varietal?.lowercased() == wineDetails.varietal?.lowercased()
                    return nameMatches && categoryMatches && varietalMatches
                }

                return nameMatches && categoryMatches
            }) {
                // Dismiss the sheet first
                dismiss()

                // Then navigate to the collection detail
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    coordinator.navigateToDrinkCollection(targetCollection)
                }
            } else {
                // Fallback: just dismiss
                dismiss()
            }
        }
    }

    private func setInitialVenue() {
        if let venue = initialVenue {
            selectedVenue = venue
        }
    }
}

struct VenueSelectionCard: View {
    let venue: Venue
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Venue thumbnail
            if let imageURL = venue.imageURL {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    default:
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 60, height: 60)
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(venue.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    if !venue.isOfficial {
                        Text("Personal")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(4)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Text(venue.city)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    Text("•")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Text(venue.type.rawValue)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: onClear) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.system(size: 22))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(14)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CategoryPill: View {
    let category: DrinkCategory
    let isSelected: Bool
    let onTap: () -> Void

    var categoryColor: Color {
        switch category {
        case .beer: return .orange
        case .wine: return .purple
        case .cocktail: return .blue
        case .other: return .gray
        }
    }

    var categoryIcon: String {
        switch category {
        case .beer: return "mug.fill"
        case .wine: return "wineglass.fill"
        case .cocktail: return "cup.and.saucer.fill"
        case .other: return "circle.fill"
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: categoryIcon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? categoryColor : .secondary)

                Text(category.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? categoryColor : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? categoryColor.opacity(0.15) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? categoryColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Generic Drink Form (for Beer, Cocktails, Other)

struct GenericDrinkForm: View {
    @Binding var drinkName: String
    @Binding var score: Double
    @Binding var notes: String

    var body: some View {
        VStack(spacing: 24) {
            // Drink name
            VStack(alignment: .leading, spacing: 8) {
                Text("Drink Name")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                TextField("Drink name", text: $drinkName)
                    .font(.system(size: 16))
                    .padding(14)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .autocorrectionDisabled()
            }

            // Details Card
            VStack(alignment: .leading, spacing: 18) {
                Text("Details")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                // Score
                ScoreSlider(score: $score)

                Divider()

                // Notes section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Notes (optional)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)

                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("Add your tasting notes...")
                                .foregroundColor(Color(.placeholderText))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }

                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
            .padding(18)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }
}

// MARK: - Helper Components

struct CategoryButton: View {
    let category: DrinkCategory
    let isSelected: Bool
    let onTap: () -> Void

    var categoryColor: Color {
        switch category {
        case .beer: return .orange
        case .wine: return .purple
        case .cocktail: return .blue
        case .other: return .gray
        }
    }

    var body: some View {
        Button(action: onTap) {
            Text(category.rawValue.capitalized)
                .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? categoryColor : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? categoryColor.opacity(0.12) : Color(.systemGray6))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? categoryColor : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CompactWineStylePill: View {
    let style: WineStyle
    let isSelected: Bool
    let onTap: () -> Void

    var styleColor: Color {
        switch style {
        case .red: return Color(red: 0.5, green: 0.1, blue: 0.1)
        case .white: return Color(red: 0.9, green: 0.85, blue: 0.4)
        case .rose: return Color(red: 0.9, green: 0.5, blue: 0.6)
        case .orange: return Color.orange
        case .sparkling: return Color(red: 0.95, green: 0.95, blue: 0.7)
        case .dessert: return Color(red: 0.6, green: 0.4, blue: 0.2)
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 5) {
                Circle()
                    .fill(styleColor)
                    .frame(width: 10, height: 10)

                Text(style.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.purple.opacity(0.12) : Color(.systemGray6))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

