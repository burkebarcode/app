//
//  MapVenueSearchView.swift
//  barcode
//
//  Created by Claude on 12/7/25.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine
import Contacts

struct IdentifiedMapItem: Identifiable, Equatable {
    let id = UUID()
    let item: MKMapItem

    var coordinate: CLLocationCoordinate2D {
        // Prefer placemark coordinate; fall back to location coordinate; default to (0,0)
        let placemarkCoord = item.placemark.coordinate
        if CLLocationCoordinate2DIsValid(placemarkCoord) {
            return placemarkCoord
        }
        let locCoord = item.location.coordinate
        if CLLocationCoordinate2DIsValid(locCoord) {
            return locCoord
        }
        return CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
}

extension Array where Element == MKMapItem {
    func identified() -> [IdentifiedMapItem] {
        map(IdentifiedMapItem.init)
    }
}

@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}

struct MapVenueSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchManager = MapSearchManager()

    let currentUserId: UUID
    let onVenueSelected: (Venue) -> Void

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedPlace: IdentifiedMapItem?
    @State private var showingPlaceDetails = false

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // Map
                Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: searchManager.searchResults.identified()) { place in
                    MapAnnotation(coordinate: place.coordinate) {
                        MapMarkerView(
                            place: place.item,
                            isSelected: selectedPlace?.id == place.id
                        )
                        .onTapGesture {
                            selectedPlace = place
                            showingPlaceDetails = true
                        }
                    }
                }
                .ignoresSafeArea()

                // Search results overlay
                VStack(spacing: 0) {
                    Spacer()

                    if searchManager.isSearching {
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.2)
                            Text("Searching nearby...")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 8)
                        .padding(.bottom, 100)
                    } else if !searchManager.searchResults.isEmpty {
                        VenueResultsList(
                            results: searchManager.sortedByDistance(from: locationManager.location).identified(),
                            userLocation: locationManager.location,
                            onPlaceSelected: { place in
                                selectedPlace = place
                                showingPlaceDetails = true
                            }
                        )
                        .frame(height: 280)
                    }
                }

                // Search button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            searchNearby()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Search This Area")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(25)
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        Spacer()
                    }
                    .padding(.top, 16)

                    Spacer()
                }
            }
            .navigationTitle("Nearby Venues")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        if let location = locationManager.location {
                            centerOnUserLocation(location)
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .onAppear {
                if let location = locationManager.location {
                    centerOnUserLocation(location)
                    searchNearby()
                }
            }
            .onChange(of: locationManager.location) { oldLocation, newLocation in
                if let location = newLocation, oldLocation == nil {
                    // First time getting location, center and search
                    centerOnUserLocation(location)
                    searchNearby()
                }
            }
            .sheet(isPresented: $showingPlaceDetails) {
                if let place = selectedPlace {
                    PlaceDetailsSheet(
                        place: place.item,
                        currentUserId: currentUserId,
                        onUseVenue: { venue in
                            dismiss()
                            onVenueSelected(venue)
                        }
                    )
                }
            }
        }
    }

    private func centerOnUserLocation(_ location: CLLocation) {
        region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }

    private func searchNearby() {
        Task {
            await searchManager.searchNearby(center: region.center, radius: 2000)
        }
    }
}

// MARK: - Map Marker View

struct MapMarkerView: View {
    let place: MKMapItem
    let isSelected: Bool

    var categoryIcon: String {
        switch place.pointOfInterestCategory {
        case .some(.restaurant):
            return "fork.knife"
        case .some(.brewery), .some(.winery):
            return "wineglass.fill"
        case .some(.cafe):
            return "cup.and.saucer.fill"
        default:
            return "mappin.circle.fill"
        }
    }

    var categoryColor: Color {
        switch place.pointOfInterestCategory {
        case .some(.restaurant):
            return .orange
        case .some(.brewery), .some(.winery):
            return .purple
        case .some(.cafe):
            return .brown
        default:
            return .blue
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            // Pin circle
            ZStack {
                Circle()
                    .fill(isSelected ? categoryColor : categoryColor.opacity(0.9))
                    .frame(width: isSelected ? 44 : 36, height: isSelected ? 44 : 36)
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)

                Image(systemName: categoryIcon)
                    .font(.system(size: isSelected ? 20 : 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: isSelected ? 3 : 2)
                    .frame(width: isSelected ? 44 : 36, height: isSelected ? 44 : 36)
            )

            // Pin point
            if isSelected {
                Triangle()
                    .fill(categoryColor)
                    .frame(width: 12, height: 8)
                    .offset(y: -4)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

// Triangle shape for pin point
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Venue Results List

struct VenueResultsList: View {
    let results: [IdentifiedMapItem]
    let userLocation: CLLocation?
    let onPlaceSelected: (IdentifiedMapItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Nearby Venues")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                Text("\(results.count) found")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            Divider()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(results, id: \.id) { place in
                        VenueResultCard(
                            place: place.item,
                            distance: userLocation?.distance(from: CLLocation(
                                latitude: place.coordinate.latitude,
                                longitude: place.coordinate.longitude
                            ))
                        )
                        .onTapGesture {
                            onPlaceSelected(place)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
    }
}

// MARK: - Venue Result Card

struct VenueResultCard: View {
    let place: MKMapItem
    let distance: CLLocationDistance?

    var distanceText: String {
        guard let distance = distance else { return "" }
        let miles = distance / 1609.34
        if miles < 0.1 {
            return "nearby"
        } else if miles < 1.0 {
            return String(format: "%.1f mi", miles)
        } else {
            return String(format: "%.1f mi", miles)
        }
    }

    var categoryIcon: String {
        switch place.pointOfInterestCategory {
        case .some(.restaurant):
            return "fork.knife"
        case .some(.cafe):
            return "cup.and.saucer"
        case .some(.brewery), .some(.winery):
            return "wineglass"
        default:
            return "mappin.circle"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: categoryIcon)
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name ?? "Unknown")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if let category = place.pointOfInterestCategory {
                        Text(categoryDisplayName(category))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }

            if distance != nil {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(distanceText)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .frame(width: 180)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func categoryDisplayName(_ category: MKPointOfInterestCategory) -> String {
        switch category {
        case .restaurant: return "Restaurant"
        case .cafe: return "Cafe"
        case .brewery: return "Brewery"
        case .winery: return "Winery"
        default: return "Venue"
        }
    }
}

// MARK: - Place Details Sheet

struct PlaceDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var venuesManager: VenuesManager

    let place: MKMapItem
    let currentUserId: UUID
    let onUseVenue: (Venue) -> Void

    @State private var isCreating = false
    @State private var errorMessage: String?

    var venueType: String {
        switch place.pointOfInterestCategory {
        case .some(.restaurant):
            return "restaurant"
        case .some(.brewery), .some(.winery):
            return "bar"
        default:
            return "other"
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(place.name ?? "Unknown Venue")
                            .font(.system(size: 24, weight: .bold))

                        if let category = place.pointOfInterestCategory {
                            HStack(spacing: 6) {
                                Image(systemName: categoryIcon)
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                                Text(categoryDisplayName(category))
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    Divider()

                    // Address
                    if let address = formattedAddress {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Address", systemImage: "mappin.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)

                            Text(address)
                                .font(.system(size: 16))
                        }
                        .padding(.horizontal, 16)
                    }

                    // Phone
                    if let phone = place.phoneNumber {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Phone", systemImage: "phone.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)

                            Text(phone)
                                .font(.system(size: 16))
                        }
                        .padding(.horizontal, 16)
                    }

                    Divider()

                    // Error message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                    }

                    // Action button
                    Button(action: createAndUseVenue) {
                        HStack {
                            if isCreating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            }
                            Text(isCreating ? "Creating..." : "Use This Venue")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isCreating ? Color.gray : Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(isCreating)
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("Venue Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var categoryIcon: String {
        switch place.pointOfInterestCategory {
        case .some(.restaurant):
            return "fork.knife"
        case .some(.brewery), .some(.winery):
            return "wineglass"
        case .some(.cafe):
            return "cup.and.saucer"
        default:
            return "mappin.circle"
        }
    }

    private func categoryDisplayName(_ category: MKPointOfInterestCategory) -> String {
        switch category {
        case .restaurant: return "Restaurant"
        case .cafe: return "Cafe"
        case .brewery: return "Brewery"
        case .winery: return "Winery"
        default: return "Venue"
        }
    }

    private var formattedAddress: String? {
        if let postal = place.placemark.postalAddress {
            let formatter = CNPostalAddressFormatter()
            return formatter.string(from: postal).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let parts: [String] = [
            place.placemark.subThoroughfare,
            place.placemark.thoroughfare,
            place.placemark.locality,
            place.placemark.administrativeArea,
            place.placemark.postalCode
        ].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    private func createAndUseVenue() {
        Task {
            isCreating = true
            errorMessage = nil

            let createdVenue = await venuesManager.createVenue(
                name: place.name ?? "Unknown Venue",
                description: "",
                venueType: venueType,
                address: formattedAddress,
                city: place.placemark.locality,
                state: place.placemark.administrativeArea,
                country: place.placemark.isoCountryCode ?? "US",
                lat: place.placemark.coordinate.latitude,
                lng: place.placemark.coordinate.longitude,
                hasBeer: venueType == "bar",
                hasWine: venueType == "bar" || venueType == "restaurant",
                hasCocktails: venueType == "bar"
            )

            isCreating = false

            if let createdVenue = createdVenue {
                let venue = venuesManager.toVenue(createdVenue)
                dismiss()
                onUseVenue(venue)
            } else {
                errorMessage = venuesManager.errorMessage ?? "Failed to create venue"
            }
        }
    }
}

// MARK: - Map Search Manager

class MapSearchManager: ObservableObject {
    @Published var searchResults: [MKMapItem] = []
    @Published var isSearching = false

    func searchNearby(center: CLLocationCoordinate2D, radius: CLLocationDistance) async {
        await MainActor.run {
            isSearching = true
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "bars restaurants"
        request.region = MKCoordinateRegion(
            center: center,
            latitudinalMeters: radius * 2,
            longitudinalMeters: radius * 2
        )

        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()
            let filtered = response.mapItems.filter { item in
                guard let category = item.pointOfInterestCategory else { return false }
                switch category {
                case .restaurant, .brewery, .winery, .cafe:
                    return true
                default:
                    return false
                }
            }

            await MainActor.run {
                searchResults = filtered
                isSearching = false
            }
        } catch {
            print("Search error: \(error)")
            await MainActor.run {
                isSearching = false
            }
        }
    }

    func sortedByDistance(from location: CLLocation?) -> [MKMapItem] {
        guard let location = location else { return Array(searchResults.prefix(10)) }

        let sorted = searchResults.sorted { item1, item2 in
            let distance1 = location.distance(from: CLLocation(
                latitude: item1.placemark.coordinate.latitude,
                longitude: item1.placemark.coordinate.longitude
            ))
            let distance2 = location.distance(from: CLLocation(
                latitude: item2.placemark.coordinate.latitude,
                longitude: item2.placemark.coordinate.longitude
            ))
            return distance1 < distance2
        }

        // Return only the 10 closest
        return Array(sorted.prefix(10))
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

