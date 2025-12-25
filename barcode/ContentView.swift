//
//  ContentView.swift
//  barcode
//
//  Created by Burke Butler on 11/18/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var dataStore = DataStore()
    @StateObject private var postsManager = PostsManager()
    @StateObject private var coordinator = AppCoordinator()

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            ExploreView()
                .tabItem {
                    Label("Explore", systemImage: "map.fill")
                }
                .tag(0)

            //SocialView()
            //    .tabItem {
             //       Label("Social", systemImage: "person.2.fill")
              //  }
              //  .tag(1)

            MyLogView()
                .tabItem {
                    Label("My Log", systemImage: "book.fill")
                }
                .tag(1)

            ScanBottleView()
                .tabItem {
                    Label("Scan", systemImage: "camera.fill")
                }
                .tag(2)

            ForYouView()
                .tabItem {
                    Label("For You", systemImage: "star.fill")
                }
                .tag(3)

            //SettingsView()
            //    .tabItem {
            //        Label("Settings", systemImage: "gearshape.fill")
            //    }
            //    .tag(4)
        }
        .environmentObject(dataStore)
        .environmentObject(postsManager)
        .environmentObject(coordinator)
    }
}

#Preview {
    ContentView()
}
