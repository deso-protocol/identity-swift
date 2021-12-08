//
//  URLSession+Ext.swift
//  
//
//  Created by Jacob Davis on 12/7/21.
//

import Foundation

extension URLSession {
    @available(macOS, deprecated: 12.0, message: "This extension is no longer necessary. Use API built into SDK")
    @available(iOS, deprecated: 15.0, message: "This extension is no longer necessary. Use API built into SDK")
    func data(with urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: urlRequest) { data, response, error in
                guard let data = data, let response = response else {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing: error)
                }
                
                continuation.resume(returning: (data, response))
            }
            task.resume()
        }
    }
}
