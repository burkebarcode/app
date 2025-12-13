//
//  APIService.swift
//  barcode
//
//  Created by Burke Butler on 12/4/25.
//

import Foundation

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError
    case networkError(Error)

    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int64

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

struct CreateUserRequest: Codable {
    let email: String
    let handle: String
    let password: String
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct UserResponse: Codable {
    let id: String
    let email: String
    let handle: String
    let avatarUrl: String?
    let bio: String?

    enum CodingKeys: String, CodingKey {
        case id, email, handle, bio
        case avatarUrl = "avatar_url"
    }
}



class APIService {
    static let shared = APIService()

    //private let baseURL = "https://barcode-gateway.fly.dev"
    private let baseURL = "http://localhost:9000"
    private let tokenManager = TokenManager.shared
    private var refreshTask: Task<Void, Never>?

    private init() {}

    private func ensureValidToken() async throws {
        if tokenManager.shouldRefreshToken() {
            // If already refreshing, wait for that task
            if let existingTask = refreshTask {
                await existingTask.value
                return
            }

            // Start new refresh
            let task = Task {
                do {
                    _ = try await self.performTokenRefresh()
                } catch {
                    print("Token refresh failed: \(error)")
                }
            }
            refreshTask = task
            await task.value
            refreshTask = nil
        }
    }

    private func performTokenRefresh() async throws -> TokenResponse {
        guard let refreshToken = tokenManager.refreshToken else {
            throw APIError.invalidResponse
        }

        let url = URL(string: "\(baseURL)/v1/auth/refresh")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["refresh_token": refreshToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            // Token refresh failed - clear tokens
            tokenManager.clearTokens()
            throw APIError.httpError(httpResponse.statusCode)
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        // Update stored tokens
        if let userId = tokenManager.userId {
            tokenManager.saveTokens(
                accessToken: tokenResponse.accessToken,
                refreshToken: tokenResponse.refreshToken,
                expiresIn: tokenResponse.expiresIn,
                userId: userId
            )
        }

        return tokenResponse
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // If 401 and we have a refresh token, try refreshing
        if httpResponse.statusCode == 401 && tokenManager.refreshToken != nil {
            try await ensureValidToken()
            // Retry the request with new token
            var retryRequest = request
            if let token = tokenManager.accessToken {
                retryRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            return try await performRequest(retryRequest)
        }

        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Auth Endpoints

    func signUp(email: String, handle: String, password: String) async throws -> UserResponse {
        let url = URL(string: "\(baseURL)/v1/users")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = CreateUserRequest(email: email, handle: handle, password: password)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 201 else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(UserResponse.self, from: data)
    }

    func login(email: String, password: String) async throws -> (TokenResponse, String) {
        let url = URL(string: "\(baseURL)/v1/auth/login")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = LoginRequest(email: email, password: password)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        // Decode JWT to get user ID
        let userId = try extractUserIdFromToken(tokenResponse.accessToken)

        // Store tokens with user ID
        tokenManager.saveTokens(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            expiresIn: tokenResponse.expiresIn,
            userId: userId
        )

        return (tokenResponse, userId)
    }

    private func extractUserIdFromToken(_ token: String) throws -> String {
        let segments = token.components(separatedBy: ".")
        guard segments.count > 1 else {
            throw APIError.decodingError
        }

        let payloadSegment = segments[1]
        var base64 = payloadSegment
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Add padding if needed
        while base64.count % 4 != 0 {
            base64.append("=")
        }

        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sub = json["sub"] as? String else {
            throw APIError.decodingError
        }

        return sub
    }

    func logout() async throws {
        guard let refreshToken = tokenManager.refreshToken else {
            return
        }

        let url = URL(string: "\(baseURL)/v1/auth/logout")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["refresh_token": refreshToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        // Clear stored tokens
        tokenManager.clearTokens()
    }

    // MARK: - User Endpoints

    func getUser(by id: String) async throws -> UserResponse {
        // Ensure token is valid before making request
        try await ensureValidToken()

        let url = URL(string: "\(baseURL)/v1/users/\(id)")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = tokenManager.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return try await performRequest(request)
    }

    func clearTokens() {
        tokenManager.clearTokens()
    }

    // MARK: - Post Endpoints

    func createPost(
        venueId: String? = nil,
        drinkName: String,
        drinkCategory: String,
        stars: Int? = nil,
        notes: String? = nil,
        beerDetails: BeerDetailsRequest? = nil,
        wineDetails: WineDetailsRequest? = nil,
        cocktailDetails: CocktailDetailsRequest? = nil,
        venueDetails: VenueDetailsRequest? = nil
    ) async throws -> PostResponse {
        try await ensureValidToken()

        let url = URL(string: "\(baseURL)/v1/feed")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = tokenManager.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body = CreatePostRequest(
            venueId: venueId,
            drinkName: drinkName,
            drinkCategory: drinkCategory,
            stars: stars,
            notes: notes,
            beerDetails: beerDetails,
            wineDetails: wineDetails,
            cocktailDetails: cocktailDetails,
            venueDetails: venueDetails
        )
        request.httpBody = try JSONEncoder().encode(body)

        return try await performRequest(request)
    }

    func getPosts(externalPlaceId: String? = nil) async throws -> [PostResponse] {
        try await ensureValidToken()

        var urlString = "\(baseURL)/v1/feed"
        if let externalPlaceId = externalPlaceId {
            urlString += "?external_place_id=\(externalPlaceId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }

        let url = URL(string: urlString)!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = tokenManager.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return try await performRequest(request)
    }

    func updatePost(
        postId: String,
        drinkName: String,
        stars: Int? = nil,
        notes: String? = nil,
        beerDetails: BeerDetailsRequest? = nil,
        wineDetails: WineDetailsRequest? = nil,
        cocktailDetails: CocktailDetailsRequest? = nil
    ) async throws -> PostResponse {
        try await ensureValidToken()

        let url = URL(string: "\(baseURL)/v1/feed/\(postId)")!

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = tokenManager.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body = UpdatePostRequest(
            drinkName: drinkName,
            stars: stars,
            notes: notes,
            beerDetails: beerDetails,
            wineDetails: wineDetails,
            cocktailDetails: cocktailDetails
        )
        request.httpBody = try JSONEncoder().encode(body)

        return try await performRequest(request)
    }

    func deletePost(postId: String) async throws {
        try await ensureValidToken()

        let url = URL(string: "\(baseURL)/v1/feed/\(postId)")!

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        if let token = tokenManager.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
    }

    // MARK: - Venue Endpoints

    func searchVenues(query: String) async throws -> [VenueResponse] {
        let url = URL(string: "\(baseURL)/v1/venues/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        return try await performRequest(request)
    }

    func getVenues(limit: Int = 50) async throws -> [VenueResponse] {
        let url = URL(string: "\(baseURL)/v1/venues?limit=\(limit)")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        return try await performRequest(request)
    }

    func createVenue(
        name: String,
        description: String,
        venueType: String,
        address: String?,
        city: String?,
        state: String?,
        country: String?,
        lat: Double?,
        lng: Double?,
        hasBeer: Bool,
        hasWine: Bool,
        hasCocktails: Bool
    ) async throws -> VenueResponse {
        try await ensureValidToken()

        let url = URL(string: "\(baseURL)/v1/venues")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = tokenManager.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body = CreateVenueRequest(
            name: name,
            description: description,
            venueType: venueType,
            address: address,
            city: city,
            state: state,
            country: country,
            lat: lat,
            lng: lng,
            hasBeer: hasBeer,
            hasWine: hasWine,
            hasCocktails: hasCocktails
        )
        request.httpBody = try JSONEncoder().encode(body)

        return try await performRequest(request)
    }
}

// MARK: - Post Models

struct CreatePostRequest: Codable {
    let venueId: String?
    let drinkName: String
    let drinkCategory: String
    let stars: Int?
    let notes: String?
    let beerDetails: BeerDetailsRequest?
    let wineDetails: WineDetailsRequest?
    let cocktailDetails: CocktailDetailsRequest?
    let venueDetails: VenueDetailsRequest?

    enum CodingKeys: String, CodingKey {
        case venueId = "venue_id"
        case drinkName = "drink_name"
        case drinkCategory = "drink_category"
        case stars, notes
        case beerDetails
        case wineDetails
        case cocktailDetails
        case venueDetails
    }
}

struct VenueDetailsRequest: Codable {
    let name: String
    let address: String?
    let city: String?
    let state: String?
    let country: String?
    let lat: Double?
    let lng: Double?
    let externalPlaceId: String?
    let mapProvider: String?

    enum CodingKeys: String, CodingKey {
        case name, address, city, state, country, lat, lng
        case externalPlaceId = "externalPlaceId"
        case mapProvider = "mapProvider"
    }
}

struct UpdatePostRequest: Codable {
    let drinkName: String
    let stars: Int?
    let notes: String?
    let beerDetails: BeerDetailsRequest?
    let wineDetails: WineDetailsRequest?
    let cocktailDetails: CocktailDetailsRequest?

    enum CodingKeys: String, CodingKey {
        case drinkName = "drink_name"
        case stars, notes
        case beerDetails
        case wineDetails
        case cocktailDetails
    }
}

struct BeerDetailsRequest: Codable {
    let brewery: String
    let abv: Double
    let ibu: Int32
    let acidity: String
    let beerStyle: String
    let serving: String

    enum CodingKeys: String, CodingKey {
        case brewery, abv, ibu, acidity
        case beerStyle = "beer_style"
        case serving
    }
}

struct WineDetailsRequest: Codable {
    let sweetness: String
    let body: String
    let tannin: String
    let acidity: String
    let wineStyle: String
    let varietal: String
    let region: String
    let vintage: String
    let winery: String

    enum CodingKeys: String, CodingKey {
        case sweetness, body, tannin, acidity, varietal, region, vintage, winery
        case wineStyle = "wineStyle"
    }
}

struct CocktailDetailsRequest: Codable {
    let baseSpirit: String
    let cocktailFamily: String
    let preparation: String
    let presentation: String
    let garnish: String
    let sweetness: String
    let booziness: String
    let balance: String

    enum CodingKeys: String, CodingKey {
        case baseSpirit = "base_spirit"
        case cocktailFamily = "cocktail_family"
        case preparation, presentation, garnish
        case sweetness, booziness, balance
    }
}

struct PostResponse: Codable, Identifiable {
    let id: String
    let userId: String
    let venueId: String?
    let drinkName: String
    let drinkCategory: String
    let stars: Int?
    let notes: String?
    let wineDetails: WineDetailsResponse?
    let beerDetails: BeerDetailsResponse?
    let cocktailDetails: CocktailDetailsResponse?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case venueId = "venue_id"
        case drinkName = "drink_name"
        case drinkCategory = "drink_category"
        case stars, notes
        case wineDetails, beerDetails, cocktailDetails
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct WineDetailsResponse: Codable {
    let sweetness: String?
    let body: String?
    let tannin: String?
    let acidity: String?
    let wineStyle: String?
    let varietal: String?
    let region: String?
    let vintage: String?
    let winery: String?
}

struct BeerDetailsResponse: Codable {
    let brewery: String?
    let abv: Double?
    let ibu: Int32?
    let acidity: String?
    let beerStyle: String?
    let serving: String?
}

struct CocktailDetailsResponse: Codable {
    let baseSpirit: String?
    let cocktailFamily: String?
    let preparation: String?
    let presentation: String?
    let garnish: String?
    let sweetness: String?
    let booziness: String?
    let balance: String?
}

// MARK: - Venue Models

struct CreateVenueRequest: Codable {
    let name: String
    let description: String
    let venueType: String
    let address: String?
    let city: String?
    let state: String?
    let country: String?
    let lat: Double?
    let lng: Double?
    let hasBeer: Bool
    let hasWine: Bool
    let hasCocktails: Bool

    enum CodingKeys: String, CodingKey {
        case name, description, address, city, state, country, lat, lng
        case venueType = "venue_type"
        case hasBeer = "has_beer"
        case hasWine = "has_wine"
        case hasCocktails = "has_cocktails"
    }
}

struct VenueResponse: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let venueType: String
    let address: String?
    let city: String?
    let state: String?
    let country: String?
    let lat: Double?
    let lng: Double?
    let hasBeer: Int
    let hasWine: Int
    let hasCocktails: Int
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, description, address, city, state, country, lat, lng
        case venueType = "venue_type"
        case hasBeer = "has_beer"
        case hasWine = "has_wine"
        case hasCocktails = "has_cocktails"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
