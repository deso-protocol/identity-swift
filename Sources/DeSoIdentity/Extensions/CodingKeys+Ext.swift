//
//  CodingKeys+Ext.swift
//  
//
//  Created by Jacob Davis on 12/7/21.
//

import Foundation

extension JSONDecoder.KeyDecodingStrategy {
    static var convertFromPascalCase: JSONDecoder.KeyDecodingStrategy {
        return .custom { keys -> CodingKey in
            guard let key = keys.last else {
                return AnyKey.empty
            }
            if key.intValue != nil {
                return key
            }
            let newKey = key.stringValue.prefix(1).lowercased() + key.stringValue.dropFirst()
            return AnyKey(string: newKey)
        }
    }
}

extension JSONEncoder.KeyEncodingStrategy {
    static var convertToPascalCase: JSONEncoder.KeyEncodingStrategy {
        return .custom { keys -> CodingKey in
            guard let key = keys.last else {
                return AnyKey.empty
            }
            if key.intValue != nil {
                return key
            }
            let newKey = key.stringValue.prefix(1).uppercased() + key.stringValue.dropFirst()
            return AnyKey(string: newKey)
        }
    }
}

struct AnyKey: CodingKey {
    
    static let empty = AnyKey(string: "")
    
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
    
    init(string: String) {
        self.stringValue = string
        self.intValue = nil
    }
}
