//
//  FilterChip.swift
//  barcode
//
//  Created by Burke Butler on 11/18/25.
//

import SwiftUI

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                Text(title)
                    .font(.system(size: 15, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.primary : Color(.systemGray5))
            )
            .foregroundStyle(isSelected ? Color(.systemBackground) : Color.primary)
        }
    }
}
