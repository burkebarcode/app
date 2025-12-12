//
//  SettingsView.swift
//  barcode
//
//  Created by Burke Butler on 11/18/25.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Spacer()

                Image(systemName: "gearshape.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)

                Text("Settings")
                    .font(.system(size: 24, weight: .bold))

                Text("Account settings and preferences")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Text("Coming soon")
                    .font(.system(size: 14))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 8)

                Spacer()
            }
            .navigationTitle("Settings")
#if os(iOS)
            .navigationBarTitleDisplayMode(.large)
#endif
        }
    }
}
