//
//  RatingDetailView.swift
//  barcode
//
//  Created by Burke Butler on 11/18/25.
//

import SwiftUI

struct RatingDetailView: View {
    let rating: Rating
    let venue: Venue
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {

                // MARK: - Title Section Card
                VStack(alignment: .leading, spacing: 10) {
                    // Drink name
                    Text(rating.drinkName)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.primary)

                    // Category badge and stars
                    HStack(spacing: 10) {
                        Text(rating.category.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(categoryColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(categoryColor.opacity(0.15))
                            .cornerRadius(6)

                        StarRatingView(rating: rating.stars, size: 16)

                        Spacer()

                        Text(rating.dateLogged.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // MARK: - Photo Section Card
                if !rating.photoNames.isEmpty {
                    VStack(spacing: 12) {
                        // Main photo
                        if let mainPhoto = rating.photoNames.first {
                            Image(mainPhoto)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 280)
                                .clipped()
                                .cornerRadius(10)
                        }

                        // Thumbnail gallery
                        if rating.photoNames.count > 1 {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(rating.photoNames, id: \.self) { photoName in
                                        Image(photoName)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 60, height: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(photoName == rating.photoNames.first ? categoryColor : Color.clear, lineWidth: 2)
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                }

                // MARK: - Wine Details Card
                if let wineDetails = rating.wineDetails {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Wine Details")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)

                        VStack(spacing: 10) {
                            if let style = wineDetails.style {
                                DetailRow(label: "Style", value: style.rawValue)
                            }
                            if let sweetness = wineDetails.sweetness {
                                DetailRow(label: "Sweetness", value: sweetness.rawValue)
                            }
                            if let body = wineDetails.body {
                                DetailRow(label: "Body", value: body.rawValue)
                            }
                            if let tannin = wineDetails.tannin {
                                DetailRow(label: "Tannin", value: tannin.rawValue)
                            }
                            if let acidity = wineDetails.acidity {
                                DetailRow(label: "Acidity", value: acidity.rawValue)
                            }
                            if let varietal = wineDetails.varietal {
                                DetailRow(label: "Varietal", value: varietal)
                            }
                            if let region = wineDetails.region {
                                DetailRow(label: "Region", value: region)
                            }
                            if let vintage = wineDetails.vintage {
                                DetailRow(label: "Vintage", value: vintage)
                            }
                            if let winery = wineDetails.winery {
                                DetailRow(label: "Winery", value: winery)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                }

                // MARK: - Beer Details Card
                if let beerDetails = rating.beerDetails {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Beer Details")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)

                        VStack(spacing: 10) {
                            if let style = beerDetails.style {
                                DetailRow(label: "Style", value: style.rawValue)
                            }
                            if let brewery = beerDetails.brewery {
                                DetailRow(label: "Brewery", value: brewery)
                            }
                            if let abv = beerDetails.abv {
                                DetailRow(label: "ABV", value: abv + "%")
                            }
                            if let ibu = beerDetails.ibu {
                                DetailRow(label: "IBU", value: ibu)
                            }
                            if let servingType = beerDetails.servingType {
                                DetailRow(label: "Serving", value: servingType.rawValue)
                            }
                            if let bitterness = beerDetails.bitterness {
                                DetailRow(label: "Bitterness", value: bitterness.rawValue)
                            }
                            if let hoppiness = beerDetails.hoppiness {
                                DetailRow(label: "Hoppiness", value: hoppiness.rawValue)
                            }
                            if let maltiness = beerDetails.maltiness {
                                DetailRow(label: "Maltiness", value: maltiness.rawValue)
                            }
                            if let mouthfeel = beerDetails.mouthfeel {
                                DetailRow(label: "Mouthfeel", value: mouthfeel.rawValue)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                }

                // MARK: - Cocktail Details Card
                if let cocktailDetails = rating.cocktailDetails {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cocktail Details")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)

                        VStack(spacing: 10) {
                            if let baseSpirit = cocktailDetails.baseSpirit {
                                DetailRow(label: "Base Spirit", value: baseSpirit.rawValue)
                            }
                            if let cocktailFamily = cocktailDetails.cocktailFamily {
                                DetailRow(label: "Family", value: cocktailFamily.rawValue)
                            }
                            if let preparationStyle = cocktailDetails.preparationStyle {
                                DetailRow(label: "Preparation", value: preparationStyle.rawValue)
                            }
                            if let glassType = cocktailDetails.glassType {
                                DetailRow(label: "Glass", value: glassType.rawValue)
                            }
                            if let garnish = cocktailDetails.garnish {
                                DetailRow(label: "Garnish", value: garnish)
                            }
                            if let sweetness = cocktailDetails.sweetness {
                                DetailRow(label: "Sweetness", value: sweetness.rawValue)
                            }
                            if let booziness = cocktailDetails.booziness {
                                DetailRow(label: "Booziness", value: booziness.rawValue)
                            }
                            if let balance = cocktailDetails.balance {
                                DetailRow(label: "Balance", value: balance.rawValue)
                            }
                            if let recipeNotes = cocktailDetails.recipeNotes {
                                DetailRow(label: "Recipe", value: recipeNotes)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                }

                // MARK: - Notes Card
                if !rating.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)

                        Text(rating.notes)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                }

                // MARK: - Venue Card
                VStack(alignment: .leading, spacing: 8) {
                    Text("Venue")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)

                    Button(action: {
                        // Navigate to venue detail
                    }) {
                        HStack(spacing: 12) {
                            // Venue thumbnail
                            if let imageURL = venue.imageURL {
                                AsyncImage(url: URL(string: imageURL)) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 50, height: 50)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    default:
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 50, height: 50)
                                    }
                                }
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.gray)
                                    )
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(venue.name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)

                                HStack(spacing: 4) {
                                    Image(systemName: "mappin")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)

                                    Text(venue.city)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)

                                    Text("•")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)

                                    Text(venue.type.rawValue)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(14)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 16)

                // MARK: - Tags Card
                if !rating.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(rating.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 13, weight: .medium))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(categoryColor.opacity(0.15))
                                        .foregroundColor(categoryColor)
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                }

                // MARK: - Actions Card
                VStack(spacing: 10) {
                    Button(action: {
                        showEditSheet = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil")
                                .font(.system(size: 15, weight: .medium))
                            Text("Edit Rating")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }

                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                                .font(.system(size: 15, weight: .medium))
                            Text("Delete Rating")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.08))
                        .cornerRadius(8)
                    }
                }
                .padding(14)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .padding(.top, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
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
    let venue: Venue
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var postsManager: PostsManager

    @State private var drinkName: String
    @State private var stars: Int
    @State private var notes: String
    @State private var wineDetails: WineDetails
    @State private var beerDetails: BeerDetails
    @State private var cocktailDetails: CocktailDetails
    @State private var isSubmitting = false

    init(rating: Rating, venue: Venue) {
        self.rating = rating
        self.venue = venue
        _drinkName = State(initialValue: rating.drinkName)
        _stars = State(initialValue: rating.stars)
        _notes = State(initialValue: rating.notes)
        _wineDetails = State(initialValue: rating.wineDetails ?? WineDetails(varietal: nil, region: nil, vintage: nil, style: nil, sweetness: nil, body: nil, tannin: nil, acidity: nil, winery: nil))
        _beerDetails = State(initialValue: rating.beerDetails ?? BeerDetails(style: nil, brewery: nil, abv: nil, ibu: nil, servingType: nil, bitterness: nil, hoppiness: nil, maltiness: nil, mouthfeel: nil))
        _cocktailDetails = State(initialValue: rating.cocktailDetails ?? CocktailDetails(baseSpirit: nil, cocktailFamily: nil, preparationStyle: nil, glassType: nil, garnish: nil, sweetness: nil, booziness: nil, balance: nil, recipeNotes: nil))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Drink Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Drink Name")
                            .font(.system(size: 15, weight: .semibold))
                        TextField("Drink name", text: $drinkName)
                            .font(.system(size: 16))
                            .padding(14)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }

                    // Rating
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rating")
                            .font(.system(size: 15, weight: .semibold))
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= stars ? "star.fill" : "star")
                                    .font(.system(size: 24))
                                    .foregroundColor(star <= stars ? .yellow : .gray)
                                    .onTapGesture {
                                        stars = star
                                    }
                            }
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.system(size: 15, weight: .semibold))
                        TextEditor(text: $notes)
                            .font(.system(size: 16))
                            .frame(height: 100)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }

                    // Category-specific forms would go here
                    // For now, keeping it simple
                }
                .padding()
            }
            .navigationTitle("Edit Rating")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
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
                wineStyle: wineDetails.style?.rawValue ?? ""
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

        let success = await postsManager.updatePost(
            postId: rating.id.uuidString,
            drinkName: drinkName,
            stars: stars,
            notes: notes,
            beerDetails: beerDetailsReq,
            wineDetails: wineDetailsReq,
            cocktailDetails: cocktailDetailsReq
        )

        isSubmitting = false

        if success {
            dismiss()
        }
    }
}

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

