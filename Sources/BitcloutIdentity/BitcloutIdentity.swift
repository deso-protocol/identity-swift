import AuthenticationServices

public class Identity {
    private let authWorker: Authable
    private let keyStore: KeyInfoStorable
    private let transactionSigner: TransactionSignable
    private let messageDecrypter: MessageDecryptable
    private let jwtCreator: JWTCreatable
    private let context: PresentationContextProvidable
    
    public convenience init() throws {
        guard let window = UIApplication.shared.windows.first else {
            throw IdentityError.missingPresentationAnchor
        }
        
        self.init(
            authWorker: AuthWorker(),
            keyStore: KeyInfoStorageWorker(),
            transactionSigner: SignTransactionWorker(),
            messageDecrypter: MessageDecryptionWorker(),
            jwtCreator: JWTCreator(),
            context: PresentationContextProvider(anchor: window)
        )
    }
    
    internal init(
        authWorker: Authable,
        keyStore: KeyInfoStorable,
        transactionSigner: TransactionSignable,
        messageDecrypter: MessageDecryptable,
        jwtCreator: JWTCreatable,
        context: PresentationContextProvidable
    ) {
        self.authWorker = authWorker
        self.keyStore = keyStore
        self.transactionSigner = transactionSigner
        self.messageDecrypter = messageDecrypter
        self.jwtCreator = jwtCreator
        self.context = context
    }

    public func login(with accessLevel: AccessLevel) throws {
        authWorker.presentAuthSession(accessLevel: accessLevel, context: context)
    }

    public func logout(_ publicKey: String) throws {
        try keyStore.clearDerivedKeyInfo(for: publicKey)
    }

    public func removeAllKeys() throws {
        try keyStore.clearAllDerivedKeyInfo()
    }

    public func sign(_ transaction: UnsignedTransaction) throws -> String {
        // TODO: Check if logged in and throw error if not
        return try transactionSigner.signTransaction(transaction)
    }

    public func decrypt(_ messages: EncryptedMessages) throws -> [String] {
        // TODO: Check if logged in and throw error if not
        return try messageDecrypter.decryptMessages(messages)
    }

    public func jwt(_ request: JWTRequest) throws -> String {
        // TODO: Check if logged in and throw error if not
        return try jwtCreator.createJwt(request)
    }
}



