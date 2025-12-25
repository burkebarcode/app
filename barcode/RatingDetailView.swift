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

    // MARK: - Computed Insights

    var scoreContext: (text: String, isPositive: Bool)? {
        guard let currentScore = rating.score ?? rating.stars.map({ Double($0) * 2.0 }) else { return nil }

        // Get all ratings from posts
        let allRatings = postsManager.posts.compactMap { post -> Double? in
            if let score = post.score {
                return score
            } else if let stars = post.stars {
                return Double(stars) * 2.0
            }
            return nil
        }

        guard allRatings.count > 1 else { return nil }

        let average = allRatings.reduce(0, +) / Double(allRatings.count)
        let difference = currentScore - average

        // Calculate percentile
        let sorted = allRatings.sorted()
        let rank = sorted.filter { $0 <= currentScore }.count
        let percentile = (Double(rank) / Double(sorted.count)) * 100

        if percentile >= 90 {
            return ("One of your highest-rated", true)
        } else if percentile >= 75 {
            return ("Well above your average", true)
        } else if difference > 0.3 {
            return ("Above your average", true)
        } else if abs(difference) < 0.3 {
            return ("Right at your average (\(String(format: "%.1f", average)))", false)
        } else {
            return ("Below your average (\(String(format: "%.1f", average)))", false)
        }
    }

    var venueContext: String? {
        guard let currentVenue = venue else { return nil }

        // Count tastings at this venue
        let venuePostsCount = postsManager.posts.filter { post in
            post.venueId == currentVenue.id.uuidString
        }.count

        if venuePostsCount > 1 {
            return "You've logged \(venuePostsCount) drinks here"
        }

        return nil
    }

    func hasWineIdentity(_ wineDetails: WineDetails) -> Bool {
        return wineDetails.varietal != nil ||
               wineDetails.region != nil ||
               wineDetails.vintage != nil ||
               wineDetails.winery != nil
    }

    func hasFlavorProfile(_ wineDetails: WineDetails) -> Bool {
        return wineDetails.sweetness != nil ||
               wineDetails.body != nil ||
               wineDetails.tannin != nil ||
               wineDetails.acidity != nil
    }

    func flavorSummary(for wineDetails: WineDetails) -> String {
        var parts: [String] = []

        // Sweetness
        if let sweetness = wineDetails.sweetness {
            switch sweetness {
            case .dry: parts.append("Dry")
            case .offDry: parts.append("Dry-leaning")
            case .semiSweet: parts.append("Semi-sweet")
            case .sweet: parts.append("Sweet")
            }
        }

        // Body
        if let body = wineDetails.body {
            switch body {
            case .light: parts.append("light-bodied")
            case .medium: parts.append("medium-bodied")
            case .full: parts.append("full-bodied")
            }
        }

        // Acidity
        if let acidity = wineDetails.acidity {
            switch acidity {
            case .low: parts.append("soft acidity")
            case .medium: parts.append("balanced acidity")
            case .high: parts.append("bright acidity")
            }
        }

        return parts.isEmpty ? "" : parts.joined(separator: ", ")
    }

    var insightText: (headline: String, detail: String?)? {
        guard let currentScore = rating.score ?? rating.stars.map({ Double($0) * 2.0 }) else { return nil }

        // Get similar drinks (same category and name if wine with same varietal)
        let similarPosts = postsManager.posts.filter { post in
            guard post.drinkCategory == rating.category.rawValue else { return false }
            guard post.drinkName.lowercased() == rating.drinkName.lowercased() else { return false }

            // For wines, also match varietal
            if rating.category == .wine {
                let thisVarietal = rating.wineDetails?.varietal?.lowercased() ?? ""
                let postVarietal = post.wineDetails?.varietal?.lowercased() ?? ""
                return thisVarietal == postVarietal
            }

            return true
        }

        // Pattern: Multiple tastings of the same drink
        if similarPosts.count > 1 {
            let scores = similarPosts.compactMap { post -> Double? in
                if let score = post.score {
                    return score
                } else if let stars = post.stars {
                    return Double(stars) * 2.0
                }
                return nil
            }.sorted()

            if let lowest = scores.first, let highest = scores.last {
                let avg = scores.reduce(0, +) / Double(scores.count)
                let detail = "\(scores.count) times tried · Avg \(String(format: "%.1f", avg))"

                if currentScore == highest {
                    return ("You consistently enjoy this.", detail)
                } else if currentScore == lowest {
                    return ("This one didn't land as well.", detail)
                } else if abs(currentScore - avg) < 0.5 {
                    return ("This has held up over time.", detail)
                } else {
                    return ("You rate this reliably high.", detail)
                }
            }
        }

        // Pattern: Category preference
        let categoryScores = postsManager.posts.filter { $0.drinkCategory == rating.category.rawValue }
            .compactMap { post -> Double? in
                if let score = post.score {
                    return score
                } else if let stars = post.stars {
                    return Double(stars) * 2.0
                }
                return nil
            }

        if categoryScores.count >= 3 {
            let categoryAvg = categoryScores.reduce(0, +) / Double(categoryScores.count)
            let categoryName = rating.category.rawValue.capitalized

            if currentScore > categoryAvg + 0.5 {
                return ("Exceptional for your palate.", nil)
            } else if currentScore < categoryAvg - 0.5 {
                return ("Not your usual \(categoryName) preference.", nil)
            }
        }

        return nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // MARK: - Hero Header Card
                heroHeader

                // MARK: - Insight Card
                if let insight = insightText {
                    insightCard(headline: insight.headline, detail: insight.detail)
                }

                // MARK: - Photo Gallery
                if let media = rating.media, !media.isEmpty {
                    photoGallery(media: media)
                }

                // MARK: - Wine-Specific Sections
                if rating.category == .wine, let wineDetails = rating.wineDetails {
                    if hasWineIdentity(wineDetails) {
                        wineIdentityCard(wineDetails: wineDetails)
                    }
                    if hasFlavorProfile(wineDetails) {
                        flavorProfileCard(wineDetails: wineDetails)
                    }
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

                // MARK: - Venue (moved above notes for prominence)
                if let venue = venue {
                    venueCard(venue: venue)
                }

                // MARK: - Tasting Notes
                if let notes = rating.notes, !notes.isEmpty {
                    tastingNotesCard(notes: notes)
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

            // Drink Name
            Text(rating.drinkName)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(3)

            // Identity chips row (category + quick facts)
            identityChipsRow

            // Rating - Large and prominent with numeric value
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    if let score = rating.score {
                        Text(String(format: "%.1f", score))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                    } else if let stars = rating.stars {
                        // Fallback for old star ratings - convert to 0-10 scale
                        Text(String(format: "%.1f", Double(stars) * 2.0))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                    } else {
                        Text("No rating")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }

                // Relative context - elevated as secondary hero line
                if let context = scoreContext {
                    Text(context.text)
                        .font(.system(size: 17))
                        .foregroundColor(context.isPositive ? Color.green.opacity(0.85) : .secondary)
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
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
    }

    // MARK: - Wine Flavor Profile Card
    private func flavorProfileCard(wineDetails: WineDetails) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Flavor Profile")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            // Overall summary
            let summary = flavorSummary(for: wineDetails)
            if !summary.isEmpty {
                Text("Overall: \(summary)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }

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
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
    }

    // MARK: - Beer Identity Card
    private func beerIdentityCard(beerDetails: BeerDetails) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Beer Details")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            VStack(spacing: 14) {
                if let brewery = beerDetails.brewery {
                    BeerDetailRow(label: "Brewery", value: brewery, icon: "building.2")
                }
                if let style = beerDetails.style {
                    BeerDetailRow(label: "Style", value: style.rawValue, icon: "mug")
                }
                if let abv = beerDetails.abv {
                    BeerDetailRow(label: "ABV", value: abv + "%", icon: "percent", prominent: true)
                }
                if let ibu = beerDetails.ibu {
                    BeerDetailRow(label: "IBU", value: ibu, icon: "leaf")
                }
                if let servingType = beerDetails.servingType {
                    BeerDetailRow(label: "Format", value: servingType.rawValue, icon: "wineglass")
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
    }

    // MARK: - Beer Flavor Profile Card
    private func beerFlavorProfileCard(beerDetails: BeerDetails) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Drinkability")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            VStack(spacing: 16) {
                if let bitterness = beerDetails.bitterness {
                    BeerMeterRow(
                        label: "Bitterness",
                        level: bitterness,
                        color: categoryColor,
                        leftLabel: "Mild",
                        rightLabel: "Hoppy"
                    )
                }
                if let maltiness = beerDetails.maltiness {
                    BeerMeterRow(
                        label: "Sweetness",
                        level: maltiness,
                        color: categoryColor,
                        leftLabel: "Dry",
                        rightLabel: "Malty"
                    )
                }
                if let mouthfeel = beerDetails.mouthfeel {
                    BeerMeterRow(
                        label: "Body",
                        level: mouthfeel,
                        color: categoryColor,
                        leftLabel: "Light",
                        rightLabel: "Heavy"
                    )
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
    }

    // MARK: - Cocktail Identity Card
    private func cocktailIdentityCard(cocktailDetails: CocktailDetails) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ingredients & Style")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            VStack(spacing: 14) {
                if let baseSpirit = cocktailDetails.baseSpirit {
                    CocktailDetailRow(label: "Base Spirit", value: baseSpirit.rawValue, icon: "drop.fill")
                }
                if let family = cocktailDetails.cocktailFamily {
                    CocktailDetailRow(label: "Family", value: family.rawValue, icon: "list.bullet")
                }
                if let glass = cocktailDetails.glassType {
                    CocktailDetailRow(label: "Glass", value: glass.rawValue, icon: "wineglass")
                }
                if let prep = cocktailDetails.preparationStyle {
                    CocktailDetailRow(label: "Technique", value: prep.rawValue, icon: "arrow.triangle.2.circlepath")
                }
                if let garnish = cocktailDetails.garnish {
                    CocktailDetailRow(label: "Garnish", value: garnish, icon: "leaf.fill")
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
    }

    // MARK: - Cocktail Flavor Profile Card
    private func cocktailFlavorProfileCard(cocktailDetails: CocktailDetails) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Balance")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            VStack(spacing: 16) {
                if let sweetness = cocktailDetails.sweetness {
                    CocktailMeterRow(
                        label: "Sweetness",
                        level: sweetness,
                        color: categoryColor,
                        leftLabel: "Dry",
                        rightLabel: "Sweet"
                    )
                }
                if let booziness = cocktailDetails.booziness {
                    CocktailMeterRow(
                        label: "Spirit-Forward",
                        level: booziness,
                        color: categoryColor,
                        leftLabel: "Juice-Heavy",
                        rightLabel: "Spirit-Heavy"
                    )
                }
                if let balance = cocktailDetails.balance {
                    CocktailMeterRow(
                        label: "Balance",
                        level: balance,
                        color: categoryColor,
                        leftLabel: "One-Note",
                        rightLabel: "Complex"
                    )
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
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
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
    }

    // MARK: - Insight Card
    private func insightCard(headline: String, detail: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your Pattern")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .tracking(0.3)

            Text(headline)
                .font(.system(size: 16))
                .foregroundColor(.primary)

            if let detail = detail {
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
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

                    if let context = venueContext {
                        Text(context)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
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
            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Photo Gallery
    private func photoGallery(media: [MediaItem]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(media) { mediaItem in
                    AsyncImage(url: URL(string: mediaItem.fullUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 280, height: 280)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        case .failure(_):
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray5))
                                .frame(width: 280, height: 280)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "photo")
                                            .font(.system(size: 32))
                                            .foregroundColor(.secondary)
                                        Text("Failed to load")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                )
                        case .empty:
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray5))
                                .frame(width: 280, height: 280)
                                .overlay(
                                    ProgressView()
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
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

    private var levelDescriptor: String {
        switch level {
        case .low: return leftLabel
        case .medium: return "Medium"
        case .high: return rightLabel
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text("·")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(levelDescriptor)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

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

// MARK: - Beer-Specific Components

struct BeerDetailRow: View {
    let label: String
    let value: String
    let icon: String
    var prominent: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 20)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(prominent ? .body : .subheadline)
                .fontWeight(prominent ? .semibold : .medium)
                .foregroundColor(prominent ? .orange : .primary)
        }
    }
}

struct BeerMeterRow: View {
    let label: String
    let level: FlavorLevel
    let color: Color
    let leftLabel: String
    let rightLabel: String

    private var levelValue: Double {
        switch level {
        case .low: return 1.0
        case .moderate: return 2.0
        case .high: return 3.0
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            // Horizontal meter bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    // Filled portion
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * (levelValue / 3.0), height: 8)
                }
            }
            .frame(height: 8)

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

// Alternative for Mouthfeel
extension BeerMeterRow {
    init(label: String, level: Mouthfeel, color: Color, leftLabel: String, rightLabel: String) {
        self.label = label
        self.color = color
        self.leftLabel = leftLabel
        self.rightLabel = rightLabel

        // Convert Mouthfeel to FlavorLevel
        let flavorLevel: FlavorLevel
        switch level {
        case .light: flavorLevel = .low
        case .medium: flavorLevel = .moderate
        case .full, .creamy: flavorLevel = .high
        }
        self.level = flavorLevel
    }
}

// MARK: - Cocktail-Specific Components

struct CocktailDetailRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.blue)
                .frame(width: 20)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

struct CocktailMeterRow: View {
    let label: String
    let level: BalanceLevel
    let color: Color
    let leftLabel: String
    let rightLabel: String

    private var levelValue: Double {
        switch level {
        case .low: return 1.0
        case .medium: return 2.0
        case .high: return 3.0
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            // Horizontal meter bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    // Filled portion
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * (levelValue / 3.0), height: 8)
                }
            }
            .frame(height: 8)

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

// MARK: - Edit Rating Sheet
struct EditRatingSheet: View {
    let rating: Rating
    let venue: Venue?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var postsManager: PostsManager

    @State private var drinkName: String
    @State private var score: Double
    @State private var notes: String
    @State private var wineDetails: WineDetails
    @State private var beerDetails: BeerDetails
    @State private var cocktailDetails: CocktailDetails
    @State private var isSubmitting = false

    init(rating: Rating, venue: Venue?) {
        self.rating = rating
        self.venue = venue
        _drinkName = State(initialValue: rating.drinkName)
        // Convert stars to score or use score directly
        let initialScore = rating.score ?? (rating.stars.map { Double($0) * 2.0 } ?? 7.5)
        _score = State(initialValue: initialScore)
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
                            score: $score,
                            notes: $notes
                        )
                        .padding(.horizontal, 20)
                    } else if rating.category == .beer {
                        BeerRatingForm(
                            beerName: $drinkName,
                            beerDetails: $beerDetails,
                            score: $score,
                            notes: $notes
                        )
                        .padding(.horizontal, 20)
                    } else if rating.category == .cocktail {
                        CocktailRatingForm(
                            cocktailName: $drinkName,
                            cocktailDetails: $cocktailDetails,
                            score: $score,
                            notes: $notes
                        )
                        .padding(.horizontal, 20)
                    } else {
                        GenericDrinkForm(
                            drinkName: $drinkName,
                            score: $score,
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
            score: score,
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
