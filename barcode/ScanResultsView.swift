//
//  ScanResultsView.swift
//  barcode
//
//  Created by Claude Code on 12/24/25.
//

import SwiftUI

struct ScanResultsView: View {
    let response: ScanBottleResponse
    @Environment(\.dismiss) var dismiss
    @State private var selectedCandidate: BeverageCandidate?
    @State private var showCreateNew = false

    private var highConfidenceMatch: Bool {
        response.candidates.first?.confidence ?? 0 > 0.8
    }

    private var lowConfidenceMatch: Bool {
        response.candidates.first?.confidence ?? 0 < 0.5
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Title and description
                    VStack(spacing: 8) {
                        Text("Possible matches")
                            .font(.title2)
                            .fontWeight(.bold)

                        if lowConfidenceMatch {
                            Text("We found some similar beverages. Tap to view details.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 8)

                    // Match cards
                    ForEach(Array(response.candidates.enumerated()), id: \.element.id) { index, candidate in
                        MatchCard(
                            candidate: candidate,
                            isTopMatch: index == 0 && highConfidenceMatch
                        )
                        .onTapGesture {
                            selectedCandidate = candidate
                        }
                        .padding(.horizontal)
                    }

                    // Don't see your beverage? (only for low confidence)
                    if lowConfidenceMatch {
                        Divider()
                            .padding(.horizontal)
                            .padding(.vertical, 8)

                        Button(action: { showCreateNew = true }) {
                            VStack(spacing: 8) {
                                Text("Don't see your beverage?")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.body)
                                    Text("Create new beverage")
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.blue)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedCandidate) { candidate in
                CandidateDetailView(candidate: candidate)
            }
            .sheet(isPresented: $showCreateNew) {
                CreateNewBeverageView(detectedInfo: response.query)
            }
        }
    }
}

// MARK: - Match Card

struct MatchCard: View {
    let candidate: BeverageCandidate
    let isTopMatch: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top match badge
            if isTopMatch {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("Top match")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }

            // Name and brand
            VStack(alignment: .leading, spacing: 4) {
                Text(candidate.displayName)
                    .font(.title3)
                    .fontWeight(.semibold)

                if let brand = candidate.brand {
                    Text(brand)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if let vintage = candidate.vintage {
                    Text(vintage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Stats row
            HStack(spacing: 16) {
                // Match confidence
                HStack(spacing: 4) {
                    Circle()
                        .fill(confidenceColor)
                        .frame(width: 8, height: 8)
                    Text("\(Int(candidate.confidence * 100))% match")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Rating
                if candidate.avgRating > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", candidate.avgRating))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }

                // Review count
                if candidate.reviewCount > 0 {
                    Text("\(candidate.reviewCount) \(candidate.reviewCount == 1 ? "review" : "reviews")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Tap to view details hint
            HStack {
                Spacer()
                Text("Tap for details")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isTopMatch ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }

    private var confidenceColor: Color {
        if candidate.confidence >= 0.7 {
            return Color(red: 0.2, green: 0.78, blue: 0.35)
        } else if candidate.confidence >= 0.4 {
            return Color(red: 1.0, green: 0.75, blue: 0.2)
        } else {
            return Color(red: 0.95, green: 0.45, blue: 0.45)
        }
    }
}

// MARK: - No Match View

struct NoMatchView: View {
    let query: ScanQuery

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 80))
                .foregroundColor(.gray)

            Text("No matches found")
                .font(.title2)
                .fontWeight(.semibold)

            Text("We couldn't find any beverages matching your scan.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            if let name = query.name {
                Text("Scanned: \(name)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Button(action: {}) {
                Label("Create New Beverage", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}

// MARK: - Candidate Card

struct CandidateCard: View {
    let candidate: BeverageCandidate

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with name and confidence
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(candidate.displayName)
                        .font(.headline)

                    if let brand = candidate.brand {
                        Text(brand)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if let vintage = candidate.vintage {
                        Text("Vintage: \(vintage)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(spacing: 8) {
                    // Personalized match score (if available)
                    if let matchScore = candidate.matchScore {
                        VStack(spacing: 4) {
                            Text("\(matchScore)%")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("for you")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                    }

                    // Confidence badge
                    VStack(spacing: 4) {
                        Text("\(Int(candidate.confidence * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                        Text("match")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .background(confidenceColor.opacity(0.2))
                    .cornerRadius(8)
                }
            }

            Divider()

            // Stats
            HStack(spacing: 24) {
                StatView(
                    icon: "star.fill",
                    value: String(format: "%.1f", candidate.avgRating),
                    label: "Rating"
                )

                StatView(
                    icon: "bubble.left.and.bubble.right.fill",
                    value: "\(candidate.reviewCount)",
                    label: "Reviews"
                )
            }

            // Match reasons (Phase 3: Personalized)
            if let reasons = candidate.matchReasons, !reasons.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Why this matches your taste")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    ForEach(reasons, id: \.self) { reason in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                            Text(reason)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Top reviews
            if !candidate.topReviews.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Reviews")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    ForEach(candidate.topReviews.prefix(2)) { review in
                        ReviewRow(review: review)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private var confidenceColor: Color {
        if candidate.confidence >= 0.7 {
            return .green
        } else if candidate.confidence >= 0.4 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Stat View

struct StatView: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Review Row

struct ReviewRow: View {
    let review: ReviewItem

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Rating
            Text(String(format: "%.1f", review.rating))
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.blue)
                .cornerRadius(4)

            // Note
            if let note = review.note {
                Text(note)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            } else {
                Text("No notes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }

            Spacer()
        }
    }
}

// MARK: - Candidate Detail View

struct CandidateDetailView: View {
    let candidate: BeverageCandidate
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var coordinator: AppCoordinator

    @State private var summary: BeverageSummaryResponse?
    @State private var similar: SimilarBeveragesResponse?
    @State private var isLoadingSummary = false
    @State private var isLoadingSimilar = false
    @State private var summaryError: String?
    @State private var pollAttempts = 0
    private let maxPollAttempts = 5

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(candidate.displayName)
                            .font(.title)
                            .fontWeight(.bold)

                        if let brand = candidate.brand {
                            Text(brand)
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }

                        if let vintage = candidate.vintage {
                            Text("Vintage: \(vintage)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()

                    // Stats
                    HStack(spacing: 24) {
                        StatView(
                            icon: "star.fill",
                            value: String(format: "%.1f", candidate.avgRating),
                            label: "Avg Rating"
                        )

                        StatView(
                            icon: "bubble.left.and.bubble.right.fill",
                            value: "\(candidate.reviewCount)",
                            label: "Total Reviews"
                        )

                        StatView(
                            icon: "checkmark.circle.fill",
                            value: "\(Int(candidate.confidence * 100))%",
                            label: "Match"
                        )

                        // Personalized match score
                        if let matchScore = candidate.matchScore {
                            StatView(
                                icon: "heart.fill",
                                value: "\(matchScore)%",
                                label: "For You"
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Personalized match reasons
                    if let reasons = candidate.matchReasons, !reasons.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Why this matches your taste")
                                .font(.headline)
                                .padding(.horizontal)

                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(reasons, id: \.self) { reason in
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.body)
                                            .foregroundColor(.green)
                                        Text(reason)
                                            .font(.body)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                    }

                    // AI Summary ("What people say")
                    if let summary = summary, summary.status == "ready" {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What people say")
                                .font(.headline)
                                .padding(.horizontal)

                            if let summaryText = summary.summaryText {
                                Text(summaryText)
                                    .font(.body)
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                            }

                            // Descriptors
                            if !summary.descriptors.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(summary.descriptors, id: \.self) { descriptor in
                                            Text(descriptor)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.blue)
                                                .foregroundColor(.white)
                                                .cornerRadius(16)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }

                            // Pros & Cons
                            HStack(alignment: .top, spacing: 16) {
                                if !summary.pros.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Label("Pros", systemImage: "hand.thumbsup.fill")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.green)

                                        ForEach(summary.pros, id: \.self) { pro in
                                            HStack(alignment: .top, spacing: 4) {
                                                Text("•")
                                                Text(pro)
                                                    .font(.caption)
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                if !summary.cons.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Label("Cons", systemImage: "hand.thumbsdown.fill")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.orange)

                                        ForEach(summary.cons, id: \.self) { con in
                                            HStack(alignment: .top, spacing: 4) {
                                                Text("•")
                                                Text(con)
                                                    .font(.caption)
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding(.horizontal)
                        }
                    } else if isLoadingSummary {
                        VStack {
                            ProgressView()
                            Text("Loading insights...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else if summary?.status == "pending" {
                        VStack {
                            ProgressView()
                            Text("Generating AI summary...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else if summary?.status == "not_available" {
                        Text("AI insights not available yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }

                    // Similar Beverages
                    if let similar = similar, !similar.similar.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Similar Beverages")
                                .font(.headline)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(similar.similar) { item in
                                        SimilarBeverageCard(item: item)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    } else if isLoadingSimilar {
                        VStack {
                            ProgressView()
                            Text("Finding similar beverages...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }

                    // All reviews
                    if !candidate.topReviews.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Reviews")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(candidate.topReviews) { review in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(String(format: "%.1f", review.rating))
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue)
                                            .cornerRadius(6)

                                        Text(formatDate(review.createdAt))
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        Spacer()
                                    }

                                    if let note = review.note {
                                        Text(note)
                                            .font(.body)
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.05), radius: 2)
                            }
                            .padding(.horizontal)
                        }
                    }

                    Spacer(minLength: 20)

                    // Log this bottle button
                    Button(action: {
                        // TODO: Prefill AddRatingSheet with this beverage info
                        dismiss()
                        coordinator.shouldOpenAddRating = true
                    }) {
                        Text("Log This Bottle")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadSummary()
                loadSimilarBeverages()
            }
        }
    }

    private func loadSummary() {
        isLoadingSummary = true

        Task {
            do {
                let response = try await APIService.shared.getBeverageSummary(beverageId: candidate.beverageId)

                await MainActor.run {
                    summary = response
                    isLoadingSummary = false

                    // Poll if pending
                    if response.status == "pending" && pollAttempts < maxPollAttempts {
                        pollAttempts += 1
                        Task {
                            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                            loadSummary()
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isLoadingSummary = false
                    summaryError = error.localizedDescription
                }
            }
        }
    }

    private func loadSimilarBeverages() {
        isLoadingSimilar = true

        Task {
            do {
                let response = try await APIService.shared.getSimilarBeverages(beverageId: candidate.beverageId)

                await MainActor.run {
                    similar = response
                    isLoadingSimilar = false
                }
            } catch {
                await MainActor.run {
                    isLoadingSimilar = false
                }
            }
        }
    }

    private func formatDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else {
            return isoString
        }

        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .abbreviated
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Similar Beverage Card

struct SimilarBeverageCard: View {
    let item: SimilarBeverageItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Name
            Text(item.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)

            // Brand
            if let brand = item.brand {
                Text(brand)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Stats
            HStack(spacing: 12) {
                Label(String(format: "%.1f", item.avgRating), systemImage: "star.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)

                Label("\(item.reviewCount)", systemImage: "bubble.left.fill")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            // Similarity
            HStack {
                Spacer()
                Text("\(Int(item.similarity * 100))% match")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .frame(width: 160)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ScanResultsView(response: ScanBottleResponse(
        query: ScanQuery(rawText: "Caymus Cabernet 2019", brand: "Caymus", name: "Cabernet Sauvignon", vintage: "2019"),
        candidates: [
            BeverageCandidate(
                beverageId: "1",
                displayName: "Caymus Cabernet Sauvignon",
                brand: "Caymus Vineyards",
                name: "Cabernet Sauvignon",
                vintage: "2019",
                imageUrl: nil,
                confidence: 0.92,
                avgRating: 8.5,
                reviewCount: 15,
                topReviews: [
                    ReviewItem(reviewId: "r1", rating: 9.0, note: "Rich and bold, perfect with steak", userId: "u1", createdAt: "2024-01-15T12:00:00Z"),
                    ReviewItem(reviewId: "r2", rating: 8.5, note: "Smooth tannins, great vintage", userId: "u2", createdAt: "2024-01-10T12:00:00Z")
                ],
                matchScore: 85,
                matchReasons: ["You rate bold red wines higher", "Matches your preference for Cabernet"]
            )
        ],
        noMatch: false
    ))
}
