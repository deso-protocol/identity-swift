//
//  File.swift
//  
//
//  Created by Andy Boyd on 02/07/2021.
//

import Foundation
import AuthenticationServices
@testable import BitcloutIdentity

class MockPresentationContextProvider: NSObject, PresentationContextProvidable {
    var mockPresentationAnchor = UIWindow()
    var calledPresentationAnchor: Bool = false
    var sessionForAnchor: ASWebAuthenticationSession?
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        calledPresentationAnchor = true
        sessionForAnchor = session
        return mockPresentationAnchor
    }
}
