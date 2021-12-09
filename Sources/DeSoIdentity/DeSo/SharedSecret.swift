//
//  File.swift
//
//
//  Created by Andy Boyd on 05/07/2021.
//
import Foundation

public struct SharedSecret: Codable {
    public let secret: String
    public let publicKey: String
    public let otherPublicKey: String
}
