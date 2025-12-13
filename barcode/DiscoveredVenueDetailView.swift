//
//  DiscoveredVenueDetailView.swift
//  barcode
//
//  Created by Claude on 12/8/25.
//

import SwiftUI
import MapKit

struct VenueStats {
    let averageRating: Double
    let totalDrinks: Int
    let wineCount: Int
    let beerCount: Int
    let cocktailCount: Int
}

struct DiscoveredVenueDetailView: View {
    let venue: DiscoveredVenue
    @EnvironmentObject var postsManager: PostsManager
    @EnvironmentObject var coordinator: AppCoordinator
    @Environment(\.dismiss) private var dismiss

    @State private var scrollOffset: CGFloat = 0
    @State private var showTitle = false
    @State private var venueReviews: [PostResponse] = []
    @State private var isLoadingReviews = false

    var stats: VenueStats {
        guard !venueReviews.isEmpty else {
            return VenueStats(averageRating: 0, totalDrinks: 0, wineCount: 0, beerCount: 0, cocktailCount: 0)
        }

        let total = venueReviews.count
        let reviewsWithRatings = venueReviews.compactMap { $0.stars }
        let avgRating = reviewsWithRatings.isEmpty ? 0 : Double(reviewsWithRatings.reduce(0, +)) / Double(reviewsWithRatings.count)
        let wineCount = venueReviews.filter { $0.drinkCategory == "wine" }.count
        let beerCount = venueReviews.filter { $0.drinkCategory == "beer" }.count
        let cocktailCount = venueReviews.filter { $0.drinkCategory == "cocktail" }.count

        return VenueStats(
            averageRating: avgRating,
            totalDrinks: total,
            wineCount: wineCount,
            beerCount: beerCount,
            cocktailCount: cocktailCount
        )
    }

    var distanceText: String {
        let miles = venue.distance * 0.000621371
        if miles < 0.1 {
            return "< 0.1 mi"
        } else {
            return String(format: "%.1f mi", miles)
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 16) {
                            // Venue Image / Placeholder
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.15)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.blue.opacity(0.6))
                                )

                            VStack(alignment: .leading, spacing: 6) {
                                Text(venue.name)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.primary)
                                    .lineLimit(2)

                                HStack(spacing: 6) {
                                    Text(distanceText)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)

                                    Text("·")
                                        .foregroundColor(.secondary)

                                    Text(venue.category)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }

                                if let address = venue.address {
                                    Text(address)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                // Open in Maps button
                                Button(action: openInMaps) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "map.fill")
                                            .font(.system(size: 12))
                                        Text("Open in Maps")
                                            .font(.system(size: 13, weight: .medium))
                                    }
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(Color.blue, lineWidth: 1.5)
                                    )
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                    .padding(.horizontal, 16)
                    .padding(.top, 80)

                    // Stats / Summary Card
                    if venueReviews.isEmpty {
                        // Empty State
                        VStack(spacing: 16) {
                            Image(systemName: "wineglass")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary.opacity(0.5))

                            Text("No drinks logged here yet")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)

                            Text("Be the first to rate something from this spot")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 16)
                    } else {
                        // Stats Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                // Average Rating
                                HStack(spacing: 4) {
                                    Text(String(format: "%.1f", stats.averageRating))
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.primary)

                                    Image(systemName: "star.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.orange)
                                }

                                Spacer()

                                // Total drinks
                                Text("\(stats.totalDrinks) drink\(stats.totalDrinks == 1 ? "" : "s") logged")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }

                            // Breakdown pills
                            HStack(spacing: 8) {
                                if stats.wineCount > 0 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "wineglass.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.purple)
                                        Text("Wine \(stats.wineCount)")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.purple.opacity(0.1))
                                    .cornerRadius(12)
                                }

                                if stats.beerCount > 0 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "mug.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.orange)
                                        Text("Beer \(stats.beerCount)")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(12)
                                }

                                if stats.cocktailCount > 0 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "martini.glass.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.blue)
                                        Text("Cocktails \(stats.cocktailCount)")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                                }

                                Spacer()
                            }
                        }
                        .padding(20)
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 16)
                    }

                    // Primary Action Button
                    Button(action: {
                        dismiss()
                        coordinator.logDrinkAtVenue(venue)
                    }) {
                        Text("Log a Drink at This Venue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(16)
                            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    // Reviews Section
                    if !venueReviews.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Recent Logs")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)

                                Text("\(venueReviews.count)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.blue)
                                    .cornerRadius(8)

                                Spacer()
                            }
                            .padding(.horizontal, 16)

                            VStack(spacing: 12) {
                                ForEach(venueReviews.sorted(by: { $0.createdAt > $1.createdAt }), id: \.id) { review in
                                    ReviewCard(review: review)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    // Footer hint
                    Text("Reviews are from Barcode users who've logged drinks at this venue")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 20)
                }
                .padding(.bottom, 40)
            }

            // Sticky Header
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }

                    Spacer()

                    Text("Venue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .opacity(showTitle ? 1 : 0)

                    Spacer()

                    // Placeholder for balance
                    Color.clear
                        .frame(width: 32, height: 32)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground).opacity(showTitle ? 1 : 0))
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadVenueReviews()
        }
    }

    func loadVenueReviews() {
        Task {
            isLoadingReviews = true
            do {
                // Fetch posts for this venue using external_place_id
                venueReviews = try await APIService.shared.getPosts(externalPlaceId: venue.id)
                print("Loaded \(venueReviews.count) reviews for venue: \(venue.name)")
            } catch {
                print("Error loading venue reviews: \(error)")
                venueReviews = []
            }
            isLoadingReviews = false
        }
    }

    func openInMaps() {
        let placemark = MKPlacemark(coordinate: venue.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = venue.name
        mapItem.openInMaps(launchOptions: nil)
    }

    func calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let location1 = CLLocation(latitude: lat1, longitude: lon1)
        let location2 = CLLocation(latitude: lat2, longitude: lon2)
        return location1.distance(from: location2)
    }
}

// MARK: - Review Card

struct ReviewCard: View {
    let review: PostResponse

    var categoryColor: Color {
        switch review.drinkCategory {
        case "wine": return .purple
        case "beer": return .orange
        case "cocktail": return .blue
        default: return .gray
        }
    }

    var categoryIcon: String {
        switch review.drinkCategory {
        case "wine": return "wineglass.fill"
        case "beer": return "mug.fill"
        case "cocktail": return "martini.glass.fill"
        default: return "circle.fill"
        }
    }

    var relativeTime: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: review.createdAt) else {
            return "recently"
        }

        let interval = Date().timeIntervalSince(date)
        let days = Int(interval / 86400)
        let hours = Int(interval / 3600)

        if days > 0 {
            return "\(days)d ago"
        } else if hours > 0 {
            return "\(hours)h ago"
        } else {
            return "just now"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    // Drink name and stars
                    HStack(spacing: 8) {
                        Text(review.drinkName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        if let stars = review.stars {
                            HStack(spacing: 2) {
                                ForEach(0..<stars, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }

                    // Category pill and time
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: categoryIcon)
                                .font(.system(size: 10))
                                .foregroundColor(categoryColor)
                            Text(review.drinkCategory.capitalized)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(categoryColor)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(categoryColor.opacity(0.12))
                        .cornerRadius(8)

                        Text(relativeTime)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    // Notes
                    if let notes = review.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}
