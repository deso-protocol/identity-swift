//
//  KeyInfoStorageWorker.swift
//  
//
//  Created by Andy Boyd on 30/06/2021.
//

import Foundation
import KeychainAccess

protocol KeyInfoStorable {
    func store(_ info: DerivedKeyInfo) throws
    func store(sharedSecret: SharedSecret) throws
    func clearAllStoredInfo() throws
    func clearDerivedKeyInfo(for publicKey: String) throws
    func clearAllSharedSecrets(for privateKey: String) throws
    func clearSharedSecret(for privateKey: String, and publicKey: String) throws
    func getDerivedKeyInfo(for publicKey: String) throws -> DerivedKeyInfo?
    func getAllStoredKeys() throws -> [String]
    func getSharedSecret(for myPublicKey: String, and otherPublicKey: String) throws -> SharedSecret?
    func getAllSharedSecrets() throws -> [SharedSecret]
}

class KeyInfoStorageWorker: KeyInfoStorable {
    private enum Keys: String {
        case derivedKeyInfo
        case sharedSecrets
    }
    
    private let keychain: Keychain
    
    init() {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            fatalError()
        }
        self.keychain = Keychain(service: bundleId)
    }
    
    func store(_ info: DerivedKeyInfo) throws {
        var storedInfo = try getExistingDerivedKeyInfo() ?? [:]
        let data = try JSONEncoder().encode(info)
        storedInfo[info.publicKey] = data
        try setKeyInfoOnKeychain(storedInfo)
    }
    
    func store(sharedSecret: SharedSecret) throws {
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
    
    func clearAllStoredInfo() throws {
        try keychain.remove(Keys.derivedKeyInfo.rawValue)
        try keychain.remove(Keys.sharedSecrets.rawValue)
    }
    
    func clearDerivedKeyInfo(for publicKey: String) throws {
        guard var storedInfo = try getExistingDerivedKeyInfo() else { return }
        storedInfo[publicKey] = nil
        try setKeyInfoOnKeychain(storedInfo)
    }
    
    func clearAllSharedSecrets(for privateKey: String) throws {
        guard var storedSecrets = try getExistingSharedSecrets() else { return }
        storedSecrets.removeAll(where: {
            $0.privateKey == privateKey
        })
        try setSharedSecretsOnKeychain(storedSecrets)
    }
    
    func clearSharedSecret(for privateKey: String, and publicKey: String) throws {
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
    
    private func setKeyInfoOnKeychain(_ info: [String: Data]) throws {
        let keychainData = try JSONEncoder().encode(info)
        try keychain.set(keychainData, key: Keys.derivedKeyInfo.rawValue)
    }
    
    private func getExistingSharedSecrets() throws -> [SharedSecret]? {
        guard let data = try keychain.getData(Keys.sharedSecrets.rawValue) else { return nil }
        return try JSONDecoder().decode([SharedSecret].self, from: data)
    }
    
    private func setSharedSecretsOnKeychain(_ secrets: [SharedSecret]) throws {
        let keychainData = try JSONEncoder().encode(secrets)
        try keychain.set(keychainData, key: Keys.sharedSecrets.rawValue)
    }
}
