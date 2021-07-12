//
//  MessageDecryptionWorker.swift
//  
//
//  Created by Andy Boyd on 29/06/2021.
//

import Foundation

protocol MessageDecryptable {
    func decryptThreads(_ encryptedMessageThreads: [EncryptedMessagesThread], for publicKey: String, errorOnFailure: Bool) throws -> [String: [String]]
    func decryptThread(_ thread: EncryptedMessagesThread, for publicKey: String, errorOnFailure: Bool) throws -> [String]
}

class MessageDecryptionWorker: MessageDecryptable {
    
    private let keyStore: KeyInfoStorable
    
    init(keyStore: KeyInfoStorable = KeyInfoStorageWorker()) {
        self.keyStore = keyStore
    }
    
    func decryptThreads(_ encryptedMessageThreads: [EncryptedMessagesThread], for publicKey: String, errorOnFailure: Bool) throws -> [String: [String]] {
        return try encryptedMessageThreads.reduce(into: [:], { res, this in
            do {
                res[this.publicKey] = try decryptThread(this, for: publicKey, errorOnFailure: errorOnFailure)
            } catch {
                if errorOnFailure {
                    throw error
                }
            }
        })
    }
    
    func decryptThread(_ thread: EncryptedMessagesThread, for publicKey: String, errorOnFailure: Bool) throws -> [String] {
        guard let sharedSecret = try? keyStore.getSharedSecret(for: publicKey, and: thread.publicKey) else {
            throw IdentityError.missingSharedSecret
        }
        do {
        let decrypted = try decrypt(messages: thread.encryptedMessages, with: sharedSecret)
        return decrypted
    }
    
    private func decrypt(messages: [String], with secret: SharedSecret) throws -> [String] {
        return try messages.compactMap {
            return try decryptShared(privateKeyRecipient: secret.privateKey.uInt8Array,
                                      publicKeySender: secret.publicKey.uInt8Array,
                                      encrypted: $0.uInt8Array).stringValue
        }
    }
}
