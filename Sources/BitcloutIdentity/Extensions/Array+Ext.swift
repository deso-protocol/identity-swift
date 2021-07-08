//
//  File.swift
//  
//
//  Created by Andy Boyd on 08/07/2021.
//

import Foundation

extension Array {
    func slice(from start: Int, length: Int? = nil) -> Array<Element> {
        if let length = length {
            return Array(self[start..<length])
        } else {
            return Array(self.suffix(from: start))
        }
    }
}
