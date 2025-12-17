//
//  DrinkCollectionDetailView.swift
//  barcode
//
//  Created by Claude on 12/17/25.
//

import SwiftUI

struct DrinkCollectionDetailView: View {
    let collection: DrinkCollection
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var postsManager: PostsManager
    @EnvironmentObject var coordinator: AppCoordinator

    @State private var showingAddTasting = false

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

    // Calculate averaged wine details from tastings that have them
    var averagedWineDetails: (
        sweetness: Double?,
        body: Double?,
        tannin: Double?,
        acidity: Double?
    )? {
        guard collection.category == .wine else { return nil }

        let tastingsWithDetails = collection.tastings.compactMap { $0.wineDetails }
        guard !tastingsWithDetails.isEmpty else { return nil }

        // Helper to convert levels to numeric values
        func levelValue(_ level: String?) -> Double? {
            guard let level = level else { return nil }
            switch level.lowercased() {
            case "low": return 1.0
            case "medium", "off-dry", "semi-sweet": return 2.0
            case "high", "sweet": return 3.0
            case "dry": return 1.0
            case "light": return 1.0
            case "full": return 3.0
            default: return nil
            }
        }

        // Calculate averages
        let sweetnessValues = tastingsWithDetails.compactMap { levelValue($0.sweetness?.rawValue) }
        let bodyValues = tastingsWithDetails.compactMap { levelValue($0.body?.rawValue) }
        let tanninValues = tastingsWithDetails.compactMap { levelValue($0.tannin?.rawValue) }
        let acidityValues = tastingsWithDetails.compactMap { levelValue($0.acidity?.rawValue) }

        let avgSweetness = sweetnessValues.isEmpty ? nil : sweetnessValues.reduce(0, +) / Double(sweetnessValues.count)
        let avgBody = bodyValues.isEmpty ? nil : bodyValues.reduce(0, +) / Double(bodyValues.count)
        let avgTannin = tanninValues.isEmpty ? nil : tanninValues.reduce(0, +) / Double(tanninValues.count)
        let avgAcidity = acidityValues.isEmpty ? nil : acidityValues.reduce(0, +) / Double(acidityValues.count)

        // Only return if at least one average exists
        guard avgSweetness != nil || avgBody != nil || avgTannin != nil || avgAcidity != nil else {
            return nil
        }

        return (sweetness: avgSweetness, body: avgBody, tannin: avgTannin, acidity: avgAcidity)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Hero Header
                VStack(spacing: 12) {
                    // Drink name
                    Text(collection.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)

                    // Stats row
                    HStack(spacing: 20) {
                        // Average rating
                        if let avgRating = collection.averageRating {
                            VStack(spacing: 4) {
                                HStack(spacing: 3) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.yellow)
                                    Text(String(format: "%.1f", avgRating))
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                Text("Average")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Divider()
                            .frame(height: 40)

                        // Times tried
                        VStack(spacing: 4) {
                            Text("\(collection.timesTried)")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("Tastings")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Divider()
                            .frame(height: 40)

                        // Last tried
                        if let lastTried = collection.lastTried {
                            VStack(spacing: 4) {
                                let formatter = RelativeDateTimeFormatter()
                                Text(formatter.localizedString(for: lastTried, relativeTo: Date()))
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Text("Last tried")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)

                // MARK: - Flavor Profile Card (only if we have averaged details)
                if let wineDetails = averagedWineDetails {
                    flavorProfileCard(wineDetails: wineDetails)
                }

                // MARK: - Log Another Tasting Button
                Button(action: {
                    showingAddTasting = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)

                        Text("Log another tasting")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())

                // MARK: - Your Tastings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Tastings")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 4)

                    ForEach(collection.tastings) { tasting in
                        let venue = dataStore.getVenue(for: tasting)
                        NavigationLink(destination: RatingDetailView(rating: tasting, venue: venue)
                            .environmentObject(postsManager)) {
                            TastingRowCard(tasting: tasting, venue: venue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddTasting) {
            AddRatingSheet(
                initialDrinkName: collection.name,
                initialCategory: collection.category,
                initialVarietal: collection.latestTasting?.wineDetails?.varietal,
                initialWineStyle: collection.latestTasting?.wineDetails?.style
            )
            .environmentObject(dataStore)
            .environmentObject(postsManager)
            .environmentObject(coordinator)
        }
    }

    // MARK: - Flavor Profile Card
    @ViewBuilder
    func flavorProfileCard(wineDetails: (sweetness: Double?, body: Double?, tannin: Double?, acidity: Double?)) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Flavor Profile")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            VStack(spacing: 14) {
                // Sweetness
                if let sweetness = wineDetails.sweetness {
                    AveragedFlavorRow(label: "Sweetness", value: sweetness)
                }

                // Body
                if let body = wineDetails.body {
                    AveragedFlavorRow(label: "Body", value: body)
                }

                // Tannin
                if let tannin = wineDetails.tannin {
                    AveragedFlavorRow(label: "Tannin", value: tannin)
                }

                // Acidity
                if let acidity = wineDetails.acidity {
                    AveragedFlavorRow(label: "Acidity", value: acidity)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Tasting Row Card
struct TastingRowCard: View {
    let tasting: Rating
    let venue: Venue?

    var body: some View {
        HStack(spacing: 12) {
            // Photo or placeholder
            if let firstMedia = tasting.media?.first {
                AsyncImage(url: URL(string: firstMedia.url)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    default:
                        placeholderThumbnail
                    }
                }
            } else {
                placeholderThumbnail
            }

            VStack(alignment: .leading, spacing: 6) {
                // Rating + date
                HStack(spacing: 6) {
                    if let stars = tasting.stars {
                        StarRatingView(rating: stars, size: 14)
                    }

                    Text("•")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Text(tasting.relativeTime)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                // Venue
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

                // Notes preview
                if let notes = tasting.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    var placeholderThumbnail: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray6))
            .frame(width: 60, height: 60)
    }
}

// MARK: - Averaged Flavor Row
struct AveragedFlavorRow: View {
    let label: String
    let value: Double

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)

            HStack(spacing: 8) {
                ForEach(1...3, id: \.self) { index in
                    Circle()
                        .fill(Double(index) <= value.rounded() ? Color.purple : Color(.systemGray5))
                        .frame(width: 12, height: 12)
                }
            }

            Spacer()
        }
    }
}
