//
//  DeSoLoginResponse.swift
//  
//
//  Created by Jacob Davis on 12/8/21.
//

import Foundation

public struct DeSoLoginResponse {
    
    public enum LoginState {
        case authorized
        case notAuthorized
        case expiredAuthorization
        case insufficentBalanceForAuthorization
    }
    
    public let selectedPublicKey: String
    public let allLoadedPublicKeys: [String]
    public let loginState: LoginState
}
