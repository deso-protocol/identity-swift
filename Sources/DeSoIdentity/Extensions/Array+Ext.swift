//
//  File.swift
//  
//
//  Created by Andy Boyd on 08/07/2021.
//

import Foundation

extension Array {
    func slice(from start: Int, to end: Int? = nil) -> Array<Element> {
        if let end = end {
            return Array(self[start..<end])
        } else {
            return Array(self.suffix(from: start))
        }
    }
}

extension Array where Element == UInt8 {
    var stringValue: String? {
        let string = String(bytes: self, encoding: .utf8)
        return string
    }
}
