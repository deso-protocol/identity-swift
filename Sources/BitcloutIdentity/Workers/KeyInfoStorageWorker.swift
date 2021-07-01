//
//  File.swift
//  
//
//  Created by Andy Boyd on 30/06/2021.
//

import Foundation

protocol KeyInfoStorable {
    func store(_ info: DerivedKeyInfo) throws
    func clearAllDerivedKeyInfo()
    func clearDerivedKeyInfo(for publicKey: String)
    func getDerivedKeyInfo(for publicKey: String) throws -> DerivedKeyInfo?
}

class KeyInfoStorageWorker: KeyInfoStorable {
    private enum Keys: String {
        case derivedKeyInfo
    }
    
    let defaults = UserDefaults.standard
    
    func store(_ info: DerivedKeyInfo) throws {
        var storedInfo = defaults.dictionary(forKey: Keys.derivedKeyInfo.rawValue) ?? [:]
        let data = try JSONEncoder().encode(info)
        storedInfo[info.truePublicKey] = data
        defaults.setValue(storedInfo, forKey: Keys.derivedKeyInfo.rawValue)
    }
    
    func clearAllDerivedKeyInfo() {
        defaults.removeObject(forKey: Keys.derivedKeyInfo.rawValue)
    }
    
    func clearDerivedKeyInfo(for publicKey: String) {
        var storedInfo = defaults.dictionary(forKey: Keys.derivedKeyInfo.rawValue) ?? [:]
        storedInfo[publicKey] = nil
        defaults.setValue(storedInfo, forKey: Keys.derivedKeyInfo.rawValue)
    }
    
    func getDerivedKeyInfo(for publicKey: String) throws -> DerivedKeyInfo? {
        guard let data = defaults.dictionary(forKey: Keys.derivedKeyInfo.rawValue),
              let thisPublicKeyData = data[publicKey] as? Data else { return nil }
        return try JSONDecoder().decode(DerivedKeyInfo.self, from: thisPublicKeyData)
    }
}
