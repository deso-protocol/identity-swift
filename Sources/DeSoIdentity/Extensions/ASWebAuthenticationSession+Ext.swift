//
//  ASWebAuthenticationSession+Ext.swift
//  
//
//  Created by Jacob Davis on 12/7/21.
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

extension ASWebAuthenticationSession {
    
    @MainActor
    static func startDerivedKeySession(url: URL, callbackURLScheme: String?) async throws -> DerivedKeyInfo {
        
        return try await withCheckedThrowingContinuation({
            (continuation: CheckedContinuation<DerivedKeyInfo, Error>) in
            do {
                
                #if os(iOS)
                guard let window = UIApplication.shared.windows.first else {
                    throw DeSoIdentityError.missingPresentationAnchor
                }
                let context = PresentationContextProvider(anchor: window)
                #elseif os(macOS)
                guard let window = NSApplication.shared.windows.first else {
                    throw DeSoIdentityError.missingPresentationAnchor
                }
                let context = PresentationContextProvider(anchor: window)
                #endif
                
                let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme) { url, error in

                    guard let url = url else {
                        print(error?.localizedDescription ?? "No URL Returned")
                        return continuation.resume(throwing: DeSoIdentityError.authUrlReturnMissing)
                    }
                    
                    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                    guard let query = components?.queryItems,
                          let keyData = DerivedKeyInfo(query) else {
                              print("Unexpected data returned")
                              continuation.resume(throwing: DeSoIdentityError.unexpectedDerivedKeyData)
                        return
                    }
                    
                    continuation.resume(returning: keyData)

                }
                
                session.presentationContextProvider = context
                session.prefersEphemeralWebBrowserSession = false
                session.start()
                
            } catch {
                continuation.resume(throwing: error)
            }
        })
        
    }
    
    @MainActor
    static func startGetSharedSecretsSession(url: URL, callbackURLScheme: String?) async throws -> [String] {
        
        return try await withCheckedThrowingContinuation({
            (continuation: CheckedContinuation<[String], Error>) in
            do {
                
                #if os(iOS)
                guard let window = UIApplication.shared.windows.first else {
                    throw DeSoIdentityError.missingPresentationAnchor
                }
                let context = PresentationContextProvider(anchor: window)
                #elseif os(macOS)
                guard let window = NSApplication.shared.windows.first else {
                    throw DeSoIdentityError.missingPresentationAnchor
                }
                let context = PresentationContextProvider(anchor: window)
                #endif
                
                let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme) { url, error in

                    guard let url = url else {
                        print(error?.localizedDescription ?? "No URL Returned")
                        return continuation.resume(throwing: DeSoIdentityError.authUrlReturnMissing)
                    }
                    
                    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                    guard let sharedSecrets = components?.queryItems?.first(where: { $0.name == "sharedSecrets" })?.value else {
                        continuation.resume(throwing: DeSoIdentityError.error(message: "No shared secrets return from DeSo Identity"))
                        return
                    }

                    continuation.resume(returning: sharedSecrets.components(separatedBy: ","))

                }
                
                session.presentationContextProvider = context
                session.prefersEphemeralWebBrowserSession = false
                session.start()
                
            } catch {
                continuation.resume(throwing: error)
            }
        })
        
    }
    
}
