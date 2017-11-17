//
//  HashProtocol.swift
//  App
//
//  Created by Rodrigo Kreutz on 16/11/17.
//

import Vapor
import AuthProvider

extension CryptoHasher: PasswordVerifier {
    public func verify(password: Bytes, matches hash: Bytes) throws -> Bool {
        return try self.check(password, matchesHash: hash)
    }
}
