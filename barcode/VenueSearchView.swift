//
//  VenueSearchView.swift
//  barcode
//
//  Created by Burke Butler on 11/30/25.
//

import SwiftUI

struct VenueSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataStore: DataStore
    @StateObject private var venuesManager = VenuesManager()

    let currentUserId: UUID
    let onVenueSelected: (Venue) -> Void

    @State private var searchText = ""
    @State private var showingCreateVenue = false
    @State private var showingMapSearch = false
    @State private var searchTask: Task<Void, Never>?
    @FocusState private var isSearchFocused: Bool

    var searchResults: [Venue] {
        venuesManager.venues.map { venuesManager.toVenue($0) }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)

                        TextField("Search venues...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 16))
                            .focused($isSearchFocused)

                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider()

                // Results
                if searchResults.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()

                        Image(systemName: "mappin.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("No venues found")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)

                        Text("Can't find your venue?")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)

                        Button(action: {
                            showingCreateVenue = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16))
                                Text("Create Personal Venue")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(12)
                        }

                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(searchResults) { venue in
                                Button(action: {
                                    onVenueSelected(venue)
                                }) {
                                    VenueSearchResultRow(venue: venue)
                                }
                                .buttonStyle(PlainButtonStyle())

                                Divider()
                                    .padding(.leading, 82)
                            }
                        }
                    }

                    // Create venue button at bottom
                    VStack(spacing: 0) {
                        Divider()

                        Button(action: {
                            showingCreateVenue = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)

                                Text("Can't find it? Create personal venue")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.systemGray6))
                        }
                    }
                }
            }
            .navigationTitle("Select Venue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingMapSearch = true
                    }) {
                        Image(systemName: "map.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .onAppear {
                isSearchFocused = true
            }
            .task {
                await venuesManager.fetchVenues()
            }
            .onChange(of: searchText) { _, newValue in
                // Debounce search
                searchTask?.cancel()
                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
                    if !Task.isCancelled {
                        await venuesManager.searchVenues(query: newValue)
                    }
                }
            }
            .sheet(isPresented: $showingCreateVenue) {
                CreateVenueSheet(
                    currentUserId: currentUserId,
                    prefillName: searchText,
                    onVenueCreated: { venue in
                        onVenueSelected(venue)
                    }
                )
                .environmentObject(venuesManager)
            }
            .fullScreenCover(isPresented: $showingMapSearch) {
                MapVenueSearchView(
                    currentUserId: currentUserId,
                    onVenueSelected: { venue in
                        onVenueSelected(venue)
                    }
                )
                .environmentObject(venuesManager)
            }
        }
    }
}

struct VenueSearchResultRow: View {
    let venue: Venue

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
                            .foregroundColor(.gray)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(venue.name)
                        .font(.system(size: 16, weight: .medium))
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

                if let address = venue.address {
                    Text(address)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

struct CreateVenueSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var venuesManager: VenuesManager

    let currentUserId: UUID
    let prefillName: String
    let onVenueCreated: (Venue) -> Void

    @State private var venueName: String
    @State private var venueType: VenueType = .bar
    @State private var city: String = ""
    @State private var address: String = ""
    @State private var isCreating: Bool = false
    @State private var errorMessage: String?

    init(currentUserId: UUID, prefillName: String, onVenueCreated: @escaping (Venue) -> Void) {
        self.currentUserId = currentUserId
        self.prefillName = prefillName
        self.onVenueCreated = onVenueCreated
        _venueName = State(initialValue: prefillName)
    }

    var canSave: Bool {
        !venueName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !city.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // MARK: - Venue Details Card
                        VStack(alignment: .leading, spacing: 18) {
                            Text("Venue Details")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)

                            // Venue Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)

                                TextField("e.g. Corner Pub", text: $venueName)
                                    .font(.system(size: 16))
                                    .padding(14)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .autocorrectionDisabled()
                            }

                            // Venue Type Selector
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Type")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)

                                HStack(spacing: 10) {
                                    ForEach(VenueType.allCases, id: \.self) { type in
                                        VenueTypeButton(
                                            type: type,
                                            isSelected: venueType == type,
                                            onTap: { venueType = type }
                                        )
                                    }
                                }
                            }

                            // Help text
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.blue)

                                Text("This venue will only be visible to you unless promoted by an admin.")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        }
                        .padding(18)
                        .background(Color(.systemBackground))
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 16)

                        // MARK: - Location Card
                        VStack(alignment: .leading, spacing: 18) {
                            HStack {
                                Text("Location")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)

                                Spacer()

                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                            }

                            // City
                            VStack(alignment: .leading, spacing: 8) {
                                Text("City")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)

                                TextField("e.g. San Francisco", text: $city)
                                    .font(.system(size: 16))
                                    .padding(14)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .autocorrectionDisabled()
                            }

                            // Address
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Address (optional)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)

                                TextField("e.g. 123 Main St", text: $address)
                                    .font(.system(size: 16))
                                    .padding(14)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .autocorrectionDisabled()
                            }
                        }
                        .padding(18)
                        .background(Color(.systemBackground))
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 16)

                        // Bottom spacing for fixed button
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.top, 16)
                }

                // MARK: - Fixed Bottom Button
                VStack(spacing: 0) {
                    Divider()

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }

                    Button(action: {
                        Task {
                            isCreating = true
                            errorMessage = nil

                            let createdVenue = await venuesManager.createVenue(
                                name: venueName,
                                description: "",
                                venueType: venueType.rawValue.lowercased(),
                                address: address.isEmpty ? nil : address,
                                city: city.isEmpty ? nil : city,
                                state: nil,
                                country: "US",
                                lat: nil,
                                lng: nil,
                                hasBeer: venueType == .bar,
                                hasWine: venueType == .bar || venueType == .restaurant,
                                hasCocktails: venueType == .bar
                            )

                            isCreating = false

                            if let createdVenue = createdVenue {
                                let venue = venuesManager.toVenue(createdVenue)
                                dismiss()
                                onVenueCreated(venue)
                            } else {
                                errorMessage = venuesManager.errorMessage ?? "Failed to create venue"
                            }
                        }
                    }) {
                        HStack {
                            if isCreating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            }
                            Text(isCreating ? "Creating..." : "Create Venue")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canSave && !isCreating ? Color.blue : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!canSave || isCreating)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle("Create Venue")
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
}

// MARK: - Venue Type Button Component

struct VenueTypeButton: View {
    let type: VenueType
    let isSelected: Bool
    let onTap: () -> Void

    var typeIcon: String {
        switch type {
        case .bar: return "wineglass.fill"
        case .restaurant: return "fork.knife"
        case .other: return "building.2.fill"
        }
    }

    var typeColor: Color {
        switch type {
        case .bar: return Color.purple
        case .restaurant: return Color.orange
        case .other: return Color.gray
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: typeIcon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? typeColor : .secondary)

                Text(type.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? typeColor : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? typeColor.opacity(0.12) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? typeColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
