//
//  AddRatingSheet.swift
//  barcode
//
//  Created by Burke Butler on 11/18/25.
//

import SwiftUI
internal import _LocationEssentials

struct AddRatingSheet: View {
    let initialVenue: Venue?
    let discoveredVenue: DiscoveredVenue?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var postsManager: PostsManager

    @State private var selectedVenue: Venue?
    @State private var showingVenueSearch = false
    @State private var drinkCategory: DrinkCategory = .wine
    @State private var drinkName: String = ""
    @State private var rating: Int = 3
    @State private var notes: String = ""
    @State private var isSubmitting: Bool = false

    // Category-specific details
    @State private var wineDetails = WineDetails()
    @State private var beerDetails = BeerDetails()
    @State private var cocktailDetails = CocktailDetails()

    // TODO: Replace with actual current user ID from auth system
    let currentUserId = UUID()

    init(initialVenue: Venue? = nil, discoveredVenue: DiscoveredVenue? = nil) {
        self.initialVenue = initialVenue
        self.discoveredVenue = discoveredVenue
    }

    var canSave: Bool {
        selectedVenue != nil &&
        !drinkName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with subtitle
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Add Rating")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.primary)

                            Text("Log a drink you tried")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                        // Venue Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Venue")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)

                            if let venue = selectedVenue {
                                VenueSelectionCard(venue: venue, onClear: {
                                    selectedVenue = nil
                                })
                            } else {
                                Button(action: {
                                    showingVenueSearch = true
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 18))
                                            .foregroundColor(.secondary)

                                        Text("Search for a venue...")
                                            .font(.system(size: 16))
                                            .foregroundColor(.secondary)

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(16)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)

                        // Category Selection
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Category")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)

                            // Category pills
                            HStack(spacing: 10) {
                                ForEach(DrinkCategory.allCases, id: \.self) { category in
                                    CategoryPill(
                                        category: category,
                                        isSelected: drinkCategory == category,
                                        onTap: {
                                            drinkCategory = category
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Conditional Form based on category
                        if drinkCategory == .wine {
                            WineRatingForm(
                                wineName: $drinkName,
                                wineDetails: $wineDetails,
                                rating: $rating,
                                notes: $notes
                            )
                            .padding(.horizontal, 20)
                        } else if drinkCategory == .beer {
                            BeerRatingForm(
                                beerName: $drinkName,
                                beerDetails: $beerDetails,
                                rating: $rating,
                                notes: $notes
                            )
                            .padding(.horizontal, 20)
                        } else if drinkCategory == .cocktail {
                            CocktailRatingForm(
                                cocktailName: $drinkName,
                                cocktailDetails: $cocktailDetails,
                                rating: $rating,
                                notes: $notes
                            )
                            .padding(.horizontal, 20)
                        } else {
                            // Generic drink form for other
                            GenericDrinkForm(
                                drinkName: $drinkName,
                                rating: $rating,
                                notes: $notes
                            )
                            .padding(.horizontal, 20)
                        }

                        // Bottom spacing for sticky button
                        Spacer(minLength: 80)
                    }
                    .padding(.bottom, 80)
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
                            Text(isSubmitting ? "Saving..." : "Save Rating")
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
            .onAppear {
                setInitialVenue()
            }
        }
    }

    func submitPost() async {
        guard let venue = selectedVenue else { return }

        isSubmitting = true

        // Convert category-specific details to API format
        var beerDetailsReq: BeerDetailsRequest?
        var wineDetailsReq: WineDetailsRequest?
        var cocktailDetailsReq: CocktailDetailsRequest?

        switch drinkCategory {
        case .beer:
            beerDetailsReq = BeerDetailsRequest(
                brewery: beerDetails.brewery ?? "",
                abv: Double(beerDetails.abv ?? "0") ?? 0.0,
                ibu: Int32(beerDetails.ibu ?? "0") ?? 0,
                acidity: beerDetails.mouthfeel?.rawValue ?? "",
                beerStyle: beerDetails.style?.rawValue ?? "",
                serving: beerDetails.servingType?.rawValue ?? ""
            )
        case .wine:
            wineDetailsReq = WineDetailsRequest(
                sweetness: wineDetails.sweetness?.rawValue ?? "",
                body: wineDetails.body?.rawValue ?? "",
                tannin: wineDetails.tannin?.rawValue ?? "",
                acidity: wineDetails.acidity?.rawValue ?? "",
                wineStyle: wineDetails.style?.rawValue ?? ""
            )
        case .cocktail:
            cocktailDetailsReq = CocktailDetailsRequest(
                baseSpirit: cocktailDetails.baseSpirit?.rawValue ?? "",
                cocktailFamily: cocktailDetails.cocktailFamily?.rawValue ?? "",
                preparation: cocktailDetails.preparationStyle?.rawValue ?? "",
                presentation: cocktailDetails.glassType?.rawValue ?? "",
                garnish: cocktailDetails.garnish ?? "",
                sweetness: cocktailDetails.sweetness?.rawValue ?? "",
                booziness: cocktailDetails.booziness?.rawValue ?? "",
                balance: cocktailDetails.balance?.rawValue ?? ""
            )
        case .other:
            break
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
            venueId: discoveredVenue == nil ? venue.id.uuidString : nil,
            drinkName: drinkName,
            drinkCategory: drinkCategory.rawValue,
            stars: rating,
            notes: notes,
            beerDetails: beerDetailsReq,
            wineDetails: wineDetailsReq,
            cocktailDetails: cocktailDetailsReq,
            venueDetails: venueDetailsReq
        )

        isSubmitting = false

        if success {
            dismiss()
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
    @Binding var rating: Int
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

                // Rating section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Rating")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)

                    HStack {
                        Spacer()
                        StarRatingView(
                            rating: rating,
                            size: 36,
                            interactive: true,
                            onRatingChanged: { newRating in
                                rating = newRating
                            }
                        )
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

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

