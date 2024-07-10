//
//  ContentView.swift
//  InAppPurchaseManager
//
//  Created by 王楚江 on 2024/7/10.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var entitlement: EntitlementManager
    @State var showingSubscriptionView = false
    var body: some View {
        VStack {
            if entitlement.hasPro == false {
                Button("Subscription Purchase") {
                    showingSubscriptionView.toggle()
                }
            } else {
                Text("You have subscribed to purchase")
            }
        }
        .padding()
        .sheet(isPresented: $showingSubscriptionView) {
            SubscriptionView()
        }
    }
}
