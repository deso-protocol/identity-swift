//
//  Errors.swift
//  
//
//  Created by Andy Boyd on 29/06/2021.
//

import Foundation

public enum IdentityError: Swift.Error {
    case missingPresentationAnchor
    case notLoggedIn
    case missingInfoForPublicKey
    case keyInfoExpired
}
