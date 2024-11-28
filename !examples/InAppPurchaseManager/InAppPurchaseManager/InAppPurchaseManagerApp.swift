//
//  InAppPurchaseManagerApp.swift
//  InAppPurchaseManager
//
//  Created by 王楚江 on 2024/7/10.
//

import SwiftUI

@main
struct InAppPurchaseManagerApp: App {
    @StateObject private var subscriptionsManager: SubscriptionsManager = SubscriptionsManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(subscriptionsManager)
        }
    }
}
