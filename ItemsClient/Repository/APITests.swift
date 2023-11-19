//
//  APITests.swift
//  ItemsClient
//
//  Created by Alex Vaiman on 18/11/2023.
//

import Foundation

// Test adding an item

extension AddsApi {
    func testAddItem(completion: @escaping (AddsApiError?) -> Void) {
        let mockItem = ListItem(id: UUID(), title: "Mock Title", description: "Mock Description", location: "Mock Location", phoneNumber: "Mock Phone", userId: "Mock User ID")
        
        addItem(item: mockItem) { error in
            if let error = error {
                print("Error adding item: \(error)")
                completion(error)
            } else {
                print("Item added successfully")
                completion(nil)
            }
        }
    }
    
    // Test for duplicate uuids
    func testAddItemDuplicateUUID(completion: @escaping (AddsApiError?) -> Void) {
        let id = UUID()
        let mockItem = ListItem(id: id, title: "Mock Title", description: "Mock Description", location: "Mock Location", phoneNumber: "Mock Phone", userId: "Mock User ID")
        
        addItem(item: mockItem) { [weak self] error in
            if let error = error {
                print("Error adding item: \(error)")
                completion(error)
            } else {
                self?.addItem(item: mockItem) { error in
                    if let addsApiError = error {
                        // Unwrapped the optional AddsApiError
                        if case let AddsApiError.serverError(code, _) = addsApiError, code == 406 {
                            // The error is a server error with code 406
                            print("Test passed!: \(addsApiError)")
                            completion(addsApiError)
                        } else {
                            // The error is not a server error with code 406
                            print("Test failed! item with double uuid created!")
                            completion(error)
                        }
                    } else {
                        // Handle the case where error is not AddsApiError
                        print("Error is not AddsApiError")
                        completion(error)
                    }
                }
            }
        }
    }
    
    // Test for updating an item
    func testUpdateItem(completion: @escaping (Error?) -> Void) {
        // Create a new item
        let id = UUID()
        let initialTitle = "Initial Title"
        let updatedTitle = "Updated Title"
        
        let mockItem = ListItem(id: id, title: initialTitle, description: "Mock Description", location: "Mock Location", phoneNumber: "Mock Phone", userId: "Mock User ID")
        
        // Add the initial item
        addItem(item: mockItem) { [weak self] error in
            guard let self = self, error == nil else {
                completion(error)
                return
            }
            
            // Update the item with a new title
            let updatedItem = ListItem(id: id, title: updatedTitle, description: "Updated Description", location: "Updated Location", phoneNumber: "Updated Phone", userId: "Updated User ID")
            self.updateItem(id: id, updatedItem: updatedItem) { updateError in
                guard updateError == nil else {
                    completion(updateError)
                    return
                }
                
                // Fetch all items and check if the item was updated
                self.fetchAllItems { items, fetchError in
                    guard let fetchedItems = items, fetchError == nil else {
                        completion(fetchError)
                        return
                    }
                    
                    let updatedItem = fetchedItems.first(where: { $0.id == id })
                    
                    if let updatedItem = updatedItem, updatedItem.title == updatedTitle {
                        // The item was successfully updated
                        print("Item updated successfully: \(updatedItem)")
                        completion(nil)
                    } else {
                        // The item was not updated successfully
                        completion(NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Item not updated successfully"]))
                    }
                }
            }
        }
    }
    
    func testDeleteItem(completion: @escaping (Error?) -> Void) {
        // Create a new item
        let id = UUID()
        
        let mockItem = ListItem(id: id, title:  "Test Title", description: "Mock Description", location: "Mock Location", phoneNumber: "Mock Phone", userId: "Mock User ID")
        
        // Add the item
        addItem(item: mockItem) { [weak self] error in
            guard let self = self, error == nil else {
                completion(error)
                return
            }
            
            // Delete the item
            self.removeItem(id: id) { deleteError in
                guard deleteError == nil else {
                    completion(deleteError)
                    return
                }
                
                // Fetch all items and check if the item was deleted
                self.fetchAllItems { items, fetchError in
                    guard let fetchedItems = items, fetchError == nil else {
                        completion(fetchError)
                        return
                    }
                    
                    let deletedItem = fetchedItems.first(where: { $0.id == id })
                    
                    if deletedItem == nil {
                        // The item was successfully deleted
                        print("Item deleted successfully")
                        completion(nil)
                    } else {
                        // The item was not deleted successfully
                        completion(NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Item not deleted successfully"]))
                    }
                }
            }
        }
    }
}
