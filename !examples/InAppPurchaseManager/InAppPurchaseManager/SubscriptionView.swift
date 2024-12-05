//
//  SubscriptionView.swift
//  InAppPurchaseManager
//
//  Created by 王楚江 on 2024/7/10.
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var subscriptions: SubscriptionsManager
    @State private var message: String = ""
    let privacyPolicy = URL(string: "https://wangchujiang.com/copybook-generator/privacy-policy.html")!
    let termsOfService = URL(string: "https://wangchujiang.com/copybook-generator/terms-of-service.html")!
    var body: some View {
        NavigationStack {
            if !subscriptions.products.isEmpty {
                VStack {
                    SubscriptionStoreView(productIDs: subscriptions.productIDs)
                        .storeButton(.visible, for: .policies)
                        .subscriptionStorePolicyDestination(url: privacyPolicy, for: .privacyPolicy)
                        .subscriptionStorePolicyDestination(url: termsOfService, for: .termsOfService)
                        .onInAppPurchaseCompletion(perform: { product, result in
                            if case .success(.success(let transaction)) = result {
                                print("Purchased successfully: \(transaction.signedDate)")
                                await subscriptions.updatePurchasedProducts()
                                dismiss()
                            } else {
                                print("Something else happened")
                            }
                        })
                    Button(action: {
                        Task {
                            await subscriptions.restorePurchases()
                            dismiss()
                        }
                    }, label: {
                        Text("Restore Subscription")
                    })
                    #if os(macOS)
                    .buttonStyle(.link)
                    #endif
                    .offset(y: -22)
                }
                .background(.background)
                .frame(minWidth: 320, minHeight: 580)
                .frame(maxWidth: 450)
            } else {
                VStack {
                    if message.isEmpty {
                        ProgressView().progressViewStyle(.circular).scaleEffect(1).ignoresSafeArea(.all)
                    } else {
                        Text(message).foregroundStyle(.red)
                    }
                }
                .padding(.horizontal)
                .frame(minWidth: 230, minHeight: 120)
            }
        }
    }
}
