import AuthenticationServices

/**
 The main entry point for the library
 */
public class Identity {
    
    /**
        The possible responses when login is called
     */
    public enum LoginResponse {
        case success(selectedPublicKey: String, allLoadedPublicKeys: [String])
        case failed(error: Error)
    }
    
    /**
     Completion handler called upon successful login.
     - Parameter response: the response of the login request
     */
    public typealias LoginCompletion = ((_ response: LoginResponse) -> Void)
    
    private let authWorker: Authable
    private var keyStore: KeyInfoStorable
    private let transactionSigner: TransactionSignable
    private let messageDecrypter: MessageDecryptable
    private let jwtWorker: JWTFetchable
    private let context: PresentationContextProvidable
    private let network: Network
    private let overrideIdentityURL: String?
    
    public convenience init(network: Network = .mainnet, overrideIdentityURL: String? = nil) throws {
        #if os(iOS)
        guard let window = UIApplication.shared.windows.first else {
            throw IdentityError.missingPresentationAnchor
        }
        let context = PresentationContextProvider(anchor: window)
        #elseif os(macOS)
        guard let window = NSApplication.shared.windows.first else {
            throw IdentityError.missingPresentationAnchor
        }
        let context = PresentationContextProvider(anchor: window)
        #endif
        
        #if targetEnvironment(simulator)
        let keyStore = EphemeralKeyStore()
        #else
        let keyStore = KeyInfoStorageWorker()
        #endif
        
        self.init(
            authWorker: AuthWorker(),
            keyStore: keyStore,
            transactionSigner: SignTransactionWorker(),
            messageDecrypter: MessageDecryptionWorker(),
            jwtWorker: JWTWorker(),
            context: context,
            network: network,
            overrideIdentityURL: overrideIdentityURL
        )
    }
    
    internal init(
        authWorker: Authable,
        keyStore: KeyInfoStorable,
        transactionSigner: TransactionSignable,
        messageDecrypter: MessageDecryptable,
        jwtWorker: JWTFetchable,
        context: PresentationContextProvidable,
        network: Network,
        overrideIdentityURL: String?
    ) {
        self.authWorker = authWorker
        self.keyStore = keyStore
        self.transactionSigner = transactionSigner
        self.messageDecrypter = messageDecrypter
        self.jwtWorker = jwtWorker
        self.context = context
        self.network = network
        self.overrideIdentityURL = overrideIdentityURL
    }

    // TODO: When Swift 5.5. is widely available, update this to use async/await
    /**
     Call this to log in to one or more accounts.
     - Parameter completion: Will be called on completion of the login flow
     */
    public func login(_ completion: @escaping LoginCompletion ) {
        authWorker.presentAuthSession(context: context, on: self.network, overrideUrl: overrideIdentityURL, with: completion)
    }

    /**
     Call this to log an account out
     - Parameter publicKey: The true public key of the account to be logged out
     - Returns: An array of the remaining logged in true public keys
     */
    public func logout(_ publicKey: String) throws -> [String] {
        try keyStore.clearDerivedKeyInfo(for: publicKey)
        
        // Question: when an account is logged out, presumably we also need to delete any shared secrets relating to its private key?
        
        return try keyStore.getAllStoredKeys()
    }
    
    /**
     Get a list of the true publis keys currently logged in
     - Returns: An array of all the currently logged in true public keys
     */
    public func getLoggedInKeys() throws -> [String] {
        return try keyStore.getAllStoredKeys()
    }

    /**
     Remove all the info currently stored
     */
    public func removeAllKeys() throws {
        try keyStore.clearAllStoredInfo()
    }

    /**
     Sign a transaction to be committed to the blockchain. Note, this does not write the transaction, it just signs it.
     - Parameter transaction: and `UnsignedTransaction` object to be signed
     - Returns: A signed hash of the transaction
     */
    public func sign(_ transaction: UnsignedTransaction) throws -> String {
        return try transactionSigner.signTransaction(transaction)
    }

    /**
     Decrypt private messages from a collection of threads
     - Parameters:
        - threads: An array of `EncryptedMessagesThread` objects to be decrypted
        - myPublicKey: The public key of the calling user's account
        - errorOnFailure: true if failure to decrypt messages should return an error, false if messages which cannot be decrypted should just be ommitted from the results
     - Returns: A dictionary with keys of the publicKeys of the threads and values of the messages contained in the thread, in the order they were sent
     */
    public func decrypt(_ threads: [EncryptedMessagesThread], for myPublicKey: String, errorOnFailure: Bool = false) throws -> [String: [String]] {
        return try messageDecrypter.decryptThreads(threads, for: myPublicKey, errorOnFailure: errorOnFailure)
    }
    
    /**
     Decrypt private messages from a single thread
     - Parameters:
        - thread: An `EncryptedMessagesThread` object to be decrypted
        - myPublicKey: The public key of the calling user's account
        - errorOnFailure: true if failure to decrypt messages should return an error, false if messages which cannot be decrypted should just be ommitted from the results
     - Returns: An array of decrypted message strings in the order they were sent
     */
    public func decrypt(_ thread: EncryptedMessagesThread, for myPublicKey: String, errorOnFailure: Bool = false) throws -> [String] {
        return try messageDecrypter.decryptThread(thread, for: myPublicKey, errorOnFailure: errorOnFailure)
    }

    /**
     Retrieve a JWT that verifies ownership of the publicKey
     - Parameter publicKey: The public key for which ownership is to be verified
     - Returns: A base64 JWT string
     - Throws: Error if the publicKey is not logged in
     */
    public func jwt(for publicKey: String) throws -> String {
        return try jwtWorker.getJWT(for: publicKey)
    }
}



