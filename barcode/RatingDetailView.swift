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
    @State private var detailsExpanded = true

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
            VStack(alignment: .leading, spacing: 20) {

                // MARK: - Title Section
                VStack(alignment: .leading, spacing: 12) {
                    // Date in top-right semantic position
                    HStack {
                        Spacer()
                        Text(rating.dateLogged.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Drink name - larger, more prominent
                    Text(rating.drinkName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    // Category badge and stars - tighter spacing
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: categoryIcon)
                                .font(.system(size: 11))
                                .foregroundColor(categoryColor)
                            Text(rating.category.rawValue.capitalized)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(categoryColor)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(categoryColor.opacity(0.12))
                        .cornerRadius(8)

                        StarRatingView(rating: rating.stars ?? 0, size: 14)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // MARK: - Photo Section
                if !rating.photoNames.isEmpty {
                    VStack(spacing: 12) {
                        if let mainPhoto = rating.photoNames.first {
                            Image(mainPhoto)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 280)
                                .clipped()
                                .cornerRadius(16)
                        }

                        if rating.photoNames.count > 1 {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(rating.photoNames, id: \.self) { photoName in
                                        Image(photoName)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 60, height: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(photoName == rating.photoNames.first ? categoryColor : Color.clear, lineWidth: 2)
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // MARK: - Wine Details
                if let wineDetails = rating.wineDetails {
                    VStack(alignment: .leading, spacing: 16) {
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                detailsExpanded.toggle()
                            }
                        }) {
                            HStack {
                                Text("Wine Details")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: detailsExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if detailsExpanded {
                            VStack(spacing: 14) {
                                if let style = wineDetails.style {
                                    DetailRowModern(label: "Style", value: style.rawValue)
                                }
                                if let sweetness = wineDetails.sweetness {
                                    VisualDetailRow(label: "Sweetness", level: sweetness.rawValue, maxLevel: 5, color: categoryColor)
                                }
                                if let body = wineDetails.body {
                                    VisualDetailRow(label: "Body", level: body.rawValue, maxLevel: 5, color: categoryColor)
                                }
                                if let tannin = wineDetails.tannin {
                                    VisualDetailRow(label: "Tannin", level: tannin.rawValue, maxLevel: 5, color: categoryColor)
                                }
                                if let acidity = wineDetails.acidity {
                                    VisualDetailRow(label: "Acidity", level: acidity.rawValue, maxLevel: 5, color: categoryColor)
                                }
                                if let varietal = wineDetails.varietal {
                                    DetailRowModern(label: "Varietal", value: varietal)
                                }
                                if let region = wineDetails.region {
                                    DetailRowModern(label: "Region", value: region)
                                }
                                if let vintage = wineDetails.vintage {
                                    DetailRowModern(label: "Vintage", value: vintage)
                                }
                                if let winery = wineDetails.winery {
                                    DetailRowModern(label: "Winery", value: winery)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 16)
                }

                // MARK: - Beer Details
                if let beerDetails = rating.beerDetails {
                    VStack(alignment: .leading, spacing: 16) {
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                detailsExpanded.toggle()
                            }
                        }) {
                            HStack {
                                Text("Beer Details")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: detailsExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if detailsExpanded {
                            VStack(spacing: 14) {
                                if let style = beerDetails.style {
                                    DetailRowModern(label: "Style", value: style.rawValue)
                                }
                                if let brewery = beerDetails.brewery {
                                    DetailRowModern(label: "Brewery", value: brewery)
                                }
                                if let abv = beerDetails.abv {
                                    DetailRowModern(label: "ABV", value: abv + "%")
                                }
                                if let ibu = beerDetails.ibu {
                                    DetailRowModern(label: "IBU", value: ibu)
                                }
                                if let servingType = beerDetails.servingType {
                                    DetailRowModern(label: "Serving", value: servingType.rawValue)
                                }
                                if let bitterness = beerDetails.bitterness {
                                    VisualDetailRow(label: "Bitterness", level: bitterness.rawValue, maxLevel: 5, color: categoryColor)
                                }
                                if let hoppiness = beerDetails.hoppiness {
                                    VisualDetailRow(label: "Hoppiness", level: hoppiness.rawValue, maxLevel: 5, color: categoryColor)
                                }
                                if let maltiness = beerDetails.maltiness {
                                    VisualDetailRow(label: "Maltiness", level: maltiness.rawValue, maxLevel: 5, color: categoryColor)
                                }
                                if let mouthfeel = beerDetails.mouthfeel {
                                    VisualDetailRow(label: "Mouthfeel", level: mouthfeel.rawValue, maxLevel: 5, color: categoryColor)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 16)
                }

                // MARK: - Cocktail Details
                if let cocktailDetails = rating.cocktailDetails {
                    VStack(alignment: .leading, spacing: 16) {
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                detailsExpanded.toggle()
                            }
                        }) {
                            HStack {
                                Text("Cocktail Details")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: detailsExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if detailsExpanded {
                            VStack(spacing: 14) {
                                if let baseSpirit = cocktailDetails.baseSpirit {
                                    DetailRowModern(label: "Base Spirit", value: baseSpirit.rawValue)
                                }
                                if let cocktailFamily = cocktailDetails.cocktailFamily {
                                    DetailRowModern(label: "Family", value: cocktailFamily.rawValue)
                                }
                                if let preparationStyle = cocktailDetails.preparationStyle {
                                    DetailRowModern(label: "Preparation", value: preparationStyle.rawValue)
                                }
                                if let glassType = cocktailDetails.glassType {
                                    DetailRowModern(label: "Glass", value: glassType.rawValue)
                                }
                                if let garnish = cocktailDetails.garnish {
                                    DetailRowModern(label: "Garnish", value: garnish)
                                }
                                if let sweetness = cocktailDetails.sweetness {
                                    VisualDetailRow(label: "Sweetness", level: sweetness.rawValue, maxLevel: 5, color: categoryColor)
                                }
                                if let booziness = cocktailDetails.booziness {
                                    VisualDetailRow(label: "Booziness", level: booziness.rawValue, maxLevel: 5, color: categoryColor)
                                }
                                if let balance = cocktailDetails.balance {
                                    VisualDetailRow(label: "Balance", level: balance.rawValue, maxLevel: 5, color: categoryColor)
                                }
                                if let recipeNotes = cocktailDetails.recipeNotes {
                                    DetailRowModern(label: "Recipe", value: recipeNotes)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 16)
                }

                // MARK: - Notes
                if let notes = rating.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Notes")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(notes)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 16)
                }

                // MARK: - Venue (List-style, optional)
                if let venue = venue {
                    Button(action: {
                        // Navigate to venue detail
                    }) {
                        HStack(spacing: 12) {
                            // Venue icon
                            if let imageURL = venue.imageURL {
                                AsyncImage(url: URL(string: imageURL)) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 44, height: 44)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    default:
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(.systemGray5))
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Image(systemName: "mappin.circle.fill")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(.secondary)
                                            )
                                    }
                                }
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray5))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.secondary)
                                    )
                            }

                            VStack(alignment: .leading, spacing: 3) {
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
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 16)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // MARK: - Tags
                if !rating.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tags")
                            .font(.headline)
                            .foregroundColor(.primary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(rating.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(categoryColor.opacity(0.12))
                                        .foregroundColor(categoryColor)
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 16)
                }

                Spacer(minLength: 20)
            }
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

// MARK: - Modern Detail Row (text-only attributes)
struct DetailRowModern: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.footnote)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Visual Detail Row (with dots/progress indicator)
struct VisualDetailRow: View {
    let label: String
    let level: String
    let maxLevel: Int
    let color: Color

    private var levelValue: Int {
        // Map level strings to numeric values
        switch level.lowercased() {
        case "low": return 1
        case "medium-low", "medium low": return 2
        case "medium": return 3
        case "medium-high", "medium high": return 4
        case "high": return 5
        default: return 0
        }
    }

    var body: some View {
        HStack {
            Text(label)
                .font(.footnote)
                .foregroundColor(.secondary)

            Spacer()

            // Visual dots
            HStack(spacing: 4) {
                ForEach(1...maxLevel, id: \.self) { index in
                    Circle()
                        .fill(index <= levelValue ? color : Color(.systemGray5))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
}

// Legacy DetailRow kept for compatibility
struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.primary)
        }
    }
}
