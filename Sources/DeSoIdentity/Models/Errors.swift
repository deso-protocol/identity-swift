//
//  Errors.swift
//  
//
//  Created by Andy Boyd on 29/06/2021.
//

import Foundation

public enum IdentityError: LocalizedError {
    case missingPresentationAnchor
    case notLoggedIn
    case missingInfoForPublicKey
    case keyInfoExpired
    case missingSharedSecret
    case signatureNotAString
    case nodeNotSpecified
    case derivedKeyExpired
}

enum CryptoError: LocalizedError {
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
