//
//  MessageDecryptionWorker.swift
//  
//
//  Created by Andy Boyd on 29/06/2021.
//

import Foundation

protocol MessageDecryptable {
    // TODO: confirm interface. May need a public key/other crypto info passed as well
    func decryptMessages(_ encryptedMessageThreads: [EncryptedMessagesThread]) throws -> [String: [String]]
}

class MessageDecryptionWorker: MessageDecryptable {
    func decryptMessages(_ encryptedMessageThreads: [EncryptedMessagesThread]) throws -> [String: [String]] {
        // TODO: Actually decrypt the messages
        return encryptedMessageThreads.reduce(into: [:], { res, this in
            res[this.publicKey] = this.encryptedMessages
        })
    }
}
