//
//  RatingDetailView.swift
//  barcode
//
//  Created by Burke Butler on 11/18/25.
//

import SwiftUI

struct RatingDetailView: View {
    let rating: Rating
    let venue: Venue?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var postsManager: PostsManager
    @State private var showDeleteAlert = false
    @State private var showEditSheet = false

    var categoryColor: Color {
        switch rating.category {
        case .beer: return .orange
        case .wine: return .purple
        case .cocktail: return .blue
        case .other: return .gray
        }
    }

    var categoryIcon: String {
        switch rating.category {
        case .wine: return "wineglass.fill"
        case .beer: return "mug.fill"
        case .cocktail: return "cup.and.saucer.fill"
        case .other: return "circle.fill"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // MARK: - Hero Header Card
                heroHeader

                // MARK: - Wine-Specific Sections
                if rating.category == .wine, let wineDetails = rating.wineDetails {
                    wineIdentityCard(wineDetails: wineDetails)
                    flavorProfileCard(wineDetails: wineDetails)
                }

                // MARK: - Beer-Specific Sections
                if rating.category == .beer, let beerDetails = rating.beerDetails {
                    beerIdentityCard(beerDetails: beerDetails)
                    beerFlavorProfileCard(beerDetails: beerDetails)
                }

                // MARK: - Cocktail-Specific Sections
                if rating.category == .cocktail, let cocktailDetails = rating.cocktailDetails {
                    cocktailIdentityCard(cocktailDetails: cocktailDetails)
                    cocktailFlavorProfileCard(cocktailDetails: cocktailDetails)
                }

                // MARK: - Tasting Notes
                if let notes = rating.notes, !notes.isEmpty {
                    tastingNotesCard(notes: notes)
                }

                // MARK: - Venue
                if let venue = venue {
                    venueCard(venue: venue)
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        showEditSheet = true
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }

                    Divider()

                    Button(role: .destructive, action: {
                        showDeleteAlert = true
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditRatingSheet(rating: rating, venue: venue)
                .environmentObject(postsManager)
        }
        .alert("Delete Rating", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    let success = await postsManager.deletePost(postId: rating.id.uuidString)
                    if success {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this rating? This action cannot be undone.")
        }
    }

    // MARK: - Hero Header
    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Date - small and subtle
            HStack {
                Spacer()
                Text(rating.dateLogged.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(Color(.tertiaryLabel))
            }

            // Drink Name - Largest element on screen
            Text(rating.drinkName)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(3)

            // Identity chips row (category + quick facts)
            identityChipsRow

            // Rating - Large and prominent with numeric value
            HStack(spacing: 8) {
                StarRatingView(rating: rating.stars ?? 0, size: 20)
                if let stars = rating.stars {
                    Text("\(stars).0")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            .padding(.top, 4)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
    }

    // MARK: - Identity Chips Row
    @ViewBuilder
    private var identityChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Category chip
                IdentityChip(
                    icon: categoryIcon,
                    text: rating.category.rawValue.capitalized,
                    color: categoryColor
                )

                // Wine-specific chips
                if rating.category == .wine, let wineDetails = rating.wineDetails {
                    if let style = wineDetails.style {
                        IdentityChip(text: style.rawValue, color: categoryColor)
                    }
                    if let region = wineDetails.region {
                        IdentityChip(text: region, color: .secondary)
                    }
                    if let vintage = wineDetails.vintage {
                        IdentityChip(text: vintage, color: .secondary)
                    }
                }

                // Beer-specific chips
                if rating.category == .beer, let beerDetails = rating.beerDetails {
                    if let style = beerDetails.style {
                        IdentityChip(text: style.rawValue, color: categoryColor)
                    }
                    if let abv = beerDetails.abv {
                        IdentityChip(text: "\(abv)% ABV", color: .secondary)
                    }
                }

                // Cocktail-specific chips
                if rating.category == .cocktail, let cocktailDetails = rating.cocktailDetails {
                    if let baseSpirit = cocktailDetails.baseSpirit {
                        IdentityChip(text: baseSpirit.rawValue, color: categoryColor)
                    }
                    if let family = cocktailDetails.cocktailFamily {
                        IdentityChip(text: family.rawValue, color: .secondary)
                    }
                }
            }
        }
    }

    // MARK: - Wine Identity Card
    private func wineIdentityCard(wineDetails: WineDetails) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Wine Identity")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                if let varietal = wineDetails.varietal {
                    IdentityRow(label: "Varietal", value: varietal)
                }
                if let region = wineDetails.region {
                    IdentityRow(label: "Region", value: region)
                }
                if let vintage = wineDetails.vintage {
                    IdentityRow(label: "Vintage", value: vintage)
                }
                if let winery = wineDetails.winery {
                    IdentityRow(label: "Winery", value: winery)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }

    // MARK: - Wine Flavor Profile Card
    private func flavorProfileCard(wineDetails: WineDetails) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Flavor Profile")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            VStack(spacing: 16) {
                if let sweetness = wineDetails.sweetness {
                    FlavorProfileRow(
                        label: "Sweetness",
                        level: sweetness,
                        color: categoryColor,
                        leftLabel: "Dry",
                        rightLabel: "Sweet"
                    )
                }
                if let body = wineDetails.body {
                    FlavorProfileRow(
                        label: "Body",
                        level: body,
                        color: categoryColor,
                        leftLabel: "Light",
                        rightLabel: "Full"
                    )
                }
                if let tannin = wineDetails.tannin {
                    FlavorProfileRow(
                        label: "Tannin",
                        level: tannin,
                        color: categoryColor,
                        leftLabel: "Low",
                        rightLabel: "High"
                    )
                }
                if let acidity = wineDetails.acidity {
                    FlavorProfileRow(
                        label: "Acidity",
                        level: acidity,
                        color: categoryColor,
                        leftLabel: "Low",
                        rightLabel: "High"
                    )
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }

    // MARK: - Beer Identity Card
    private func beerIdentityCard(beerDetails: BeerDetails) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Beer Identity")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                if let brewery = beerDetails.brewery {
                    IdentityRow(label: "Brewery", value: brewery)
                }
                if let style = beerDetails.style {
                    IdentityRow(label: "Style", value: style.rawValue)
                }
                if let abv = beerDetails.abv {
                    IdentityRow(label: "ABV", value: abv + "%")
                }
                if let ibu = beerDetails.ibu {
                    IdentityRow(label: "IBU", value: ibu)
                }
                if let servingType = beerDetails.servingType {
                    IdentityRow(label: "Serving", value: servingType.rawValue)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }

    // MARK: - Beer Flavor Profile Card
    private func beerFlavorProfileCard(beerDetails: BeerDetails) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Flavor Profile")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            VStack(spacing: 16) {
                if let bitterness = beerDetails.bitterness {
                    FlavorProfileRow(
                        label: "Bitterness",
                        level: bitterness,
                        color: categoryColor,
                        leftLabel: "Low",
                        rightLabel: "High"
                    )
                }
                if let hoppiness = beerDetails.hoppiness {
                    FlavorProfileRow(
                        label: "Hoppiness",
                        level: hoppiness,
                        color: categoryColor,
                        leftLabel: "Low",
                        rightLabel: "High"
                    )
                }
                if let maltiness = beerDetails.maltiness {
                    FlavorProfileRow(
                        label: "Maltiness",
                        level: maltiness,
                        color: categoryColor,
                        leftLabel: "Low",
                        rightLabel: "High"
                    )
                }
                if let mouthfeel = beerDetails.mouthfeel {
                    FlavorProfileRow(
                        label: "Mouthfeel",
                        level: mouthfeel,
                        color: categoryColor,
                        leftLabel: "Light",
                        rightLabel: "Full"
                    )
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }

    // MARK: - Cocktail Identity Card
    private func cocktailIdentityCard(cocktailDetails: CocktailDetails) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cocktail Identity")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                if let baseSpirit = cocktailDetails.baseSpirit {
                    IdentityRow(label: "Base Spirit", value: baseSpirit.rawValue)
                }
                if let family = cocktailDetails.cocktailFamily {
                    IdentityRow(label: "Family", value: family.rawValue)
                }
                if let prep = cocktailDetails.preparationStyle {
                    IdentityRow(label: "Preparation", value: prep.rawValue)
                }
                if let glass = cocktailDetails.glassType {
                    IdentityRow(label: "Glass", value: glass.rawValue)
                }
                if let garnish = cocktailDetails.garnish {
                    IdentityRow(label: "Garnish", value: garnish)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }

    // MARK: - Cocktail Flavor Profile Card
    private func cocktailFlavorProfileCard(cocktailDetails: CocktailDetails) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Flavor Profile")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            VStack(spacing: 16) {
                if let sweetness = cocktailDetails.sweetness {
                    FlavorProfileRow(
                        label: "Sweetness",
                        level: sweetness,
                        color: categoryColor,
                        leftLabel: "Dry",
                        rightLabel: "Sweet"
                    )
                }
                if let booziness = cocktailDetails.booziness {
                    FlavorProfileRow(
                        label: "Booziness",
                        level: booziness,
                        color: categoryColor,
                        leftLabel: "Light",
                        rightLabel: "Strong"
                    )
                }
                if let balance = cocktailDetails.balance {
                    FlavorProfileRow(
                        label: "Balance",
                        level: balance,
                        color: categoryColor,
                        leftLabel: "Unbalanced",
                        rightLabel: "Balanced"
                    )
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }

    // MARK: - Tasting Notes Card
    private func tastingNotesCard(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tasting Notes")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            Text(notes)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }

    // MARK: - Venue Card
    private func venueCard(venue: Venue) -> some View {
        Button(action: {
            // Navigate to venue detail
        }) {
            HStack(spacing: 14) {
                // Venue icon
                if let imageURL = venue.imageURL {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 52, height: 52)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        default:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray5))
                                .frame(width: 52, height: 52)
                                .overlay(
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.secondary)
                                )
                        }
                    }
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("ENJOYED AT")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .tracking(0.5)

                    Text(venue.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    HStack(spacing: 4) {
                        Text(venue.city)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(venue.type.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Views

struct IdentityChip: View {
    var icon: String? = nil
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)
            }
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .cornerRadius(8)
    }
}

struct IdentityRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct FlavorProfileRow: View {
    let label: String
    let level: TastingLevel
    let color: Color
    let leftLabel: String
    let rightLabel: String

    private var levelValue: Int {
        switch level {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            // Dot indicator
            HStack(spacing: 6) {
                ForEach(1...3, id: \.self) { index in
                    Circle()
                        .fill(index <= levelValue ? color : Color(.systemGray5))
                        .frame(width: 12, height: 12)
                }
            }

            // Context labels
            HStack {
                Text(leftLabel)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text(rightLabel)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// Alternative FlavorProfileRow for SweetnessLevel
extension FlavorProfileRow {
    init(label: String, level: SweetnessLevel, color: Color, leftLabel: String, rightLabel: String) {
        self.label = label
        self.color = color
        self.leftLabel = leftLabel
        self.rightLabel = rightLabel

        // Convert SweetnessLevel to TastingLevel (4 levels -> 3 levels)
        let tastingLevel: TastingLevel
        switch level {
        case .dry: tastingLevel = .low
        case .offDry: tastingLevel = .low
        case .semiSweet: tastingLevel = .medium
        case .sweet: tastingLevel = .high
        }
        self.level = tastingLevel
    }
}

// Alternative FlavorProfileRow for WineBody
extension FlavorProfileRow {
    init(label: String, level: WineBody, color: Color, leftLabel: String, rightLabel: String) {
        self.label = label
        self.color = color
        self.leftLabel = leftLabel
        self.rightLabel = rightLabel

        // Convert WineBody to TastingLevel (3 levels)
        let tastingLevel: TastingLevel
        switch level {
        case .light: tastingLevel = .low
        case .medium: tastingLevel = .medium
        case .full: tastingLevel = .high
        }
        self.level = tastingLevel
    }
}

// Alternative FlavorProfileRow for FlavorLevel
extension FlavorProfileRow {
    init(label: String, level: FlavorLevel, color: Color, leftLabel: String, rightLabel: String) {
        self.label = label
        self.color = color
        self.leftLabel = leftLabel
        self.rightLabel = rightLabel

        // Convert FlavorLevel to TastingLevel
        let tastingLevel: TastingLevel
        switch level {
        case .low: tastingLevel = .low
        case .moderate: tastingLevel = .medium
        case .high: tastingLevel = .high
        }
        self.level = tastingLevel
    }
}

// Alternative FlavorProfileRow for Mouthfeel
extension FlavorProfileRow {
    init(label: String, level: Mouthfeel, color: Color, leftLabel: String, rightLabel: String) {
        self.label = label
        self.color = color
        self.leftLabel = leftLabel
        self.rightLabel = rightLabel

        // Convert Mouthfeel to TastingLevel (4 levels -> 3)
        let tastingLevel: TastingLevel
        switch level {
        case .light: tastingLevel = .low
        case .medium: tastingLevel = .medium
        case .full: tastingLevel = .high
        case .creamy: tastingLevel = .high
        }
        self.level = tastingLevel
    }
}

// Alternative FlavorProfileRow for BalanceLevel
extension FlavorProfileRow {
    init(label: String, level: BalanceLevel, color: Color, leftLabel: String, rightLabel: String) {
        self.label = label
        self.color = color
        self.leftLabel = leftLabel
        self.rightLabel = rightLabel

        // Convert BalanceLevel to TastingLevel
        let tastingLevel: TastingLevel
        switch level {
        case .low: tastingLevel = .low
        case .medium: tastingLevel = .medium
        case .high: tastingLevel = .high
        }
        self.level = tastingLevel
    }
}

// MARK: - Edit Rating Sheet
struct EditRatingSheet: View {
    let rating: Rating
    let venue: Venue?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var postsManager: PostsManager

    @State private var drinkName: String
    @State private var stars: Int
    @State private var notes: String
    @State private var wineDetails: WineDetails
    @State private var beerDetails: BeerDetails
    @State private var cocktailDetails: CocktailDetails
    @State private var isSubmitting = false

    init(rating: Rating, venue: Venue?) {
        self.rating = rating
        self.venue = venue
        _drinkName = State(initialValue: rating.drinkName)
        _stars = State(initialValue: rating.stars ?? 3)
        _notes = State(initialValue: rating.notes ?? "")
        _wineDetails = State(initialValue: rating.wineDetails ?? WineDetails(varietal: nil, region: nil, vintage: nil, style: nil, sweetness: nil, body: nil, tannin: nil, acidity: nil, winery: nil))
        _beerDetails = State(initialValue: rating.beerDetails ?? BeerDetails(style: nil, brewery: nil, abv: nil, ibu: nil, servingType: nil, bitterness: nil, hoppiness: nil, maltiness: nil, mouthfeel: nil))
        _cocktailDetails = State(initialValue: rating.cocktailDetails ?? CocktailDetails(baseSpirit: nil, cocktailFamily: nil, preparationStyle: nil, glassType: nil, garnish: nil, sweetness: nil, booziness: nil, balance: nil, recipeNotes: nil))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Edit Rating")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // Conditional Form based on category
                    if rating.category == .wine {
                        WineRatingForm(
                            wineName: $drinkName,
                            wineDetails: $wineDetails,
                            rating: $stars,
                            notes: $notes
                        )
                        .padding(.horizontal, 20)
                    } else if rating.category == .beer {
                        BeerRatingForm(
                            beerName: $drinkName,
                            beerDetails: $beerDetails,
                            rating: $stars,
                            notes: $notes
                        )
                        .padding(.horizontal, 20)
                    } else if rating.category == .cocktail {
                        CocktailRatingForm(
                            cocktailName: $drinkName,
                            cocktailDetails: $cocktailDetails,
                            rating: $stars,
                            notes: $notes
                        )
                        .padding(.horizontal, 20)
                    } else {
                        GenericDrinkForm(
                            drinkName: $drinkName,
                            rating: $stars,
                            notes: $notes
                        )
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 80)
                }
                .padding(.bottom, 80)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isSubmitting ? "Saving..." : "Save") {
                        Task {
                            await saveChanges()
                        }
                    }
                    .disabled(isSubmitting || drinkName.isEmpty)
                }
            }
        }
    }

    private func saveChanges() async {
        isSubmitting = true

        // Convert details back to request format
        var wineDetailsReq: WineDetailsRequest? = nil
        var beerDetailsReq: BeerDetailsRequest? = nil
        var cocktailDetailsReq: CocktailDetailsRequest? = nil

        switch rating.category {
        case .wine:
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
        case .beer:
            beerDetailsReq = BeerDetailsRequest(
                brewery: beerDetails.brewery ?? "",
                abv: Double(beerDetails.abv ?? "0") ?? 0.0,
                ibu: Int32(beerDetails.ibu ?? "0") ?? 0,
                acidity: "",
                beerStyle: beerDetails.style?.rawValue ?? "",
                serving: beerDetails.servingType?.rawValue ?? ""
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

        // Convert empty notes to nil
        let notesValue = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes

        let success = await postsManager.updatePost(
            postId: rating.id.uuidString,
            drinkName: drinkName,
            stars: stars,
            notes: notesValue,
            beerDetails: beerDetailsReq,
            wineDetails: wineDetailsReq,
            cocktailDetails: cocktailDetailsReq
        )

        isSubmitting = false

        if success {
            // Refresh the posts list to get the updated data
            await postsManager.fetchPosts()
            dismiss()
        } else {
            // Show error message if failed
            print("Failed to update post")
        }
    }
}
