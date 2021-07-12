//
//  MessageDecryptionWorker.swift
//  
//
//  Created by Andy Boyd on 29/06/2021.
//

import Foundation

protocol MessageDecryptable {
    // TODO: confirm interface. May need a public key/other crypto info passed as well
    func decryptMessages(_ encryptedMessageThreads: [EncryptedMessagesThread], for privateKey: String) throws -> [String: [String]]
}

class MessageDecryptionWorker: MessageDecryptable {
    
    private let keyStore: KeyInfoStorable
    
    init(keyStore: KeyInfoStorable = KeyInfoStorageWorker()) {
        self.keyStore = keyStore
    }
    
    func decryptMessages(_ encryptedMessageThreads: [EncryptedMessagesThread], for privateKey: String) throws -> [String: [String]] {
        // TODO: Actually decrypt the messages
        return encryptedMessageThreads.reduce(into: [:], { res, this in
            guard let sharedSecret = try? keyStore.getSharedSecret(for: privateKey, and: this.publicKey) else {
                return
            }
            let decrypted = decrypt(messages: this.encryptedMessages, with: sharedSecret)
            res[this.publicKey] = decrypted
        })
    }
    
    private func decrypt(messages: [String], with secret: SharedSecret) -> [String] {
        return messages.compactMap {
            return try? decryptShared(privateKeyRecipient: secret.privateKey.uInt8Array,
                                          publicKeySender: secret.publicKey.uInt8Array,
                                          encrypted: $0.uInt8Array).stringValue
        }
    }
}
