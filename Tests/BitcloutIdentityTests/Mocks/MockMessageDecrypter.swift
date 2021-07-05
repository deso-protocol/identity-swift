//
//  File.swift
//  
//
//  Created by Andy Boyd on 02/07/2021.
//

import Foundation
@testable import BitcloutIdentity

class MockMessageDecrypter: MessageDecryptable {
    var mockDecryptedMessages = ["foo": ["bar"], "bar": ["bat"], "bat": ["foo"]]
    var calledDecryptMessages: Bool = false
    var messagesToDecrypt: [EncryptedMessagesThread]?
    func decryptMessages(_ encryptedMessageThreads: [EncryptedMessagesThread]) throws -> [String: [String]] {
        calledDecryptMessages = true
        messagesToDecrypt = encryptedMessageThreads
        return mockDecryptedMessages
    }
}
