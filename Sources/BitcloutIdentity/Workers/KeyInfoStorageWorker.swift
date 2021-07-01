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
    func clearAllDerivedKeyInfo() throws
    func clearDerivedKeyInfo(for publicKey: String) throws
    func getDerivedKeyInfo(for publicKey: String) throws -> DerivedKeyInfo?
}

class KeyInfoStorageWorker: KeyInfoStorable {
    private enum Keys: String {
        case derivedKeyInfo
    }
    
    private let keychain: Keychain
    
    init() {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            fatalError()
        }
        self.keychain = Keychain(service: bundleId)
    }
    
    func store(_ info: DerivedKeyInfo) throws {
        var storedInfo = try getExistingInfo() ?? [:]
        let data = try JSONEncoder().encode(info)
        storedInfo[info.truePublicKey] = data
        try setKeyInfoOnKeychain(storedInfo)
    }
    
    func clearAllDerivedKeyInfo() throws {
        try keychain.remove(Keys.derivedKeyInfo.rawValue)
    }
    
    func clearDerivedKeyInfo(for publicKey: String) throws {
        guard var storedInfo = try getExistingInfo() else { return }
        storedInfo[publicKey] = nil
        try setKeyInfoOnKeychain(storedInfo)
    }
    
    func getDerivedKeyInfo(for publicKey: String) throws -> DerivedKeyInfo? {
        guard let thisPublicKeyData = try getExistingInfo()?[publicKey] else { return nil }
        return try JSONDecoder().decode(DerivedKeyInfo.self, from: thisPublicKeyData)
    }
    
    private func getExistingInfo() throws -> [String: Data]? {
        guard let data = try keychain.getData(Keys.derivedKeyInfo.rawValue) else { return nil }
        return try JSONDecoder().decode([String: Data].self, from: data)
    }
    
    private func setKeyInfoOnKeychain(_ info: [String: Data]) throws {
        let keychainData = try JSONEncoder().encode(info)
        try keychain.set(keychainData, key: Keys.derivedKeyInfo.rawValue)
    }
}
