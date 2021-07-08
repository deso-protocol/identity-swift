//
//  ECIES.swift
//  
//
//  Created by Andy Boyd on 06/07/2021.
//

import Foundation
import Security

import CryptoSwift
import secp256k1_implementation

enum ECIES {
    private func randomBytes(count: Int) throws -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

        guard status == errSecSuccess else {
            throw CryptoError.couldNotGenerateRandomBytes(status: status)
        }
        return bytes
    }
    
    // TODO: Verify that this exactly matched the implementation in https://github.com/bitclout/identity/blob/main/src/lib/ecies/index.js
    private func kdf(secret: [UInt8], outputLength: Int) -> [UInt8] {
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
    private func aesCtrEncrypt(iv: [UInt8], key: [UInt8], data: [UInt8]) throws -> [UInt8] {
        var cipher = try AES(key: key, blockMode: CTR(iv: iv), padding: .pkcs7).makeEncryptor()
        let firstChunk = try cipher.update(withBytes: data)
        let secondChunk = try cipher.finish()
        return firstChunk + secondChunk
    }

    private func aesCtrDecrypt(iv: [UInt8], key: [UInt8], data: [UInt8]) throws -> [UInt8] {
        var cipher = try AES(key: key, blockMode: CTR(iv: iv), padding: .pkcs7).makeDecryptor()
        let firstChunk = try cipher.update(withBytes: data)
        let secondChunk = try cipher.finish()
        return firstChunk + secondChunk
    }
    
    
    // Question: these return strings on the main identity library, but the non legacy ones return buffers.
    // Suspect in javascript they're interchangable, but not in Swift. Sticking with Buffers (i.e. UInt8 arrays) for both for consistency, is this ok?
    private func aesCtrEncryptLegacy(iv: [UInt8], key: [UInt8], data: [UInt8]) throws -> [UInt8] {
        var cipher = try AES(key: key, blockMode: CTR(iv: iv), padding: .pkcs7).makeEncryptor()
        return try cipher.update(withBytes: data)
    }
    
    private func aesCtrDecryptLegacy(iv: [UInt8], key: [UInt8], data: [UInt8]) throws -> [UInt8] {
        var cipher = try AES(key: key, blockMode: CTR(iv: iv), padding: .pkcs7).makeDecryptor()
        return try cipher.update(withBytes: data)
    }
    
    private func hmacSha256Sign(key: [UInt8], msg: [UInt8]) throws -> [UInt8] {
        return try HMAC(key: key, variant: .sha256).authenticate(msg)
    }
    
    /**
     Obtain the public elliptic curve key from a private
     */
    private func getPublicKey(from privateKey: [UInt8]) throws -> [UInt8] {
        guard privateKey.count == 32 else { throw CryptoError.badPrivateKey }
        let privKey = try secp256k1.Signing.PrivateKey(rawRepresentation: privateKey)
        return privKey.publicKey.rawRepresentation.bytes
    }
    
    /**
     ECDSA
     */
    private func sign(privateKey: [UInt8], msg: [UInt8]) throws -> [UInt8] {
        guard privateKey.count == 32 else { throw CryptoError.badPrivateKey }
        guard msg.count > 0 else { throw CryptoError.emptyMessage }
        guard msg.count <= 32 else { throw CryptoError.messageTooLong }
        
        let privKey = try secp256k1.Signing.PrivateKey(rawRepresentation: privateKey)
        return try privKey.signature(for: msg).derRepresentation().bytes
    }
    
    /**
     Verify ECDSA signatures
     */
    private func verify(publicKey: [UInt8], msg: [UInt8], sig: [UInt8]) throws -> Bool {
        guard publicKey.count == 65, publicKey[0] == 4 else { throw CryptoError.badPublicKey }
        guard msg.count > 0 else { throw CryptoError.emptyMessage }
        guard msg.count <= 32 else { throw CryptoError.messageTooLong }
        let signature = try secp256k1.Signing.ECDSASignature(derRepresentation: sig)
        return try secp256k1.Signing.PublicKey(rawRepresentation: publicKey).isValidSignature(signature, for: msg)
    }

    /**
     ECDH
    */
    private func derive(privateKeyA: [UInt8], publicKeyB: [UInt8]) throws -> [UInt8] {
        guard privateKeyA.count == 32 else { throw CryptoError.badPrivateKey }
        guard publicKeyB.count == 65, publicKeyB[0] == 4 else { throw CryptoError.badPublicKey }

        let keyA = try secp256k1.Signing.PrivateKey(rawRepresentation: privateKeyA)
        let keyB = try secp256k1.Signing.PublicKey(rawRepresentation: publicKeyB)
        
        /**
         The below commented code is from the javascript identity repo.
         Question: ec.keyFromPrivate and ec.keyFromPublic are generating keypairs from the elliptic curve, correct? And then keyA.derive() is generating the ECDH shared secret?
         I can't find a direct equivalent on the secp256k1 library we're using here, am I missing something, or do we need to find another library that can do it?
         */
//      const keyA = ec.keyFromPrivate(privateKeyA);
//      const keyB = ec.keyFromPublic(publicKeyB);
//      const Px = keyA.derive(keyB.getPublic());  // BN instance
//      return new Buffer(Px.toArray());
        
        return []
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
}
