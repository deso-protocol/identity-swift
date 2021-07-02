//
//  File.swift
//
//
//  Created by Andy Boyd on 02/07/2021.
//

import Foundation
@testable import BitcloutIdentity

class MockAuthWorker: Authable {
    var calledPresentAuthSession: Bool = false
    var accessLevelRequested: AccessLevel?
    var contextProvided: PresentationContextProvidable?
    func presentAuthSession(accessLevel: AccessLevel, context: PresentationContextProvidable) {
        calledPresentAuthSession = true
        accessLevelRequested = accessLevel
        contextProvided = context
    }
}
