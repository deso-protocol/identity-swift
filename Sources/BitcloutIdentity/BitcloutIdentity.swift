import AuthenticationServices

struct BitcloutIdentity {
    var contextProvider: ASWebAuthenticationPresentationContextProviding
}

private var state: BitcloutIdentity?
private let transactionSigner: TransactionSignable = SignTransactionWorker()
private let messageDecrypter: MessageDecryptable = MessageDecryptionWorker()
private let jwtCreator: JWTCreatable = JWTCreator()

public func initialize(_ viewController: UIViewController) {
    state = BitcloutIdentity(contextProvider: viewController)
}

public func login(with accessLevel: Int) throws {
    guard let state = state else {
        throw IdentityError.missingPresentationAnchor
    }
    presentAuthSession(state.contextProvider)
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
