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
    #if os(iOS)
    var mockPresentationAnchor = UIWindow()
    #elseif os(macOS)
    var mockPresentationAnchor = NSWindow()
    #endif
    var calledPresentationAnchor: Bool = false
    var sessionForAnchor: ASWebAuthenticationSession?
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        calledPresentationAnchor = true
        sessionForAnchor = session
        return mockPresentationAnchor
    }
}
