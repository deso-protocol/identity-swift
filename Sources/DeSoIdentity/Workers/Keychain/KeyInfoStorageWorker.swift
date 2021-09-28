//
//  KeyInfoStorageWorker.swift
//  
//
//  Created by Andy Boyd on 30/06/2021.
//

import Foundation
import KeychainAccess

enum Keys: String {
    case derivedKeyInfo
    case sharedSecrets
}

protocol KeyInfoStorable {
    var keychain: DataStorable { get set }
    mutating func store(_ info: DerivedKeyInfo) throws
    mutating func store(sharedSecret: SharedSecret) throws
    mutating func clearAllStoredInfo() throws
    mutating func clearDerivedKeyInfo(for publicKey: String) throws
    mutating func clearAllSharedSecrets(for privateKey: String) throws
    mutating func clearSharedSecret(for privateKey: String, and publicKey: String) throws
    func getDerivedKeyInfo(for publicKey: String) throws -> DerivedKeyInfo?
    func getAllStoredKeys() throws -> [String]
    func getSharedSecret(for myPublicKey: String, and otherPublicKey: String) throws -> SharedSecret?
    func getAllSharedSecrets() throws -> [SharedSecret]
}

protocol DataStorable {
    func getData(_ key: String) throws -> Data?
    mutating func set(_ value: Data, key: String) throws
    mutating func remove(_ key: String) throws
}

/**
 Ephemeral Key store for use when storage to the keychain is not desired or supported, e.g. when testing on simulator
 */
class EphemeralKeyStore: KeyInfoStorable {
    var keychain: DataStorable = [String: String]()
}

/**
 KeyInfoStorageWorker will store and retrieve key information from the secure device keychain
 */
class KeyInfoStorageWorker: KeyInfoStorable {
    var keychain: DataStorable
    
    init() {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            fatalError()
        }
        self.keychain = Keychain(service: bundleId)
    }
}

extension Keychain: DataStorable {
    func getData(_ key: String) throws -> Data? {
        return try getData(key, ignoringAttributeSynchronizable: true)
    }
    
    func remove(_ key: String) throws {
        try remove(key, ignoringAttributeSynchronizable: true)
    }
    
    func set(_ value: Data, key: String) throws {
        try set(value, key: key, ignoringAttributeSynchronizable: true)
    }
}

extension Dictionary: DataStorable where Key == String, Value == String {
    func getData(_ key: String) throws -> Data? {
        guard let string = self[key] else { return nil }
        return Data(base64Encoded: string)
    }
    
    mutating func set(_ value: Data, key: String) throws {
        self[key] = value.base64EncodedString()
    }
    
    mutating func remove(_ key: String) throws {
        self[key] = nil
    }
}

extension KeyInfoStorable {
    mutating func store(_ info: DerivedKeyInfo) throws {
        var storedInfo = try getExistingDerivedKeyInfo() ?? [:]
        let data = try JSONEncoder().encode(info)
        storedInfo[info.publicKey] = data
        try setKeyInfoOnKeychain(storedInfo)
    }
    
    mutating func store(sharedSecret: SharedSecret) throws {
        var storedSecrets = try getExistingSharedSecrets() ?? []
        if let existingIndex = storedSecrets
            .firstIndex(
                where: {
                    $0.privateKey == sharedSecret.privateKey &&
                        $0.publicKey == sharedSecret.publicKey
                }
            ) {
            storedSecrets[existingIndex] = sharedSecret
        } else {
            storedSecrets.append(sharedSecret)
        }
        try setSharedSecretsOnKeychain(storedSecrets)
    }
    
    mutating func clearAllStoredInfo() throws {
        try keychain.remove(Keys.derivedKeyInfo.rawValue)
        try keychain.remove(Keys.sharedSecrets.rawValue)
    }
    
    mutating func clearDerivedKeyInfo(for publicKey: String) throws {
        guard var storedInfo = try getExistingDerivedKeyInfo() else { return }
        storedInfo[publicKey] = nil
        try setKeyInfoOnKeychain(storedInfo)
    }
    
    mutating func clearAllSharedSecrets(for privateKey: String) throws {
        guard var storedSecrets = try getExistingSharedSecrets() else { return }
        storedSecrets.removeAll(where: {
            $0.privateKey == privateKey
        })
        try setSharedSecretsOnKeychain(storedSecrets)
    }
    
    mutating func clearSharedSecret(for privateKey: String, and publicKey: String) throws {
        guard var storedSecrets = try getExistingSharedSecrets() else { return }
        storedSecrets.removeAll(where: {
            $0.privateKey == privateKey &&
                $0.publicKey == publicKey
        })
        try setSharedSecretsOnKeychain(storedSecrets)
    }
    
    func getDerivedKeyInfo(for publicKey: String) throws -> DerivedKeyInfo? {
        guard let thisPublicKeyData = try getExistingDerivedKeyInfo()?[publicKey] else { return nil }
        return try JSONDecoder().decode(DerivedKeyInfo.self, from: thisPublicKeyData)
    }
    
    func getAllStoredKeys() throws -> [String] {
        guard let data = try keychain.getData(Keys.derivedKeyInfo.rawValue) else { return [] }
        let storedData = try JSONDecoder().decode([String: DerivedKeyInfo].self, from: data)
        return storedData.keys.map { $0 }
    }
    
    func getSharedSecret(for myPublicKey: String, and otherPublicKey: String) throws -> SharedSecret? {
        let sharedSecrets = try getAllSharedSecrets()
        return sharedSecrets
            .first {
                $0.myTruePublicKey == myPublicKey && $0.publicKey == otherPublicKey
            }
    }
    
    func getAllSharedSecrets() throws -> [SharedSecret] {
        guard let data = try keychain.getData(Keys.sharedSecrets.rawValue) else { return [] }
        let storedData = try JSONDecoder().decode([SharedSecret].self, from: data)
        return storedData
    }
    
    private func getExistingDerivedKeyInfo() throws -> [String: Data]? {
        guard let data = try keychain.getData(Keys.derivedKeyInfo.rawValue) else { return nil }
        return try JSONDecoder().decode([String: Data].self, from: data)
    }
    
    private mutating func setKeyInfoOnKeychain(_ info: [String: Data]) throws {
        let keychainData = try JSONEncoder().encode(info)
        try keychain.set(keychainData, key: Keys.derivedKeyInfo.rawValue)
    }
    
    private func getExistingSharedSecrets() throws -> [SharedSecret]? {
        guard let data = try keychain.getData(Keys.sharedSecrets.rawValue) else { return nil }
        return try JSONDecoder().decode([SharedSecret].self, from: data)
    }
    
    private mutating func setSharedSecretsOnKeychain(_ secrets: [SharedSecret]) throws {
        let keychainData = try JSONEncoder().encode(secrets)
        try keychain.set(keychainData, key: Keys.sharedSecrets.rawValue)
    }
}
