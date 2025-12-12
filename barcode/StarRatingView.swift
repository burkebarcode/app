//
//  StarRatingView.swift
//  barcode
//
//  Created by Burke Butler on 11/18/25.
//

import SwiftUI

struct StarRatingView: View {
    let rating: Int
    let maxRating: Int = 5
    let size: CGFloat
    let interactive: Bool
    let onRatingChanged: ((Int) -> Void)?

    init(rating: Int, size: CGFloat = 16, interactive: Bool = false, onRatingChanged: ((Int) -> Void)? = nil) {
        self.rating = rating
        self.size = size
        self.interactive = interactive
        self.onRatingChanged = onRatingChanged
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .foregroundStyle(index <= rating ? .yellow : .gray.opacity(0.3))
                    .font(.system(size: size))
                    .onTapGesture {
                        if interactive {
                            onRatingChanged?(index)
                        }
                    }
            }
        }
    }
}
