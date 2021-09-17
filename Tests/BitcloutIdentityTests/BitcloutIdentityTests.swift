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
                jwtWorker: jwtCreator,
                context: context,
                network: .testnet,
                overrideIdentityURL: nil
            )
        }
        
        func testLoginCallsAuthWorker() {
            let expectation = self.expectation(description: "completion")
            sut.login() { _,_ in
                expectation.fulfill()
            }
            waitForExpectations(timeout: 5, handler: nil)
            XCTAssertTrue(authWorker.calledPresentAuthSession)
        }
        
        func testLogoutCallsKeyStore() {
            let _ = try! sut.logout("foobar")
            XCTAssertTrue(keyStore.calledClearDerivedKeyInfo)
            XCTAssertEqual(keyStore.publicKeyRequestedForClearInfo, "foobar")
        }
        
        func testGetLoggedInKeysCallsKeyStore() {
            let _ = try! sut.getLoggedInKeys()
            XCTAssertTrue(keyStore.calledGetAllStoredKeys)
        }
        
        func testRemoveAllKeysCallsKeyStore() {
            try! sut.removeAllKeys()
            XCTAssertTrue(keyStore.calledClearAllStoredInfo)
        }
        
        func testSignCallsTransactionSigner() {
            let transaction = UnsignedTransaction(publicKey: "qwerty",
                                                  transactionHex: "123456")
            let _ = try! sut.sign(transaction)
            XCTAssertTrue(transactionSigner.calledSignTransaction)
            XCTAssertEqual(transactionSigner.transactionRequestedForSign, transaction)
        }
        
        func testDecryptThreadsCallsMessageDecrypter() {
            let encrypted = [EncryptedMessagesThread(publicKey: "alalalala",
                                                     encryptedMessages: ["foo", "foobar", "batbla"])]
            let myPublicKey = "ghghghgh"
            let _ = try! sut.decrypt(encrypted, for: myPublicKey, errorOnFailure: true)
            XCTAssertTrue(messageDecrypter.calledDecryptThreads)
            XCTAssertEqual(messageDecrypter.messagesToDecrypt, encrypted)
            XCTAssertEqual(messageDecrypter.publicKeyToDecryptFor, myPublicKey)
            XCTAssertEqual(messageDecrypter.errorOnFailure, true)
        }
        
        func testDecryptSingleThreadCallsMessageDecrypter() {
            let encrypted = EncryptedMessagesThread(publicKey: "alalalala",
                                                     encryptedMessages: ["foo", "foobar", "batbla"])
            let myPublicKey = "ghghghgh"
            let _ = try! sut.decrypt(encrypted, for: myPublicKey, errorOnFailure: true)
            XCTAssertTrue(messageDecrypter.calledDecryptThread)
            XCTAssertEqual(messageDecrypter.threadToDecrypt, encrypted)
            XCTAssertEqual(messageDecrypter.publicKeyToDecryptFor, myPublicKey)
            XCTAssertEqual(messageDecrypter.errorOnFailure, true)
        }
        
        func testJWTCallsJWTWorker() {
            let pubKey = "asdfasdf"
            let _ = try! sut.jwt(for: pubKey)
            XCTAssertTrue(jwtCreator.calledGetJWT)
            XCTAssertEqual(jwtCreator.publicKeyToGetJWTFor, pubKey)
            
        }
    }
