//
//  ExploreView.swift
//  barcode
//
//  Created by Burke Butler on 11/30/25.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

enum DrinkTypeFilter: String, CaseIterable {
    case all = "All Drinks"
    case wine = "Wine"
    case beer = "Beer"
    case cocktails = "Cocktails"
    case nonAlcoholic = "Non-alcoholic"
}

struct ExploreView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var postsManager: PostsManager
    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchManager = VenueSearchManager()

    @State private var selectedFilter: DrinkTypeFilter = .all
    @State private var showingFilterSheet = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Explore")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Discover drink spots around you")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)

                        // Filter pills
                        HStack(spacing: 8) {
                            // Location pill
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)

                                Text("Near Me")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(20)

                            // Drink type filter pill
                            Button(action: {
                                showingFilterSheet = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: filterIcon)
                                        .font(.system(size: 16))
                                        .foregroundColor(selectedFilter == .all ? .secondary : filterColor)

                                    Text(selectedFilter.rawValue)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)

                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedFilter == .all ? Color(.systemGray6) : filterColor.opacity(0.15))
                                .cornerRadius(20)
                            }

                            Spacer()
                        }
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 4)

                    // Content
                    if searchManager.isLoading {
                        VStack(spacing: 16) {
                            BarcodeLoader()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 155)
                    } else if let error = searchManager.errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    } else if searchManager.venues.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No venues found nearby")
                                .font(.headline)
                            Text("Try expanding your search area or changing your filters")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(searchManager.venues) { venue in
                                NavigationLink(destination: DiscoveredVenueDetailView(venue: venue)
                                    .environmentObject(postsManager)) {
                                    DiscoveredVenueCard(venue: venue)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 16)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingFilterSheet) {
                DrinkTypeFilterSheet(
                    selectedFilter: $selectedFilter,
                    onDismiss: { showingFilterSheet = false }
                )
            }
            .task {
                await MainActor.run {
                    // If your LocationManager has an explicit `request()` method, call it here.
                    // Otherwise, remove this line.
                }
                if let location = locationManager.location {
                    await searchManager.searchNearby(location: location, drinkFilter: selectedFilter)
                }
            }
            .onReceive(locationManager.objectWillChange) { _ in
                if let location = locationManager.location {
                    Task {
                        await searchManager.searchNearby(location: location, drinkFilter: selectedFilter)
                    }
                }
            }
            .onChange(of: selectedFilter) { _ in
                if let location = locationManager.location {
                    Task {
                        await searchManager.searchNearby(location: location, drinkFilter: selectedFilter)
                    }
                }
            }
            .refreshable {
                if let location = locationManager.location {
                    await searchManager.searchNearby(location: location, drinkFilter: selectedFilter)
                }
            }
        }
    }

    var filterIcon: String {
        switch selectedFilter {
        case .all:
            return "line.3.horizontal.decrease.circle"
        case .wine:
            return "wineglass.fill"
        case .beer:
            return "mug.fill"
        case .cocktails:
            return "martini.glass.fill"
        case .nonAlcoholic:
            return "leaf.fill"
        }
    }

    var filterColor: Color {
        switch selectedFilter {
        case .all:
            return .secondary
        case .wine:
            return .purple
        case .beer:
            return .orange
        case .cocktails:
            return .blue
        case .nonAlcoholic:
            return .green
        }
    }
}

// MARK: - Discovered Venue Card

struct DiscoveredVenueCard: View {
    let venue: DiscoveredVenue

    var distanceText: String {
        let miles = venue.distance * 0.000621371 // meters to miles
        if miles < 0.1 {
            return "< 0.1 mi"
        } else {
            return String(format: "%.1f mi", miles)
        }
    }

    var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.blue.opacity(0.1))
            .frame(width: 80, height: 80)
            .overlay(
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.blue.opacity(0.6))
            )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Venue image - use latest post photo if available
                if let photoUrl = venue.latestPhotoUrl {
                    AsyncImage(url: URL(string: photoUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        default:
                            placeholderImage
                        }
                    }
                } else {
                    placeholderImage
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(venue.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        Text(distanceText)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)

                        Text("·")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)

                        Text(venue.category)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    if let address = venue.address {
                        Text(address)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

struct VenueDetailView: View {
    let venue: Venue
    @EnvironmentObject var dataStore: DataStore

    var venueRatings: [Rating] {
        dataStore.getRatings(for: venue)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Venue image
                if let imageURL = venue.imageURL {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 250)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .frame(height: 250)
                                .clipped()
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 250)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    // Venue info
                    Text(venue.name)
                        .font(.title)
                        .fontWeight(.bold)

                    if let address = venue.address {
                        Label(address, systemImage: "mappin.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text(venue.type.rawValue)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)

                        Text(venue.city)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Offerings
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Offerings")
                            .font(.headline)

                        HStack(spacing: 12) {
                            if venue.hasBeer {
                                Label("Beer", systemImage: "wineglass")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                            }
                            if venue.hasWine {
                                Label("Wine", systemImage: "wineglass.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.purple)
                            }
                            if venue.hasCocktails {
                                Label("Cocktails", systemImage: "cup.and.saucer.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.top, 8)

                    // Ratings section
                    if !venueRatings.isEmpty {
                        Divider()
                            .padding(.vertical, 8)

                        Text("Community Ratings")
                            .font(.headline)

                        ForEach(venueRatings) { rating in
                            RatingCard(rating: rating)
                                .padding(.vertical, 4)
                        }
                    } else {
                        Divider()
                            .padding(.vertical, 8)

                        Text("No ratings yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DrinkTypeFilterSheet: View {
    @Binding var selectedFilter: DrinkTypeFilter
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter options
                VStack(spacing: 0) {
                    ForEach(DrinkTypeFilter.allCases, id: \.self) { filter in
                        Button(action: {
                            selectedFilter = filter
                            onDismiss()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: iconForFilter(filter))
                                    .font(.system(size: 20))
                                    .foregroundColor(colorForFilter(filter))
                                    .frame(width: 32)

                                Text(filter.rawValue)
                                    .font(.system(size: 17))
                                    .foregroundColor(.primary)

                                Spacer()

                                if selectedFilter == filter {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(selectedFilter == filter ? Color.blue.opacity(0.08) : Color.clear)
                        }
                        .buttonStyle(PlainButtonStyle())

                        if filter != DrinkTypeFilter.allCases.last {
                            Divider()
                                .padding(.leading, 64)
                        }
                    }
                }
                .padding(.top, 16)

                Spacer()
            }
            .navigationTitle("Filter by Drink Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    func iconForFilter(_ filter: DrinkTypeFilter) -> String {
        switch filter {
        case .all:
            return "line.3.horizontal.decrease.circle"
        case .wine:
            return "wineglass.fill"
        case .beer:
            return "mug.fill"
        case .cocktails:
            return "martini.glass.fill"
        case .nonAlcoholic:
            return "leaf.fill"
        }
    }

    func colorForFilter(_ filter: DrinkTypeFilter) -> Color {
        switch filter {
        case .all:
            return .secondary
        case .wine:
            return .purple
        case .beer:
            return .orange
        case .cocktails:
            return .blue
        case .nonAlcoholic:
            return .green
        }
    }
}

#Preview {
    ExploreView()
        .environmentObject(DataStore())
}
