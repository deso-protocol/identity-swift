//
//  MessageDecryptionWorker.swift
//  
//
//  Created by Andy Boyd on 29/06/2021.
//

import Foundation

protocol MessageDecryptable {
    // TODO: confirm interface. May need a public key/other crypto info passed as well
    func decryptMessages(_ encryptedMessages: EncryptedMessages) throws -> [String]
}

class MessageDecryptionWorker: MessageDecryptable {
    func decryptMessages(_ encryptedMessages: EncryptedMessages) throws -> [String] {
        // TODO: Actually decrypt the messages
        return encryptedMessages.encryptedMessages
    }
}
