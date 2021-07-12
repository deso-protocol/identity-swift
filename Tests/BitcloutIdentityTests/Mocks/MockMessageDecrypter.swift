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
    var calledDecryptThreads: Bool = false
    var messagesToDecrypt: [EncryptedMessagesThread]?
    var publicKeyToDecryptFor: String?
    var errorOnFailure: Bool?
    func decryptThreads(_ encryptedMessageThreads: [EncryptedMessagesThread], for myPublicKey: String, errorOnFailure: Bool) throws -> [String: [String]] {
        calledDecryptThreads = true
        messagesToDecrypt = encryptedMessageThreads
        publicKeyToDecryptFor = myPublicKey
        self.errorOnFailure = errorOnFailure
        return mockDecryptedMessages
    }
    
    var calledDecryptThread: Bool = false
    var threadToDecrypt: EncryptedMessagesThread?
    func decryptThread(_ thread: EncryptedMessagesThread, for publicKey: String, errorOnFailure: Bool) throws -> [String] {
        calledDecryptThread = true
        threadToDecrypt = thread
        publicKeyToDecryptFor = publicKey
        self.errorOnFailure = errorOnFailure
        return mockDecryptedMessages[thread.publicKey] ?? []
    }
}
