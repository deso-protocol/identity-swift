//
//  File.swift
//  
//
//  Created by Andy Boyd on 29/06/2021.
//

import Foundation

public struct JWTRequest {
    let accessLevel: AccessLevel
    let accessLevelHmac: String
    let encryptedSeedHex: String
}
