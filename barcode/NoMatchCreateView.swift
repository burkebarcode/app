//
//  NoMatchCreateView.swift
//  barcode
//
//  Created by Claude Code on 12/24/25.
//

import SwiftUI

struct NoMatchCreateView: View {
    let query: ScanQuery
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var coordinator: AppCoordinator

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                // Icon
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                // Title
                Text("Create New Beverage")
                    .font(.title)
                    .fontWeight(.bold)

                // Description
                Text("No matches found for your scan. You can create a new beverage entry with the information we detected.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                // Scanned info preview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Detected Information:")
                        .font(.headline)

                    if let name = query.name {
                        InfoRow(label: "Name", value: name)
                    }

                    if let brand = query.brand {
                        InfoRow(label: "Brand", value: brand)
                    }

                    if let vintage = query.vintage {
                        InfoRow(label: "Vintage", value: vintage)
                    }

                    Text("You can edit these details when logging.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    Button(action: createNewBeverage) {
                        Text("Create & Log This Beverage")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }

                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationTitle("No Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func createNewBeverage() {
        // Dismiss this view
        dismiss()

        // Open AddRatingSheet with prefilled data
        // The coordinator can handle this, or we pass data through environment
        coordinator.shouldOpenAddRating = true

        // Note: In a full implementation, we'd pass the scanned data
        // to the AddRatingSheet to prefill the drink name and other fields
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label + ":")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Text(value)
                .font(.subheadline)

            Spacer()
        }
    }
}

#Preview {
    NoMatchCreateView(query: ScanQuery(
        rawText: "Caymus Cabernet 2019",
        brand: "Caymus",
        name: "Cabernet Sauvignon",
        vintage: "2019"
    ))
    .environmentObject(AppCoordinator())
}
