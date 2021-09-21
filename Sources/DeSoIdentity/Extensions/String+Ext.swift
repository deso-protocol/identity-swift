//
//  File.swift
//  
//
//  Created by Andy Boyd on 08/07/2021.
//

import Foundation

extension String {
    var uInt8Array: [UInt8] {
        return self.data(using: .utf8)?.bytes ?? []
    }
}
