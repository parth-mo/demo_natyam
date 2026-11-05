//
//  CartModel.swift
//  AppStructure
//
//  Created by iOS SDP Mac04 on 03/11/26.
//

import Foundation

struct Item: Identifiable, Equatable {
    let id: UUID
    var name: String
    var quantity: Int

    init(id: UUID = UUID(), name: String, quantity: Int) {
        self.id = id
        self.name = name
        self.quantity = quantity
    }
}

@Observable
final class CartModel {
    var items: [Item] = []
    var statusMessage: String = "App Launched"
    var isPaymentActive: Bool = false
    var lastPhase: String = "None"
    
    func refreshCart() {
        lastPhase = "Active"
        statusMessage = "🔄 Cart refreshed"
        items = [
            Item(name: "iPhone", quantity: 2),
            Item(name: "MacBook", quantity: 1),
            Item(name: "iPad", quantity: 3)
        ]
    }
    
    func pausePayment() {
        lastPhase = "Inactive"
        isPaymentActive = false
        statusMessage = "⏸️ Payment paused"
    }
    
    func saveCart() {
        lastPhase = "Background"
        statusMessage = "Cart Saved"
    }
    
    func startPayment() {
        isPaymentActive = true
        statusMessage = "Payment started"
    }
}



