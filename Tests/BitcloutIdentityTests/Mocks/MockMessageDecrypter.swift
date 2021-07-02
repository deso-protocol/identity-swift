//
//  File.swift
//  
//
//  Created by Andy Boyd on 02/07/2021.
//

import Foundation
@testable import BitcloutIdentity

class MockMessageDecrypter: MessageDecryptable {
    var mockDecryptedMessages = ["foo", "bar", "bat"]
    var calledDecryptMessages: Bool = false
    var messagesToDecrypt: EncryptedMessages?
    func decryptMessages(_ encryptedMessages: EncryptedMessages) throws -> [String] {
        calledDecryptMessages = true
        messagesToDecrypt = encryptedMessages
        return mockDecryptedMessages
    }
}
