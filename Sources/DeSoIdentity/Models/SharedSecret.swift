//
//  File.swift
//  
//
//  Created by Andy Boyd on 05/07/2021.
//

import Foundation

struct SharedSecret: Codable {
    let secret: String
    let privateKey: String
    let publicKey: String
    let myTruePublicKey: String
}
