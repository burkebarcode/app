//
//  MediaUploadService.swift
//  barcode
//
//  Direct S3 upload using pre-signed URLs
//

import Foundation
import UIKit
import Combine

// MARK: - Request/Response Models

struct RequestUploadRequest: Codable {
    let post_id: String?
    let content_type: String
    let size_bytes: Int
    let width: Int?
    let height: Int?
    let is_thumb: Bool
}

struct RequestUploadResponse: Codable {
    let upload_url: String
    let object_key: String
    let media_id: String
    let expires_at: String
}

struct CompleteUploadRequest: Codable {
    let media_id: String
}

struct MediaURLResponse: Codable {
    let url: String
    let expires_at: String
}

// MARK: - Media Upload Service

@MainActor
class MediaUploadService: ObservableObject {
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published var errorMessage: String?

    private let apiService: APIService

    init(apiService: APIService = APIService.shared) {
        self.apiService = apiService
    }

    /// Upload an image for a post
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - postID: Optional post ID (can be nil for staging)
    /// - Returns: Media ID if successful
    func uploadImage(_ image: UIImage, postID: String? = nil) async -> String? {
        print("DEBUG MediaUpload: Starting upload for postID: \(postID ?? "nil")")
        isUploading = true
        uploadProgress = 0
        errorMessage = nil

        defer {
            isUploading = false
        }

        // Step 1: Compress image and create thumbnail
        guard let originalData = image.compressForUpload(),
              let thumbData = image.createThumbnail() else {
            errorMessage = "Failed to compress image"
            print("DEBUG MediaUpload: Failed to compress image")
            return nil
        }

        let dimensions = image.dimensions
        print("DEBUG MediaUpload: Compressed image - original: \(originalData.count) bytes, thumb: \(thumbData.count) bytes, dimensions: \(dimensions.width)x\(dimensions.height)")

        // Step 2: Upload original
        print("DEBUG MediaUpload: Starting original upload")
        guard let originalMediaID = await uploadImageData(
            originalData,
            postID: postID,
            width: dimensions.width,
            height: dimensions.height,
            isThumb: false
        ) else {
            print("DEBUG MediaUpload: Original upload failed, errorMessage: \(errorMessage ?? "none")")
            return nil
        }
        print("DEBUG MediaUpload: Original uploaded successfully, mediaID: \(originalMediaID)")

        // Step 3: Upload thumbnail
        print("DEBUG MediaUpload: Starting thumbnail upload")
        _ = await uploadImageData(
            thumbData,
            postID: postID,
            width: 320,
            height: Int(320.0 / (Double(dimensions.width) / Double(dimensions.height))),
            isThumb: true
        )

        uploadProgress = 1.0
        print("DEBUG MediaUpload: Upload complete")
        return originalMediaID
    }

    /// Upload multiple images for a post
    /// - Parameters:
    ///   - images: Array of UIImages to upload
    ///   - postID: Optional post ID
    /// - Returns: Array of media IDs
    func uploadImages(_ images: [UIImage], postID: String? = nil) async -> [String] {
        var mediaIDs: [String] = []

        for (index, image) in images.enumerated() {
            uploadProgress = Double(index) / Double(images.count)

            if let mediaID = await uploadImage(image, postID: postID) {
                mediaIDs.append(mediaID)
            }
        }

        uploadProgress = 1.0
        return mediaIDs
    }

    /// Attach media to a post
    /// - Parameters:
    ///   - mediaID: The media ID to attach
    ///   - postID: The post ID to attach to
    /// - Returns: Success boolean
    func attachMediaToPost(mediaID: String, postID: String) async -> Bool {
        guard let url = URL(string: "\(apiService.baseURL)/v1/posts/\(postID)/media/\(mediaID)") else {
            print("DEBUG MediaUpload: Failed to create URL for attach media")
            return false
        }

        print("DEBUG MediaUpload: Attaching media \(mediaID) to post \(postID)")
        print("DEBUG MediaUpload: Attach URL: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth header if available
        if let token = TokenManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("DEBUG MediaUpload: Attach response is not HTTPURLResponse")
                return false
            }

            print("DEBUG MediaUpload: Attach response status: \(httpResponse.statusCode)")

            if httpResponse.statusCode != 200 {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("DEBUG MediaUpload: Attach error response: \(responseString)")
                }
            }

            return httpResponse.statusCode == 200
        } catch {
            print("DEBUG MediaUpload: Error attaching media to post: \(error)")
            return false
        }
    }

    /// Get a view URL for media
    /// - Parameter mediaID: The media ID
    /// - Returns: Pre-signed URL for viewing
    func getMediaURL(mediaID: String) async -> String? {
        guard let url = URL(string: "\(apiService.baseURL)/v1/media/\(mediaID)/url") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            let mediaResponse = try JSONDecoder().decode(MediaURLResponse.self, from: data)
            return mediaResponse.url
        } catch {
            print("Error getting media URL: \(error)")
            return nil
        }
    }

    // MARK: - Private Helpers

    private func uploadImageData(
        _ imageData: Data,
        postID: String?,
        width: Int,
        height: Int,
        isThumb: Bool
    ) async -> String? {
        print("DEBUG MediaUpload: uploadImageData - size: \(imageData.count), isThumb: \(isThumb)")

        // Step 1: Request upload URL from API
        print("DEBUG MediaUpload: Requesting upload URL from API")
        guard let uploadInfo = await requestUploadURL(
            postID: postID,
            contentType: "image/jpeg",
            sizeBytes: imageData.count,
            width: width,
            height: height,
            isThumb: isThumb
        ) else {
            print("DEBUG MediaUpload: Failed to get upload URL")
            return nil
        }
        print("DEBUG MediaUpload: Got upload URL, mediaID: \(uploadInfo.media_id)")

        // Step 2: Upload directly to S3
        print("DEBUG MediaUpload: Uploading to S3")
        guard await uploadToS3(imageData, uploadURL: uploadInfo.upload_url, contentType: "image/jpeg") else {
            errorMessage = "Failed to upload to S3"
            print("DEBUG MediaUpload: S3 upload failed")
            return nil
        }
        print("DEBUG MediaUpload: S3 upload successful")

        // Step 3: Complete upload (verify)
        print("DEBUG MediaUpload: Completing upload (verify)")
        guard await completeUpload(mediaID: uploadInfo.media_id) else {
            errorMessage = "Failed to verify upload"
            print("DEBUG MediaUpload: Verification failed")
            return nil
        }
        print("DEBUG MediaUpload: Upload verified successfully")

        return uploadInfo.media_id
    }

    private func requestUploadURL(
        postID: String?,
        contentType: String,
        sizeBytes: Int,
        width: Int,
        height: Int,
        isThumb: Bool
    ) async -> RequestUploadResponse? {
        guard let url = URL(string: "\(apiService.baseURL)/v1/media/uploads") else {
            print("DEBUG MediaUpload: Failed to create URL for media uploads")
            return nil
        }

        print("DEBUG MediaUpload: Request URL: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth header if available
        if let token = TokenManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("DEBUG MediaUpload: Added auth token")
        } else {
            print("DEBUG MediaUpload: No auth token found")
        }

        let requestBody = RequestUploadRequest(
            post_id: postID,
            content_type: contentType,
            size_bytes: sizeBytes,
            width: width,
            height: height,
            is_thumb: isThumb
        )

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            print("DEBUG MediaUpload: Request body encoded")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("DEBUG MediaUpload: Response is not HTTPURLResponse")
                return nil
            }

            print("DEBUG MediaUpload: Request upload URL response status: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("DEBUG MediaUpload: Error response body: \(responseString)")
                }
                errorMessage = "Request upload URL failed with status \(httpResponse.statusCode)"
                return nil
            }

            let uploadResponse = try JSONDecoder().decode(RequestUploadResponse.self, from: data)
            print("DEBUG MediaUpload: Successfully decoded upload response")
            return uploadResponse
        } catch {
            print("DEBUG MediaUpload: Error requesting upload URL: \(error)")
            errorMessage = "Failed to request upload URL: \(error.localizedDescription)"
            return nil
        }
    }

    private func uploadToS3(_ data: Data, uploadURL: String, contentType: String) async -> Bool {
        guard let url = URL(string: uploadURL) else {
            print("DEBUG MediaUpload: Failed to create URL from upload URL string")
            return false
        }

        print("DEBUG MediaUpload: S3 upload URL: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        do {
            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("DEBUG MediaUpload: S3 response is not HTTPURLResponse")
                return false
            }

            print("DEBUG MediaUpload: S3 upload response status: \(httpResponse.statusCode)")

            return httpResponse.statusCode == 200
        } catch {
            print("DEBUG MediaUpload: Error uploading to S3: \(error)")
            return false
        }
    }

    private func completeUpload(mediaID: String) async -> Bool {
        guard let url = URL(string: "\(apiService.baseURL)/v1/media/uploads/complete") else {
            print("DEBUG MediaUpload: Failed to create URL for complete upload")
            return false
        }

        print("DEBUG MediaUpload: Complete upload URL: \(url.absoluteString), mediaID: \(mediaID)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth header if available
        if let token = TokenManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let requestBody = CompleteUploadRequest(media_id: mediaID)

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("DEBUG MediaUpload: Complete upload response is not HTTPURLResponse")
                return false
            }

            print("DEBUG MediaUpload: Complete upload response status: \(httpResponse.statusCode)")

            if httpResponse.statusCode != 200 {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("DEBUG MediaUpload: Complete upload error response: \(responseString)")
                }
            }

            return httpResponse.statusCode == 200
        } catch {
            print("DEBUG MediaUpload: Error completing upload: \(error)")
            return false
        }
    }
}
