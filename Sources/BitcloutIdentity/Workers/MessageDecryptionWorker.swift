//
//  File.swift
//  
//
//  Created by Andy Boyd on 29/06/2021.
//

import Foundation

protocol MessageDecryptable {
    func decryptMessages(_ encryptedMessages: EncryptedMessages) -> [String]
}

class MessageDecryptionWorker: MessageDecryptable {
    func decryptMessages(_ encryptedMessages: EncryptedMessages) -> [String] {
        // TODO: Actually decrypt the messages
        return encryptedMessages.encryptedMessages
    }
}
