//
//  ECIES.swift
//  
//
//  Created by Andy Boyd on 06/07/2021.
//

import Foundation
import Security

import CryptoSwift
import SwiftECC
import BigInt
import ASN1

private let ec = Domain.instance(curve: .EC256k1)

func randomBytes(count: Int) throws -> [UInt8] {
    var bytes = [UInt8](repeating: 0, count: count)
    let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
    
    guard status == errSecSuccess else {
        throw CryptoError.couldNotGenerateRandomBytes(status: status)
    }
    return bytes
}

// TODO: Verify that this exactly matched the implementation in https://github.com/bitclout/identity/blob/main/src/lib/ecies/index.js
func kdf(secret: [UInt8], outputLength: Int) -> [UInt8] {
    var ctr: UInt8 = 1
    var written = 0
    var result: [UInt8] = []
    while (written < outputLength) {
        var ctrs: [UInt8] = [ctr >> 24, ctr >> 16, ctr >> 8, ctr]
        ctrs.append(contentsOf: secret)
        let hashResult = Hash.sha256(ctrs)
        result.append(contentsOf: hashResult)
        written += 32
        ctr += 1
    }
    return result
}

// Question: For the AES encryption/decryption, is pkcs7 the correct padding to use?
func aesCtrEncrypt(iv: [UInt8], key: [UInt8], data: [UInt8]) throws -> [UInt8] {
    var cipher = try AES(key: key, blockMode: CTR(iv: iv), padding: .pkcs7).makeEncryptor()
    let firstChunk = try cipher.update(withBytes: data)
    let secondChunk = try cipher.finish()
    return firstChunk + secondChunk
}

func aesCtrDecrypt(iv: [UInt8], key: [UInt8], data: [UInt8]) throws -> [UInt8] {
    var cipher = try AES(key: key, blockMode: CTR(iv: iv), padding: .pkcs7).makeDecryptor()
    let firstChunk = try cipher.update(withBytes: data)
    let secondChunk = try cipher.finish()
    return firstChunk + secondChunk
}


// Question: these return strings on the main identity library, but the non legacy ones return buffers.
// Suspect in javascript they're interchangable, but not in Swift. Sticking with Buffers (i.e. UInt8 arrays) for both for consistency, is this ok?
func aesCtrEncryptLegacy(iv: [UInt8], key: [UInt8], data: [UInt8]) throws -> [UInt8] {
    var cipher = try AES(key: key, blockMode: CTR(iv: iv), padding: .pkcs7).makeEncryptor()
    return try cipher.update(withBytes: data)
}

func aesCtrDecryptLegacy(iv: [UInt8], key: [UInt8], data: [UInt8]) throws -> [UInt8] {
    var cipher = try AES(key: key, blockMode: CTR(iv: iv), padding: .pkcs7).makeDecryptor()
    return try cipher.update(withBytes: data)
}

func hmacSha256Sign(key: [UInt8], msg: [UInt8]) throws -> [UInt8] {
    return try HMAC(key: key, variant: .sha256).authenticate(msg)
}

/**
 Obtain the public elliptic curve key from a private
 */
func getPublicKey(from privateKey: [UInt8]) throws -> [UInt8] {
    guard privateKey.count == 32 else { throw CryptoError.badPrivateKey }
    let privKey = try ECPrivateKey(der: privateKey)
    let pubKey = ec.multiply(ec.g, privKey.s)
    return try ec.encodePoint(pubKey)
}

/**
 ECDSA
 */
func sign(privateKey: [UInt8], msg: [UInt8]) throws -> [UInt8] {
    guard privateKey.count == 32 else { throw CryptoError.badPrivateKey }
    guard msg.count > 0 else { throw CryptoError.emptyMessage }
    guard msg.count <= 32 else { throw CryptoError.messageTooLong }
    
    let privKey = try ECPrivateKey(der: privateKey)
    return privKey.sign(msg: msg).asn1.encode()
}

/**
 Verify ECDSA signatures
 */
func verify(publicKey: [UInt8], msg: [UInt8], sig: [UInt8]) throws -> Bool {
    guard publicKey.count == 65, publicKey[0] == 4 else { throw CryptoError.badPublicKey }
    guard msg.count > 0 else { throw CryptoError.emptyMessage }
    guard msg.count <= 32 else { throw CryptoError.messageTooLong }
    let pubKey = try ECPublicKey(der: publicKey)
    let signature = try ECSignature(asn1: ASN1.build(sig), domain: ec)
    return pubKey.verify(signature: signature, msg: msg)
}

/**
 ECDH
 */
func derive(privateKeyA: [UInt8], publicKeyB: [UInt8]) throws -> [UInt8] {
    let domain = Domain.instance(curve: .EC256k1)
    
    let keyA = try ECPrivateKey(der: privateKeyA)
    let keyB = try ECPublicKey(der: publicKeyB)
    
    let derived = domain.multiply(keyB.w, keyA.s)
    return try domain.encodePoint(derived)
}

/**
 Encrypt AES-128-CTR and serialise as in Parity
 Serialization: <ephemPubKey><IV><CipherText><HMAC>
 */
func encrypt(publicKeyTo: [UInt8], msg: [UInt8], ephemPrivateKey: [UInt8]? = nil, iv: [UInt8]? = nil, legacy: Bool = false) throws -> [UInt8] {
    let ephemPrivateKey = try ephemPrivateKey ?? randomBytes(count: 32)
    let ephemPublicKey = try getPublicKey(from: ephemPrivateKey)
    
    let sharedPx = try derive(privateKeyA: ephemPrivateKey, publicKeyB: publicKeyTo)
    let hash =  kdf(secret: sharedPx, outputLength: 32)
    let iv = try iv ?? randomBytes(count: 16)
    let encryptionKey = hash.slice(from: 0, length: 16)
    
    let macKey = Hash.sha256(hash.slice(from: 16))
    
    let cipherText = try legacy ?
        aesCtrEncryptLegacy(iv: iv, key: encryptionKey, data: msg) :
        aesCtrEncrypt(iv: iv, key: encryptionKey, data: msg)
    
    let dataToMac = iv + cipherText
    let hmac = try hmacSha256Sign(key: macKey, msg: dataToMac)
    
    return ephemPublicKey + iv + cipherText + hmac
}

/**
 Decrypt serialised AES-128-CTR
 */
func decrypt(privateKey: [UInt8], encrypted: [UInt8], legacy: Bool = false) throws -> [UInt8] {
    let metaLength = 1 + 64 + 16 + 32
    guard encrypted.count > metaLength, encrypted[0] >= 2, encrypted[0] <= 4 else { throw CryptoError.invalidCipherText }
    
    // deserialize
    let ephemPublicKey = encrypted.slice(from: 0, length: 65)
    let cipherTextLength = encrypted.count - metaLength
    let iv = encrypted.slice(from: 65, length: 65 + 16)
    let cipherAndIv = encrypted.slice(from: 65, length: 65 + 16 + cipherTextLength)
    let cipherText = cipherAndIv.slice(from: 16)
    let msgMac = encrypted.slice(from: 65 + 16 + cipherTextLength)
    
    // check HMAC
    let px = try derive(privateKeyA: privateKey, publicKeyB: ephemPublicKey)
    let hash = kdf(secret: px, outputLength: 32)
    let encryptionKey = hash.slice(from: 0, length: 16)
    let macKey = Hash.sha256(hash.slice(from: 16))
    guard try hmacSha256Sign(key: macKey, msg: cipherAndIv) == msgMac else { throw CryptoError.incorrectMAC }
    
    return try legacy ?
        aesCtrDecryptLegacy(iv: iv, key: encryptionKey, data: cipherText) :
        aesCtrDecrypt(iv: iv, key: encryptionKey, data: cipherText)
}

/**
 Encrypt AES-128-CTR and serialise as in Parity
 Using ECDH shared secret KDF
 Serialization: <ephemPubKey><IV><CipherText><HMAC>
 */
func encryptShared(privateKeySender: [UInt8],
                   publicKeyRecipient: [UInt8],
                   msg: [UInt8],
                   ephemPrivateKey: [UInt8]? = nil,
                   iv: [UInt8]? = nil) throws -> [UInt8] {
    let sharedPx = try derive(privateKeyA: privateKeySender, publicKeyB: publicKeyRecipient)
    let sharedPrivateKey = kdf(secret: sharedPx, outputLength: 32)
    let sharedPublicKey = try getPublicKey(from: sharedPrivateKey)
    
    return try encrypt(publicKeyTo: sharedPublicKey,
                       msg: msg,
                       ephemPrivateKey: ephemPrivateKey,
                       iv: iv)
}

/**
 Decrypt serialised AES-128-CTR
 Using ECDH shared secret KDF
 */
func decryptShared(privateKeyRecipient: [UInt8], publicKeySender: [UInt8], encrypted: [UInt8]) throws -> [UInt8] {
    let sharedPx = try derive(privateKeyA: privateKeyRecipient, publicKeyB: publicKeySender)
    let sharedPrivateKey = kdf(secret: sharedPx, outputLength: 32)
    return try decrypt(privateKey: sharedPrivateKey, encrypted: encrypted)
}
