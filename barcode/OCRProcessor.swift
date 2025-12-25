//
//  OCRProcessor.swift
//  barcode
//
//  Created by Claude Code on 12/24/25.
//

import Combine
import Foundation
import UIKit
import Vision

class OCRProcessor: ObservableObject {
    @Published var detectedText: String = ""
    @Published var recognizedLines: [String] = []

    private var lastProcessTime: Date?
    private let throttleInterval: TimeInterval = 0.5 // Process OCR every 500ms

    struct ParsedBottleInfo {
        var rawText: String
        var tokens: [String]
        var brandGuess: String?
        var nameGuess: String?
        var vintageGuess: String?
    }

    func processFrame(_ pixelBuffer: CVPixelBuffer, completion: @escaping (ParsedBottleInfo?) -> Void) {
        // Throttle OCR processing
        let now = Date()
        if let lastTime = lastProcessTime, now.timeIntervalSince(lastTime) < throttleInterval {
            return
        }
        lastProcessTime = now

        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }

            if let error = error {
                print("OCR Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }

            guard !recognizedStrings.isEmpty else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            let rawText = recognizedStrings.joined(separator: " ")

            DispatchQueue.main.async {
                self.recognizedLines = recognizedStrings
                self.detectedText = rawText

                // Parse the OCR text
                let parsed = self.parseBottleInfo(from: recognizedStrings, rawText: rawText)
                completion(parsed)
            }
        }

        // Configure request for high accuracy
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform OCR: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }

    private func parseBottleInfo(from lines: [String], rawText: String) -> ParsedBottleInfo {
        // Extract tokens
        let tokens = extractTokens(from: rawText)

        // Detect vintage (4-digit year)
        let vintage = extractVintage(from: rawText)

        // Simple heuristics for brand and name
        // Typically:
        // - First line or prominent text = brand/producer
        // - Second line = product name
        // - Look for capitalized words, longer strings

        var brandGuess: String?
        var nameGuess: String?

        let filteredLines = lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.count >= 3 && !isCommonWord(trimmed)
        }

        if filteredLines.count > 0 {
            // First meaningful line as brand
            brandGuess = filteredLines[0]
        }

        if filteredLines.count > 1 {
            // Second line as name
            nameGuess = filteredLines[1]
        } else if tokens.count > 0 {
            // Fallback: longest token as name
            nameGuess = tokens.max(by: { $0.count < $1.count })
        }

        return ParsedBottleInfo(
            rawText: rawText,
            tokens: tokens,
            brandGuess: brandGuess,
            nameGuess: nameGuess,
            vintageGuess: vintage
        )
    }

    private func extractTokens(from text: String) -> [String] {
        // Normalize and tokenize
        let normalized = normalizeText(text)

        // Split by whitespace and filter
        let tokens = normalized.split(separator: " ").map { String($0) }
            .filter { token in
                token.count >= 2 && !isCommonWord(token)
            }

        return Array(tokens.prefix(10)) // Limit to 10 tokens
    }

    private func extractVintage(from text: String) -> String? {
        // Look for 4-digit year between 1900 and current year + 1
        let currentYear = Calendar.current.component(.year, from: Date())
        let yearRegex = try? NSRegularExpression(pattern: "\\b(19|20)\\d{2}\\b", options: [])

        guard let regex = yearRegex else { return nil }

        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

        for match in matches {
            let yearString = nsString.substring(with: match.range)
            if let year = Int(yearString), year >= 1900 && year <= currentYear + 1 {
                return yearString
            }
        }

        return nil
    }

    private func normalizeText(_ text: String) -> String {
        // Lowercase
        var normalized = text.lowercased()

        // Remove punctuation except spaces
        let allowedCharacters = CharacterSet.alphanumerics.union(.whitespaces)
        normalized = String(normalized.unicodeScalars.filter { allowedCharacters.contains($0) })

        // Collapse whitespace
        normalized = normalized.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isCommonWord(_ word: String) -> Bool {
        let commonWords = Set([
            "wine", "beer", "bottle", "ml", "oz", "vol", "alc", "alcohol",
            "red", "white", "reserve", "vintage", "estate", "winery", "brewery",
            "the", "and", "or", "of", "a", "an", "by", "from", "with"
        ])

        return commonWords.contains(word.lowercased())
    }
}
