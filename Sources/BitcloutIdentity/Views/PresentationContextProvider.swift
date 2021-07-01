//
//  PresentationContextProvider.swift
//  
//
//  Created by Andy Boyd on 29/06/2021.
//

import Foundation
import AuthenticationServices

class PresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    private let anchor: ASPresentationAnchor
    
    init(anchor: ASPresentationAnchor) {
        self.anchor = anchor
    }
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return anchor
    }
}
