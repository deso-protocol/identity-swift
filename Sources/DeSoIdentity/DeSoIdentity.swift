import AuthenticationServices

/**
 The main entry point for the library
 */
public class Identity {
    
    public struct LoginResponse {
        public let selectedPublicKey: String
        public let allLoadedPublicKeys: [String]
    }
    public typealias LoginCompletion = ((Result<LoginResponse, Error>) -> Void)

    public typealias TransactionResponse = Data?
    public typealias TransactionCompletion = ((Result<TransactionResponse, Error>) -> Void)
    
    public typealias SignatureResponse = String
    public typealias SignatureCompletion = ((Result<SignatureResponse, Error>) -> Void)
    
    private let authWorker: Authable
    private var keyStore: KeyInfoStorable
    private let transactionSigner: TransactionSignable
    private let transactionSubmitter: TransactionSubmittable
    private let messageDecrypter: MessageDecryptable
    private let jwtWorker: JWTFetchable
    private let context: PresentationContextProvidable
    private let nodeBaseURL: URL?
    private let network: Network
    private let overrideIdentityURL: String?
    
    public convenience init(nodeBaseURL: String, network: Network = .mainnet, overrideIdentityURL: String? = nil) throws {
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
            transactionSubmitter: SubmitTransactionWorker(),
            messageDecrypter: MessageDecryptionWorker(),
            jwtWorker: JWTWorker(),
            context: context,
            nodeBaseURL: nodeBaseURL,
            network: network,
            overrideIdentityURL: overrideIdentityURL
        )
    }
    
    internal init(
        authWorker: Authable,
        keyStore: KeyInfoStorable,
        transactionSigner: TransactionSignable,
        transactionSubmitter: TransactionSubmittable,
        messageDecrypter: MessageDecryptable,
        jwtWorker: JWTFetchable,
        context: PresentationContextProvidable,
        nodeBaseURL: String,
        network: Network,
        overrideIdentityURL: String?
    ) {
        self.authWorker = authWorker
        self.keyStore = keyStore
        self.transactionSigner = transactionSigner
        self.transactionSubmitter = transactionSubmitter
        self.messageDecrypter = messageDecrypter
        self.jwtWorker = jwtWorker
        self.context = context
        self.nodeBaseURL = URL(string: nodeBaseURL)
        self.network = network
        self.overrideIdentityURL = overrideIdentityURL
        
        // Get derived keys for stored users and refresh if necessary?
    }

    // TODO: When Swift 5.5. is widely available, update this to use async/await
    /**
     Call this to log in to one or more accounts.
     - Parameter completion: Will be called on completion of the login flow
     */
    public func login(_ completion: @escaping LoginCompletion) {
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
     - Parameter transaction: an `UnsignedTransaction` object to be signed
     - Returns: A signed hash of the transaction
     */
    public func sign(_ transaction: UnsignedTransaction, completion: @escaping SignatureCompletion) throws {
        guard let nodeURL = nodeBaseURL else {
            throw IdentityError.nodeNotSpecified
        }
        
        try transactionSigner.signTransaction(transaction, on: nodeURL) { response in
            switch response {
            case .success(let signature):
                completion(.success(signature))
            case .failure(let error):
                completion(.failure(error))
            }
            
        }
    }
    
    /**
     Sign a transaction and immediately submit it.
     NOTE: This requires the target node to conform to the same API spec as the core bitclout node.
     Specifically, it requires the `/submit-transaction` endpoint as detailed here: https://docs.bitclout.com/devs/backend-api#submit-transaction
     - Parameter transaction: an `UnsignedTransaction` object to be signed
     - Parameter completion: a `TransactionCompletion` block that will be called upon completion of the sign/submission process
     */
    public func signAndSubmit(_ transaction: UnsignedTransaction, completion: @escaping TransactionCompletion) throws {
        guard let nodeURL = nodeBaseURL else {
            throw IdentityError.nodeNotSpecified
        }
        
        try transactionSigner.signTransaction(transaction, on: nodeURL) { response in
            switch response {
            case .success(let signature):
                do {
                    try self.transactionSubmitter.submitTransaction(with: signature, on: nodeURL) { response in
                        switch response {
                        case .success(let data):
                            completion(.success(data))
                        case .failure(let error):
                            // TODO: get new derived key here and retry
                            completion(.failure(error))
                        }
                    }
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
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
    
    /**
     Retrieve the derived public key stored fro a given public key.
     This should be added to the `DerivedPublicKey` field in the extra data for any transaction to be signed using the library
     - Parameter publicKey: The true public key for which to retrieve the derived public key
     - Returns: The currently stored derived public key corresponding to the supplied true public key
     - Throws: Error if derived key info is not stored for the specified public key
     */
    public func derivedPublicKey(for publicKey: String) throws -> String {
        guard let info = try keyStore.getDerivedKeyInfo(for: publicKey) else {
            throw IdentityError.missingInfoForPublicKey
        }

        // TODO: Possible improvement - can we check the current block height and throw an error here if the derived key has already expired?
        
        return info.derivedPublicKey
    }
}



