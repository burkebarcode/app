//
//  ForYouView.swift
//  barcode
//
//  Phase 3: Personalized Recommendations
//

import SwiftUI

struct ForYouView: View {
    @State private var selectedCategory: String = "wine"
    @State private var recommendations: [RecommendedBeverage] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let categories = ["wine", "beer", "cocktail"]

    var body: some View {
        NavigationView {
            VStack {
                // Category Selector
                Picker("Category", selection: $selectedCategory) {
                    Text("Wine").tag("wine")
                    Text("Beer").tag("beer")
                    Text("Cocktails").tag("cocktail")
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: selectedCategory) { _ in
                    Task {
                        await loadRecommendations()
                    }
                }

                if isLoading {
                    ProgressView("Finding recommendations...")
                        .padding()
                    Spacer()
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        Text("Error loading recommendations")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await loadRecommendations() }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    Spacer()
                } else if recommendations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "star.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("Rate a few bottles to get personalized recommendations!")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 32)
                    }
                    .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(recommendations) { beverage in
                            RecommendationCard(
                                beverage: beverage,
                                onFeedback: { feedbackType in
                                    await handleFeedback(beverage, feedbackType: feedbackType)
                                }
                            )
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("For You")
            .task {
                await loadRecommendations()
            }
        }
    }

    private func loadRecommendations() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await APIService.shared.getRecommendations(category: selectedCategory, limit: 20)
            recommendations = response.recommendations
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func handleFeedback(_ beverage: RecommendedBeverage, feedbackType: String) async {
        do {
            try await APIService.shared.submitFeedback(beverageId: beverage.beverageId, feedbackType: feedbackType)

            // Remove from list if hidden
            if feedbackType == "hide" {
                recommendations.removeAll { $0.id == beverage.id }
            } else {
                // Reload recommendations to reflect updated taste profile
                await loadRecommendations()
            }
        } catch {
            print("Failed to submit feedback: \(error)")
        }
    }
}

struct RecommendationCard: View {
    let beverage: RecommendedBeverage
    let onFeedback: (String) async -> Void

    @State private var isSubmittingFeedback = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(beverage.name)
                        .font(.headline)
                        .lineLimit(2)
                    if let brand = beverage.brand, !brand.isEmpty {
                        Text(brand)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Text(beverage.category.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("\(beverage.matchScore)%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("match")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", beverage.avgRating))
                            .font(.caption)
                        Text("(\(beverage.reviewCount))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Reasons
            if !beverage.reasons.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(beverage.reasons, id: \.self) { reason in
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text(reason)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // Feedback Buttons
            if !isSubmittingFeedback {
                HStack(spacing: 12) {
                    Button {
                        isSubmittingFeedback = true
                        Task {
                            await onFeedback("more_like_this")
                            isSubmittingFeedback = false
                        }
                    } label: {
                        Label("More like this", systemImage: "hand.thumbsup")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)

                    Button {
                        isSubmittingFeedback = true
                        Task {
                            await onFeedback("less_like_this")
                            isSubmittingFeedback = false
                        }
                    } label: {
                        Label("Less like this", systemImage: "hand.thumbsdown")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)

                    Button {
                        isSubmittingFeedback = true
                        Task {
                            await onFeedback("hide")
                            isSubmittingFeedback = false
                        }
                    } label: {
                        Label("Hide", systemImage: "eye.slash")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)
                }
            } else {
                HStack {
                    ProgressView()
                        .frame(height: 30)
                    Text("Updating your taste profile...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ForYouView()
}
