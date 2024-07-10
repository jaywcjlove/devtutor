//
//  store.swift
//  InAppPurchaseManager
//
//  Created by 王楚江 on 2024/7/10.
//

import SwiftUI
import StoreKit

/// 管理用户的权限状态
class EntitlementManager: ObservableObject {
    /// UserDefaults 实例，用于存储权限状态
    static let userDefaults = UserDefaults(suiteName: "com.wangchujiang.InAppPurchaseManager.vip")!
    /// 使用 @AppStorage 将 hasPro 属性保存到 UserDefaults 中
    @AppStorage("hasPro", store: userDefaults) var hasPro: Bool = false
}

/// 管理订阅产品和购买记录
@MainActor class SubscriptionsManager: NSObject, ObservableObject {
    /// 订阅产品的标识符数组
    let productIDs: [String] = [
        "com.wangchujiang.InAppPurchaseManager.monthly",
        "com.wangchujiang.InAppPurchaseManager.yearly",
        "com.wangchujiang.InAppPurchaseManager.lifetime"
    ]
    /// 记录已购买的产品标识符集合
    var purchasedProductIDs: Set<String> = []
    /// 发布订阅产品信息
    @Published var products: [Product] = []
    /// 授权管理器
    private var entitlementManager: EntitlementManager? = nil
    /// 更新任务
    private var updates: Task<Void, Never>? = nil
    /// 初始化方法，接收 EntitlementManager 实例作为参数
    init(entitlementManager: EntitlementManager) {
        self.entitlementManager = entitlementManager
        super.init()
        // 监听交易更新
        self.updates = observeTransactionUpdates()
        Task {
            await self.loadProducts(action: { err, success in
                
            })
        }
        // 添加自身作为 SKPaymentTransactionObserver
        SKPaymentQueue.default().add(self)
    }
    // 析构方法，取消更新任务
    deinit {
        updates?.cancel()
    }
    // MARK: - 观察交易更新
    /// 异步观察交易更新
    func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [unowned self] in
            for await _ in Transaction.updates {
                await self.updatePurchasedProducts()
            }
        }
    }
}

// MARK: - StoreKit2 API 扩展
extension SubscriptionsManager {
    // MARK: - 加载产品列表
    /// 异步加载产品列表
    func loadProducts(action: ((_ err: String?, _ success: Bool) -> Void)?) async {
        do {
            // 使用 Product.products(for:) 加载产品信息，并按价格排序
            self.products = try await Product.products(for: productIDs).sorted(by: { $0.price > $1.price })
            print("self.product: \(self.products)")
            action?(nil, true)
        } catch {
            let errorString = String(localized: "Failed to get the product! Please check the network! \n\(error.localizedDescription)")
            action?(errorString, false)
        }
    }
    // MARK: - 购买产品
    /// 异步购买产品
    func buyProduct(_ product: Product) async {
        do {
            // 使用 product.purchase() 进行产品购买
            let result = try await product.purchase()
            switch result {
            case let .success(.verified(transaction)):
                print("Successful purhcase 成功购买")
                // 完成交易并更新已购买产品
                await transaction.finish()
                await self.updatePurchasedProducts()
            case let .success(.unverified(_, error)):
                // Successful purchase but transaction/receipt can't be verified
                // Could be a jailbroken phone
                // 购买成功，但交易/收据无法验证
                // 可能是越狱手机
                print("Unverified purchase. Might be jailbroken. Error: \(error)")
                break
            case .pending:
                // Transaction waiting on SCA (Strong Customer Authentication) or approval from Ask to Buy
                // 等待 SCA（Strong Customer Authentication）或“要求购买”批准的交易
                break
            case .userCancelled:
                print("User cancelled!")
                break
            @unknown default:
                print("Failed to purchase the product!")
                break
            }
        } catch {
            print("Failed to purchase the product!")
        }
    }
    // MARK: - 更新已购买的产品
    /// 异步更新已购买的产品
    func updatePurchasedProducts() async {
        /// 一系列最新交易，使用户有权进行应用内购买和订阅。
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            if transaction.revocationDate == nil {
                // 如果交易未被撤销，则将产品标识符添加到已购买集合中
                if !self.purchasedProductIDs.contains(transaction.productID) {
                    self.purchasedProductIDs.insert(transaction.productID)
                }
            } else {
                // 如果交易被撤销，则从已购买集合中移除产品标识符
                self.purchasedProductIDs.remove(transaction.productID)
            }
        }
        // 更新 EntitlementManager 的 hasPro 属性
        self.entitlementManager?.hasPro = !self.purchasedProductIDs.isEmpty
    }
    // MARK: - 恢复购买
    /// 异步恢复购买
    func restorePurchases() async {
        do {
            // 同步应用内购买信息
            try await AppStore.sync()
            // 更新已购买的产品
            await updatePurchasedProducts()
        } catch {
            print(error)
        }
    }
}

// MARK: - SKPaymentTransactionObserver 实现
extension SubscriptionsManager: SKPaymentTransactionObserver {
    // 支付队列更新交易
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print("Subscriptions Payment Queue! updated!")
    }
    // 应用内购买准备添加到支付队列
    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        print("Subscriptions Payment Queue! Should Add Store Payment!")
        return true
    }
}
