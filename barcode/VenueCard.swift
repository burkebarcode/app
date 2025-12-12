//
//  VenueCard.swift
//  barcode
//
//  Created by Burke Butler on 11/30/25.
//

import SwiftUI

struct VenueCard: View {
    let venue: Venue

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image section
            if let imageURL = venue.imageURL {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                                    .font(.largeTitle)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .font(.largeTitle)
                    )
            }

            // Info section
            VStack(alignment: .leading, spacing: 6) {
                Text(venue.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                if let address = venue.address {
                    Text(address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack {
                    Text(venue.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    // Drink type icons
                    HStack(spacing: 6) {
                        // Beer icon
                        Image(systemName: "mug.fill")
                            .font(.system(size: 14))
                            .foregroundColor(venue.hasBeer ? .orange : .gray.opacity(0.3))

                        // Wine icon
                        Image(systemName: "wineglass.fill")
                            .font(.system(size: 14))
                            .foregroundColor(venue.hasWine ? .purple : .gray.opacity(0.3))

                        // Cocktail icon
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 14))
                            .foregroundColor(venue.hasCocktails ? .blue : .gray.opacity(0.3))
                    }

                    Text(venue.city)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }
            }
            .padding(12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    VenueCard(venue: Venue(
        name: "The Local Pub",
        type: .bar,
        city: "New York",
        address: "123 Main St",
        hasBeer: true,
        hasWine: true,
        hasCocktails: false
    ))
    .padding()
}
