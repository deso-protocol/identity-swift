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
    var networkRequested: Network?
    func presentAuthSession(context: PresentationContextProvidable,
                            on network: Network,
                            with completion: Identity.LoginCompletion?) {
        calledPresentAuthSession = true
        contextProvided = context
        networkRequested = network
        completion?(nil, nil)
    }
}
