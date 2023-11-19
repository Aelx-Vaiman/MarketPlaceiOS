//
//  ItemModel.swift
//  ItemsClient
//
//  Created by Alex Vaiman on 18/11/2023.
//

import Foundation
struct ListItem: Identifiable, Codable {
    var date = AddsApi.sharedInstance.serverDateDateFormatter().string(from: Date())
    var id = UUID()
    var title: String
    var description: String
    var location: String
    // so we can filter adds by city
    var city = ""
    var phoneNumber = ""
    var userName = ""
    var userId = "" // email
}
