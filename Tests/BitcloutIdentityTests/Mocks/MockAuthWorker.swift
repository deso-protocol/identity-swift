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
    var contextProvided: PresentationContextProvidable?
    func presentAuthSession(context: PresentationContextProvidable, with completion: Identity.LoginCompletion?) {
        calledPresentAuthSession = true
        contextProvided = context
        completion?(nil, nil)
    }
}
