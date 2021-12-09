//
//  EncryptedMessages.swift
//
//
//  Created by Andy Boyd on 29/06/2021.
//
import Foundation

public struct EncryptedMessagesThread: Codable {

    public struct EncryptedText: Codable {
        public let message: String
        public let v2: Bool
        public init(message: String, v2: Bool) {
            self.message = message
            self.v2 = v2
        }
    }
    
    public let publicKey: String
    public let otherPublicKey: String
    public let encryptedMessages: [EncryptedText]
    
    public init(publicKey: String, otherPublicKey: String, encryptedMessages: [EncryptedText]) {
        self.publicKey = publicKey
        self.otherPublicKey = otherPublicKey
        self.encryptedMessages = encryptedMessages
    }
}
