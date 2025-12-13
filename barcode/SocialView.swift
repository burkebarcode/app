//
//  SocialView.swift
//  barcode
//
//  Created by Burke Butler on 11/18/25.
//

import SwiftUI

struct SocialView: View {
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(dataStore.feedPosts) { post in
                    if let user = dataStore.getUser(for: post.userId) {
                        let venue = post.venueId.flatMap { dataStore.getVenue(for: $0) }
                        SocialFeedCard(post: post, user: user, venue: venue)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }
}


#Preview {
    SocialView()
        .environmentObject(DataStore())
}
