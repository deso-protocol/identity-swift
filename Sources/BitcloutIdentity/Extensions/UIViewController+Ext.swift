//
//  UIViewController+Ext.swift
//  
//
//  Created by Andy Boyd on 29/06/2021.
//

import UIKit
import AuthenticationServices

extension UIViewController: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window!
    }
}
