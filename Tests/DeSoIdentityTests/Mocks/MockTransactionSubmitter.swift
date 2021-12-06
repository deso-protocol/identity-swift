//
//  File.swift
//  
//
//  Created by Andy Boyd on 29/09/2021.
//

import Foundation
@testable import DeSoIdentity

class MockTransactionSubmitter: TransactionSubmittable {
    var calledSubmitTransaction: Bool = false
    var setNodeURL: URL?
    func submitTransaction(with signedHex: String, on nodeURL: URL, completion: @escaping ((Result<SubmitTransactionResponse, Error>) -> Void)) throws {
        calledSubmitTransaction = true
        completion(.success(nil))
    }
}
