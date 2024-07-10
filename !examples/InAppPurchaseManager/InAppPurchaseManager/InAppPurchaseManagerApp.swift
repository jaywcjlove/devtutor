//
//  InAppPurchaseManagerApp.swift
//  InAppPurchaseManager
//
//  Created by 王楚江 on 2024/7/10.
//

import SwiftUI

@main
struct InAppPurchaseManagerApp: App {
    @StateObject private var entitlementManager: EntitlementManager
    @StateObject private var subscriptionsManager: SubscriptionsManager
    init() {
        let entitlement = EntitlementManager()
        let subscriptions = SubscriptionsManager(entitlementManager: entitlement)
        self._entitlementManager = StateObject(wrappedValue: entitlement)
        self._subscriptionsManager = StateObject(wrappedValue: subscriptions)
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(entitlementManager)
                .environmentObject(subscriptionsManager)
        }
    }
}
