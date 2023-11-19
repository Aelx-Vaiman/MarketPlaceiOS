import Foundation

enum AddsApiError: Error {
    case invalidURL
    case decodingError
    case encodingError
    case serverError(code: Int, description: String)
}


class AddsApi {

    static let sharedInstance = AddsApi()
    private init() {}
    
    class var baseUrl: String {
        return "http://localhost:3000/api" // Replace with your actual API base URL
    }
    
    func parseServerError(data: Data?, statusCode: Int) -> AddsApiError {
        // Handle the error case
        if let data = data, let errorDescription = String(data: data, encoding: .utf8) {
            // Pass the server error code and description to the completion handler
            return AddsApiError.serverError(code: statusCode, description: errorDescription)
        } else {
            // If decoding fails or there's no data, provide a generic error
            return AddsApiError.serverError(code: statusCode, description: "unknown error")
        }
    }
    
    func fetchAllItems(completion: @escaping ([ListItem]?, Error?) -> Void) {
        guard let url = URL(string: "\(AddsApi.baseUrl)/items") else {
            completion([], AddsApiError.invalidURL)
            return
        }
        
        URLSession.shared.dataTask(with: url) {[weak self] data, response, error in
            guard let self = self, let data = data, error == nil, let httpResponse = response as? HTTPURLResponse else {
                completion([], error)
                return
            }
            
            if httpResponse.statusCode > 299 {
                completion(nil, self.parseServerError(data: data, statusCode: httpResponse.statusCode))
                return
            }
            
            do {
                let items = try JSONDecoder().decode([ListItem].self, from: data)
                completion(items, nil)
            } catch {
                print("Error decoding response: \(error)")
                completion([], AddsApiError.decodingError)
            }
        }.resume()
    }
    
    func removeItem(id: UUID, completion: @escaping (Error?) -> Void) {
        guard let url = URL(string: "\(AddsApi.baseUrl)/items/remove/\(id)") else {
            completion(AddsApiError.invalidURL)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            
            guard let self = self, error == nil, let httpResponse = response as? HTTPURLResponse else {
                completion(error)
                return
            }
            
            
            if (200..<300 ~= httpResponse.statusCode) {
                // Success
                completion(nil)
            } else {
                // Handle the error case
                completion(self.parseServerError(data: data, statusCode: httpResponse.statusCode))
            }
        }.resume()
    }
    
    func updateItem(id: UUID, updatedItem: ListItem, completion: @escaping (Error?) -> Void) {
        guard let url = URL(string: "\(AddsApi.baseUrl)/items/update/\(id)") else {
            completion(AddsApiError.invalidURL)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        do {
            let jsonData = try JSONEncoder().encode(updatedItem)
            request.httpBody = jsonData
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        } catch {
            print("Error encoding request body: \(error)")
            completion(AddsApiError.encodingError)
            return
        }
        
        URLSession.shared.dataTask(with: request) {[weak self] data, response, error in
            guard let self = self, error == nil, let httpResponse = response as? HTTPURLResponse else {
                completion(error)
                return
            }
            
            if (200..<300 ~= httpResponse.statusCode) {
                // Success
                completion(nil)
            } else {
                // Handle the error case
                completion(self.parseServerError(data: data, statusCode: httpResponse.statusCode))
            }
        }.resume()
    }
    
    func addItem(item: ListItem, completion: @escaping (AddsApiError?) -> Void) {
 
        let url = URL(string: "\(AddsApi.baseUrl)/items")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        do {
            let jsonData = try JSONEncoder().encode(item)
            request.httpBody = jsonData
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        } catch {
            print("Error encoding request body: \(error)")
            completion(AddsApiError.encodingError)
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, let httpResponse = response as? HTTPURLResponse else {
                completion(AddsApiError.decodingError)
                return
            }
            
            if (200..<300 ~= httpResponse.statusCode) {
                // Success
                completion(nil)
            } else {
                // Handle the error case
                completion(self.parseServerError(data: data, statusCode: httpResponse.statusCode))
            }
        }.resume()
    }
    
    func serverDateDateFormatter() -> ISO8601DateFormatter {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return dateFormatter
    }
      
}
