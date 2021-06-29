import AuthenticationServices

private let transactionSigner: TransactionSignable = SignTransactionWorker()
private let messageDecrypter: MessageDecryptable = MessageDecryptionWorker()
private let jwtCreator: JWTCreatable = JWTCreator()
private var context: PresentationContextProvider!

public func login(with accessLevel: AccessLevel) throws {
    guard let window = UIApplication.shared.windows.first else {
        throw IdentityError.missingPresentationAnchor
    }
    context = PresentationContextProvider(anchor: window)
    presentAuthSession(accessLevel: accessLevel, context: context)
}

public func logout(_ publicKey: String) throws {
    // TODO: remove stored information for specified public key
}

public func sign(_ transaction: UnsignedTransaction) throws -> String {
    // TODO: Check if logged in and throw error if not
    return transactionSigner.signTransaction(transaction)
}

public func decrypt(_ messages: EncryptedMessages) throws -> [String] {
    // TODO: Check if logged in and throw error if not
    return messageDecrypter.decryptMessages(messages)
}

public func jwt(_ request: JWTRequest) throws -> String {
    // TODO: Check if logged in and throw error if not
    return jwtCreator.createJwt(request)
}
