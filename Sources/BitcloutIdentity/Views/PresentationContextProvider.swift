//
//  PresentationContextProvider.swift
//  
//
//  Created by Andy Boyd on 29/06/2021.
//

import Foundation
import AuthenticationServices

protocol PresentationContextProvidable: ASWebAuthenticationPresentationContextProviding {}

class PresentationContextProvider: NSObject, PresentationContextProvidable {
    private let anchor: ASPresentationAnchor
    
    init(anchor: ASPresentationAnchor) {
        self.anchor = anchor
    }
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return anchor
    }
}
