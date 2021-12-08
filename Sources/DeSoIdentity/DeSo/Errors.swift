//
//  File.swift
//  
//
//  Created by Jacob Davis on 12/7/21.
//

import Foundation

public enum DeSoIdentityError: LocalizedError {
    case noDerivedKeyInfoFound
    case unableToFormIdentityUrl
    case missingPresentationAnchor
    case authUrlReturnMissing
    case httpResponseFailure
    case noUserFoundForPublicKey
    case backend(String)
    case unknown
    case error(message: String)
//    case notLoggedIn
//    case missingInfoForPublicKey
//    case keyInfoExpired
//    case missingSharedSecret
//    case signatureNotAString
//    case nodeNotSpecified
//    case derivedKeyExpired
//    case unableToDecodeResponse
//    case noUrlReturned
    case unexpectedDerivedKeyData
//    case submitTransactionFailure
//    case couldntstorekey
}

public struct DeSoBackendErrorResponse: Codable {
    public let error: String
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
