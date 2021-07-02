    import XCTest
    @testable import BitcloutIdentity
    
    final class BitcloutIdentityTests: XCTestCase {
        var sut: Identity!
        var authWorker: MockAuthWorker!
        var keyStore: MockKeyStore!
        var transactionSigner: MockTransactionSigner!
        var messageDecrypter: MockMessageDecrypter!
        var jwtCreator: MockJWTCreator!
        var context: MockPresentationContextProvider!
        
        override func setUp() {
            authWorker = MockAuthWorker()
            keyStore = MockKeyStore()
            transactionSigner = MockTransactionSigner()
            messageDecrypter = MockMessageDecrypter()
            jwtCreator = MockJWTCreator()
            context = MockPresentationContextProvider()
            
            sut = Identity(
                authWorker: authWorker,
                keyStore: keyStore,
                transactionSigner: transactionSigner,
                messageDecrypter: messageDecrypter,
                jwtCreator: jwtCreator,
                context: context
            )
        }
        
        func testLoginCallsAuthWorker() {
            try! sut.login(with: .approveLarge)
            XCTAssertTrue(authWorker.calledPresentAuthSession)
            XCTAssertEqual(authWorker.accessLevelRequested, .approveLarge)
        }
        
        func testLogoutCallsKeyStore() {
            try! sut.logout("foobar")
            XCTAssertTrue(keyStore.calledClearDerivedKeyInfo)
            XCTAssertEqual(keyStore.publicKeyRequestedForClearInfo, "foobar")
        }
        
        func testRemoveAllKeysCallsKeyStore() {
            try! sut.removeAllKeys()
            XCTAssertTrue(keyStore.calledClearAllDerivedKeys)
        }
        
        func testSignCallsTransactionSigner() {
            let transaction = UnsignedTransaction(accessLevel: .full,
                                                  accessLevelHmac: "abcdef",
                                                  encryptedSeedHex: "qwerty",
                                                  transactionHex: "123456")
            let _ = try! sut.sign(transaction)
            XCTAssertTrue(transactionSigner.calledSignTransaction)
            XCTAssertEqual(transactionSigner.transactionRequestedForSign, transaction)
        }
        
        func testDecryptCallsMessageDecrypter() {
            let encrypted = EncryptedMessages(accessLevel: .approveLarge,
                                              accessLevelHmac: "blabla",
                                              encryptedSeedHex: "alalalala",
                                              encryptedMessages: ["foo", "foobar", "batbla"])
            let _ = try! sut.decrypt(encrypted)
            XCTAssertTrue(messageDecrypter.calledDecryptMessages)
            XCTAssertEqual(messageDecrypter.messagesToDecrypt, encrypted)
        }
        
        func testJWTCallsJSTCreator() {
            let request = JWTRequest(accessLevel: .full,
                                     accessLevelHmac: "uhuhuhuhuh",
                                     encryptedSeedHex: "dadadaddadda")
            let _ = try! sut.jwt(request)
            XCTAssertTrue(jwtCreator.calledCreateJWT)
            XCTAssertEqual(jwtCreator.jwtRequest, request)
            
        }
    }
