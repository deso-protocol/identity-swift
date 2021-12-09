//
//  Keychain+Ext.swift
//  
//
//  Created by Jacob Davis on 12/7/21.
//

import Foundation
import KeychainAccess

enum StorableKeys: String {
    case derivedKeyInfo
    case sharedSecrets
}

protocol DataStorable {
    func getData(_ key: String) throws -> Data?
    mutating func set(_ value: Data, key: String) throws
    mutating func remove(_ key: String) throws
    mutating func clearAllStoredInfo() throws
    func getDerivedKeyInfo(for publicKey: String) throws -> DerivedKeyInfo
    mutating func store(_ info: DerivedKeyInfo) throws
    mutating func clearDerivedKeyInfo(for publicKey: String) throws
    func getAllStoredKeys() throws -> [String]
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
    
    mutating func clearAllStoredInfo() throws {
        self.removeAll()
    }
}

extension Keychain: DataStorable {
    
    func getData(_ key: String) throws -> Data? {
        return try getData(key, ignoringAttributeSynchronizable: true)
    }
    
    func set(_ value: Data, key: String) throws {
        try set(value, key: key, ignoringAttributeSynchronizable: true)
    }
    
    func remove(_ key: String) throws {
        try remove(key, ignoringAttributeSynchronizable: true)
    }

    func clearAllStoredInfo() throws {
        try remove(StorableKeys.derivedKeyInfo.rawValue)
        try remove(StorableKeys.sharedSecrets.rawValue)
    }
}

extension DataStorable {
    
    func getDerivedKeyInfo(for publicKey: String) throws -> DerivedKeyInfo {

        guard let storedInfo = try? getExistingDerivedKeyInfo() else {
            throw DeSoIdentityError.noDerivedKeyInfoFound
        }
        
        guard let storedDataForKey = storedInfo[publicKey] else {
            throw DeSoIdentityError.noDerivedKeyInfoFound
        }
        
        return try JSONDecoder().decode(DerivedKeyInfo.self, from: storedDataForKey)
    }
    
    mutating func store(_ info: DerivedKeyInfo) throws {

        var storedInfo = try getExistingDerivedKeyInfo()
        
        let newData = try JSONEncoder().encode(info)
        storedInfo[info.publicKey] = newData

        let storedData = try JSONEncoder().encode(storedInfo)
        try set(storedData, key: StorableKeys.derivedKeyInfo.rawValue)
    }
    
    mutating func clearDerivedKeyInfo(for publicKey: String) throws {
        
        guard var storedInfo = try? getExistingDerivedKeyInfo() else {
            throw DeSoIdentityError.noDerivedKeyInfoFound
        }
        
        storedInfo[publicKey] = nil

        let storedData = try JSONEncoder().encode(storedInfo)
        try set(storedData, key: StorableKeys.derivedKeyInfo.rawValue)
    }
    
    func getAllStoredKeys() throws -> [String] {
        guard let storedInfo = try? getExistingDerivedKeyInfo() else {
            throw DeSoIdentityError.noDerivedKeyInfoFound
        }
        return storedInfo.keys.map { $0 }
    }
    
    private func getExistingDerivedKeyInfo() throws -> [String: Data] {
        guard let data = try getData(StorableKeys.derivedKeyInfo.rawValue) else {
            return [String: Data]()
        }
        if let decodedData = try? JSONDecoder().decode([String: Data].self, from: data) {
            return decodedData
        }
        return [String: Data]()
    }

    mutating func store(_ sharedSecret: SharedSecret) throws {

        var storedInfo = try getExistingSharedSecrets() ?? []
        
        if let existingIndex = storedInfo
            .firstIndex(
                where: {
                    $0.publicKey == sharedSecret.publicKey &&
                        $0.otherPublicKey == sharedSecret.otherPublicKey
                }
            ) {
            storedInfo[existingIndex] = sharedSecret
        } else {
            storedInfo.append(sharedSecret)
        }
        
        let storedData = try JSONEncoder().encode(storedInfo)
        try set(storedData, key: StorableKeys.sharedSecrets.rawValue)
    }
    
    
    func getSharedSecret(for myPublicKey: String, and otherPublicKey: String) throws -> SharedSecret? {
        let sharedSecrets = try getAllSharedSecrets()
        return sharedSecrets
            .first(where: { $0.publicKey == myPublicKey && $0.otherPublicKey == otherPublicKey })
    }
    
    func getSharedSecrets(for myPublicKey: String, and otherPublicKeys: [String]) throws -> [SharedSecret]? {
        let sharedSecrets = try getAllSharedSecrets()
        
        var foundSecrets = [SharedSecret]()
        for otherPublicKey in otherPublicKeys {
            if let secret = sharedSecrets.first(where: { $0.publicKey == myPublicKey && $0.otherPublicKey == otherPublicKey }) {
                foundSecrets.append(secret)
            } else {
                throw DeSoIdentityError.error(message: "Not all shared keys where found")
            }
        }
        
        return foundSecrets
    }
    
    func getAllSharedSecrets() throws -> [SharedSecret] {
        guard let data = try DeSoIdentity.keychain.getData(StorableKeys.sharedSecrets.rawValue) else { return [] }
        let storedData = try JSONDecoder().decode([SharedSecret].self, from: data)
        return storedData
    }
    
    private func getExistingSharedSecrets() throws -> [SharedSecret]? {
        guard let data = try getData(StorableKeys.sharedSecrets.rawValue) else {
            return [SharedSecret]()
        }
        if let decodedData = try? JSONDecoder().decode([SharedSecret].self, from: data) {
            return decodedData
        }
        return [SharedSecret]()
    }
    
    private mutating func setSharedSecretsOnKeychain(_ secrets: [SharedSecret]) throws {
        let keychainData = try JSONEncoder().encode(secrets)
        try DeSoIdentity.keychain.set(keychainData, key: StorableKeys.sharedSecrets.rawValue)
    }
}
