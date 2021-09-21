//
//  File.swift
//
//
//  Created by Andy Boyd on 02/07/2021.
//

import Foundation
@testable import DeSoIdentity

class MockAuthWorker: Authable {
    var calledPresentAuthSession: Bool = false
    var contextProvided: PresentationContextProvidable?
    var networkRequested: Network?
    var overrideUrlSet: String?
    func presentAuthSession(context: PresentationContextProvidable,
                            on network: Network,
                            overrideUrl: String?,
                            with completion: Identity.LoginCompletion?) {
        calledPresentAuthSession = true
        contextProvided = context
        networkRequested = network
        overrideUrlSet = overrideUrl
        completion?(nil, nil)
    }
}
