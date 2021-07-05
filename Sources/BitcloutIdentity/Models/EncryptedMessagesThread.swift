//
//  EncryptedMessages.swift
//  
//
//  Created by Andy Boyd on 29/06/2021.
//

import Foundation

public struct EncryptedMessagesThread: Equatable {
    let publicKey: String
    let encryptedMessages: [String]
}
