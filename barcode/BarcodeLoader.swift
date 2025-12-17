//
//  BarcodeLoader.swift
//  barcode
//
//  Created by Burke Butler on 12/17/25.
//

import SwiftUI

struct BarcodeLoader: View {
    private let heights: [CGFloat] = [60, 35, 60, 35, 60]
    private let widths:  [CGFloat] = [11, 9, 11, 9, 11]

    // Tuning knobs
    private let minScale: CGFloat = 0.30
    private let maxScale: CGFloat = 1.05
    private let duration: Double  = 0.42   // snappier
    private let stagger: Double   = 0.13   // more wave-like

    @State private var animate = false

    var body: some View {
        HStack(spacing: 9) {
            ForEach(0..<5, id: \.self) { i in
                let delay = Double(i) * stagger

                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black)
                    .frame(width: widths[i], height: heights[i])
                    // Primary wave: vertical pulse
                    .scaleEffect(x: animate ? 1.00 : 0.96,
                                 y: animate ? maxScale : minScale,
                                 anchor: .center)
                    // Modern feel: gentle opacity lift at peak
                    .opacity(animate ? 1.0 : 0.70)
                    // Optional: slight blur reduction at peak (very subtle “pop”)
                    .blur(radius: animate ? 0.0 : 0.15)
                    .animation(
                        .spring(response: duration, dampingFraction: 0.72, blendDuration: 0.0)
                            .repeatForever(autoreverses: true)
                            .delay(delay),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
        .accessibilityLabel("Loading")
    }
}
