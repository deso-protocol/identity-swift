//
//  Errors.swift
//  
//
//  Created by Andy Boyd on 29/06/2021.
//

import Foundation

public enum IdentityError: Swift.Error {
    case missingPresentationAnchor
    case notLoggedIn
    case missingInfoForPublicKey
    case keyInfoExpired
}

enum CryptoError: Swift.Error {
    case badPrivateKey
    case badPublicKey
    case badSignature
    case couldNotGetPublicKey
    case emptyMessage
    case messageTooLong
    case couldNotGenerateRandomBytes(status: OSStatus)
    case invalidCipherText
    case incorrectMAC
}
