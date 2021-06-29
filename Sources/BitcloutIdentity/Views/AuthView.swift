//
//  File.swift
//  
//
//  Created by Andy Boyd on 29/06/2021.
//

import Foundation
import AuthenticationServices

func presentAuthSession(accessLevel: AccessLevel) {
    let session = ASWebAuthenticationSession(url: URL(string: "https://identity.bitclout.com/log-in?accessLevelRequest=\(accessLevel.rawValue)&webview=true")!,
                                             callbackURLScheme: "bitcloutid") { url, error in
        // TODO: get the auth information here and store it in the keychain (or wherever is appropriate)
        print(url?.absoluteString ?? "NO URL returned")
        if let error = error {
            print(error.localizedDescription)
        }
    }
    session.prefersEphemeralWebBrowserSession = false
    session.start()
}
